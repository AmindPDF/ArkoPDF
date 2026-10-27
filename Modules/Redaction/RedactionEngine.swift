//  RedactionEngine.swift
//  密文引擎（可复用核心）：标记 / 应用 / 搜索。
//  手动密文（拖拽框选 + 文字选中）与批量密文（输入文字 → 搜索 → 自动密文）
//  共用这一套「标记 → 应用」流程。

import Foundation

/// 一次文字命中（批量密文用：某页上的若干矩形）。
struct RedactionMatch {
    let pageIndex: Int
    let rects: [CGRect]
}

/// 密文引擎：纯逻辑，不依赖 UI。Phase A 实现「标记」，Phase B 接入 ArkoPDFCore 的「应用/搜索」。
enum RedactionEngine {

    /// 在指定页的若干矩形区域添加密文标记，返回各标注句柄。
    /// 手动密文与批量密文都通过此方法落标记，保证行为一致。
    @discardableResult
    static func mark(document: ArkoDocument, pageIndex: Int,
                     rects: [CGRect], appearance: RedactionAppearance) -> [UInt64] {
        guard let page = document.page(at: pageIndex) else { return [] }
        var handlers: [UInt64] = []
        for rect in rects where rect.width > 1 && rect.height > 1 {
            let h = page.addRedactionMark(at: rect,
                                          fillColor: appearance.fillColor.sdkColor,
                                          contents: appearance.overlayTextString)
            if h != 0 { handlers.append(h) }
        }
        return handlers
    }

    /// 应用密文：永久删除标记区域下方的原始内容并固化黑块。
    /// Phase B：调用 ArkoPDFCore 新增接口（/Redact + 内容删除）。
    static func apply(document: ArkoDocument, pageIndex: Int) {
        // TODO(Phase B): ArkoPDFCore::ApplyRedaction(page, redactionRects)
    }

    /// 搜索文字出现位置（批量密文用）。
    /// Phase B：基于 PDF 文本层定位文字矩形。
    static func search(document: ArkoDocument, text: String) -> [RedactionMatch] {
        // TODO(Phase B): ArkoPDFCore::SearchText(text) -> 每处命中矩形
        return []
    }

    /// 批量密文：搜索文字并自动标记（后续批量功能直接调用此入口）。
    @discardableResult
    static func redact(document: ArkoDocument, text: String,
                       appearance: RedactionAppearance) -> Int {
        var count = 0
        for match in search(document: document, text: text) {
            let h = mark(document: document, pageIndex: match.pageIndex,
                         rects: match.rects, appearance: appearance)
            count += h.count
        }
        return count
    }
}
