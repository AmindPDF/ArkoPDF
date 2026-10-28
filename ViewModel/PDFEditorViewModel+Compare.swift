//  PDFEditorViewModel+Compare.swift
//  文档对比：对比流程、结果状态、AI 分析（待接入后端）。

import Foundation

extension PDFEditorViewModel {

    /// 打开对比设置对话框。
    func startCompare() {
        compareSetupPresented = true
    }

    /// 执行对比：打开新文档、跑基础对比、按需跑 AI 分析，进入结果视图。
    func runCompare(newURL: URL, mode: CompareMode, filters: CompareFilters) {
        guard let currentDoc = document else { return }
        do {
            let newDoc = try ArkoDocument(url: newURL)
            // 保持新文档打开，供「双栏并排」渲染
            endCompare()
            compareNewDocument = newDoc
            compareNewURL = newURL
            compareMode = mode
            compareFilters = filters
            compareDiffs = CompareEngine.compare(old: currentDoc, new: newDoc, filters: filters)
            compareViewMode = .highlight
            compareAIResult = AICompareResult(summary: "", changes: [], risks: [])

            if mode == .ai {
                runAICompare(old: currentDoc, new: newDoc)
            }

            compareSetupPresented = false
            compareResultPresented = true
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// AI 语义对比（TODO：接入我方服务器 API / 自定义 LLM 后端）。
    private func runAICompare(old: ArkoDocument, new: ArkoDocument) {
        // 占位：后续在此调用 AIProvider 分段对齐 + LLM 分析，产出 summary/changes/risks。
        compareAIResult = AICompareResult(
            summary: "AI 语义分析待接入（基础对比结果已就绪）。",
            changes: [],
            risks: [])
    }

    /// 指定页的对比差异（结果视图叠加用）。
    func compareDiff(forPage pageIndex: Int) -> PageDiff? {
        compareDiffs.first { $0.pageIndex == pageIndex }
    }

    /// 结束对比：释放新文档、清空结果。
    func endCompare() {
        compareNewDocument?.close()
        compareNewDocument = nil
        compareNewURL = nil
        compareDiffs = []
        compareAIResult = AICompareResult(summary: "", changes: [], risks: [])
        compareResultPresented = false
    }
}
