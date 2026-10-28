//  CompareModels.swift
//  文档对比：数据模型。

import Foundation
import CoreGraphics

/// 一个页面字符（文档对比用）。
struct PageCharInfo {
    let unicode: UInt32
    let rect: CGRect      // x=left, y=bottom（PDF 用户坐标）
    let fontSize: Float
}

/// 一页的对比差异。
struct PageDiff {
    let pageIndex: Int
    let deletedRects: [CGRect]   // 旧页被删除的内容（红）
    let addedRects: [CGRect]     // 新页新增的内容（绿）

    var isEmpty: Bool { deletedRects.isEmpty && addedRects.isEmpty }
    var deletedCount: Int { deletedRects.count }
    var addedCount: Int { addedRects.count }
}

/// 对比模式。
enum CompareMode: String, CaseIterable, Identifiable {
    case basic = "基础对比"
    case ai = "AI 对比"
    var id: String { rawValue }
}

/// 过滤选项。
struct CompareFilters {
    var ignoreCase = false
    var ignoreWhitespace = false
    var ignorePunctuation = false
    var ignoreHeaderFooter = true
}

/// 结果视图模式。
enum CompareViewMode: String, CaseIterable, Identifiable {
    case sideBySide = "双栏并排"
    case revision = "单栏修订"
    case highlight = "区域高亮"
    var id: String { rawValue }
}

/// AI 差异类型。
enum AIChangeType: String {
    case same = "相同"
    case modified = "修改"
    case added = "新增"
    case deleted = "删除"
    case rewritten = "改写"
}

/// 一条 AI 变更。
struct AIChange: Identifiable {
    let id = UUID()
    var type: AIChangeType
    var category: String      // 数值 / 条款 / 文字 / 格式 / 其他
    var oldText: String
    var newText: String
    var summary: String
    var risk: String?
    var pageIndex: Int?
}

/// AI 对比结果。
struct AICompareResult {
    var summary: String
    var changes: [AIChange]
    var risks: [String]
}

/// LLM 模型来源。
enum LLMSource: String, CaseIterable, Identifiable {
    case builtin = "内置模型（我方服务器，默认）"
    case custom = "自定义 LLM"
    var id: String { rawValue }
}
