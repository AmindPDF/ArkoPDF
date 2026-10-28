//  AIBackend.swift
//  AI 对比后端：Provider 抽象 + 内置（我方服务器）+ 自定义 LLM（OpenAI 兼容）。

import Foundation

// MARK: - 配置

struct AIConfig {
    var source: LLMSource = .builtin
    var provider = "DeepSeek"
    var apiKey = ""
    /// 我方服务器对比接口（TODO：替换为正式地址）。
    var builtinEndpoint = URL(string: "https://api.arkopdf.example.com/v1/compare")!
}

// MARK: - 对齐段

struct AICompareSegment {
    let location: String       // 位置标识（第 N 页 / 条款 X）
    let oldText: String
    let newText: String
}

// MARK: - Provider 抽象

protocol AIProvider {
    var name: String { get }
    func analyze(segments: [AICompareSegment], completion: @escaping (Result<AICompareResult, Error>) -> Void)
}

// MARK: - LLM 响应 DTO

private struct AILLMChangeDTO: Codable {
    let type: String
    let category: String
    let oldText: String
    let newText: String
    let summary: String
    let risk: String?
    let pageIndex: Int?
}

private struct AILLMResponseDTO: Codable {
    let summary: String
    let changes: [AILLMChangeDTO]
    let risks: [String]
}

private struct OpenAIResponseDTO: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - 映射

private func mapType(_ s: String) -> AIChangeType {
    switch s.lowercased() {
    case "modified": return .modified
    case "added": return .added
    case "deleted": return .deleted
    case "rewritten": return .rewritten
    default: return .same
    }
}

private func mapResponse(_ dto: AILLMResponseDTO) -> AICompareResult {
    AICompareResult(
        summary: dto.summary,
        changes: dto.changes.map {
            AIChange(type: mapType($0.type), category: $0.category,
                     oldText: $0.oldText, newText: $0.newText,
                     summary: $0.summary, risk: $0.risk, pageIndex: $0.pageIndex)
        },
        risks: dto.risks)
}

/// 从 LLM 输出中提取 JSON（剥离 markdown 代码块）。
private func extractJSON(from text: String) -> Data? {
    var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("```") {
        if let firstNewline = s.firstIndex(of: "\n") {
            s = String(s[s.index(after: firstNewline)...])
        }
        if let end = s.range(of: "```") {
            s = String(s[..<end.lowerBound])
        }
    }
    return s.data(using: .utf8)
}

private func decodeResponse(_ data: Data) -> AICompareResult? {
    guard let dto = try? JSONDecoder().decode(AILLMResponseDTO.self, from: data) else { return nil }
    return mapResponse(dto)
}

// MARK: - 内置 Provider（我方服务器）

struct BuiltinAIProvider: AIProvider {
    var name: String { "内置模型（我方服务器）" }
    let endpoint: URL

    func analyze(segments: [AICompareSegment], completion: @escaping (Result<AICompareResult, Error>) -> Void) {
        let payload: [String: Any] = [
            "segments": segments.map { ["location": $0.location, "oldText": $0.oldText, "newText": $0.newText] }
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(AIBackendError.badPayload)); return
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data, let result = decodeResponse(data) else {
                completion(.failure(AIBackendError.badResponse)); return
            }
            completion(.success(result))
        }.resume()
    }
}

// MARK: - 自定义 Provider（OpenAI 兼容）

struct CustomAIProvider: AIProvider {
    var name: String { "自定义 LLM" }
    let endpoint: URL
    let apiKey: String
    let model: String

    func analyze(segments: [AICompareSegment], completion: @escaping (Result<AICompareResult, Error>) -> Void) {
        let system = "你是严谨的文档对比专家。请对比给定的「旧文本」和「新文本」片段，识别语义差异（含同义改写），只输出 JSON，不要任何解释性文字。"
        let user = buildUserPrompt(segments: segments)

        let payload: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(AIBackendError.badPayload)); return
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data,
                  let outer = try? JSONDecoder().decode(OpenAIResponseDTO.self, from: data),
                  let content = outer.choices.first?.message.content,
                  let json = extractJSON(from: content),
                  let result = decodeResponse(json) else {
                completion(.failure(AIBackendError.badResponse)); return
            }
            completion(.success(result))
        }.resume()
    }

    private func buildUserPrompt(segments: [AICompareSegment]) -> String {
        var s = "请对比以下文档片段，输出 JSON，格式：{\"summary\":\"整体摘要\",\"changes\":[{\"type\":\"modified|added|deleted|rewritten|same\",\"category\":\"数值|条款|文字|格式|其他\",\"oldText\":\"原文\",\"newText\":\"新文\",\"summary\":\"一句话\",\"risk\":\"风险（可选）\"}],\"risks\":[\"风险汇总\"]}\n\n片段：\n"
        for seg in segments {
            s += "位置：\(seg.location)\n旧：\(seg.oldText)\n新：\(seg.newText)\n\n"
        }
        return s
    }
}

// MARK: - 工厂 + 错误

enum AIBackendError: LocalizedError {
    case badPayload, badResponse
    var errorDescription: String? {
        switch self {
        case .badPayload: return "请求构造失败"
        case .badResponse: return "模型返回格式不正确"
        }
    }
}

enum AIProviderFactory {
    /// 默认 provider 端点（OpenAI 兼容协议）。
    static func endpoint(for provider: String) -> URL {
        switch provider {
        case "Qwen": return URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!
        case "智谱 GLM": return URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
        case "OpenAI": return URL(string: "https://api.openai.com/v1/chat/completions")!
        default: return URL(string: "https://api.deepseek.com/chat/completions")!  // DeepSeek
        }
    }

    static func model(for provider: String) -> String {
        switch provider {
        case "Qwen": return "qwen-plus"
        case "智谱 GLM": return "glm-4"
        case "OpenAI": return "gpt-4o"
        default: return "deepseek-chat"
        }
    }

    static func make(config: AIConfig) -> AIProvider {
        if config.source == .builtin {
            return BuiltinAIProvider(endpoint: config.builtinEndpoint)
        }
        return CustomAIProvider(endpoint: endpoint(for: config.provider),
                                apiKey: config.apiKey,
                                model: model(for: config.provider))
    }
}
