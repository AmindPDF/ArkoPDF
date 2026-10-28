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

    /// 应用密文：永久删除标记区域下方的原始内容（黑块标记保留为遮盖），
    /// 并在有叠加文字/豁免码的标记上绘制文字。
    static func apply(document: ArkoDocument, pageIndex: Int, appearance: RedactionAppearance) {
        guard let page = document.page(at: pageIndex) else { return }
        let marks = page.redactionMarks()
        guard !marks.isEmpty else { return }

        // 1. 删除底层内容
        let rects = marks.compactMap { $0["rect"] as? NSValue }
        _ = page.deleteContent(inRects: rects)

        // 2. 叠加文字（每个标记各自的 contents）
        let font = document.defaultFontHandle
        guard font != 0 else { return }
        let align: Int32 = appearance.alignment == .left ? 0 : (appearance.alignment == .right ? 2 : 1)
        for mark in marks {
            guard let contents = mark["contents"] as? String, !contents.isEmpty else { continue }
            guard let rectValue = mark["rect"] as? NSValue else { continue }
            page.addOverlayText(contents, inRect: rectValue.rectValue, fontHandle: font,
                                fontSize: Float(appearance.fontSize),
                                color: appearance.fontColor.sdkColor, align: align)
        }
    }

    /// 搜索文字出现位置（批量密文用）。
    /// 基于 ArkoPDFCore 的 IPDF_PageText::FindFirst/FindNext 逐页搜索，返回每处命中的矩形。
    static func search(document: ArkoDocument, text: String) -> [RedactionMatch] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var matches: [RedactionMatch] = []
        for p in 0..<document.pageCount {
            guard let page = document.page(at: p) else { continue }
            let rects = page.searchTextRects(trimmed).map { $0.rectValue }
            if !rects.isEmpty {
                matches.append(RedactionMatch(pageIndex: p, rects: rects))
            }
        }
        return matches
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
