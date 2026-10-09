//  TextSelectionTool.swift
//  文本选择工具公共基类：down 命中 caret，drag 更新选区，up 交棒给 finishSelection。
//  选择工具与标记工具（高亮/下划线/删除线）都继承它，只覆盖 finishSelection 的收尾行为。

import AppKit

class TextSelectionTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String

    private var startCaret: Int = -1
    private var endCaret: Int = -1
    private var dragging = false
    private var dragPage = -1

    init(id: String, displayName: String, icon: String) {
        self.id = id
        self.displayName = displayName
        self.icon = icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let page = context.page(at: event.pageIndex) else { return }
        let caret = page.caret(atUserPointX: event.point.x, y: event.point.y, tolerance: 2.0)
        startCaret = caret
        endCaret = caret
        dragging = caret >= 0
        dragPage = event.pageIndex
        if dragging {
            context.setSelection(nil)
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let page = context.page(at: dragPage) else { return }
        let caret = page.caret(atUserPointX: event.point.x, y: event.point.y, tolerance: 2.0)
        if caret >= 0 {
            endCaret = caret
        }
        let boxes = page.charBoxes(fromCaret: startCaret, toCaret: endCaret).map { $0.rectValue }
        let sel = TextSelection(pageIndex: dragPage,
                                startCaret: startCaret,
                                endCaret: endCaret,
                                charBoxes: boxes)
        context.setSelection(sel)
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging else { return }
        dragging = false
        guard startCaret >= 0, endCaret >= 0, endCaret != startCaret else { return }
        finishSelection(pageIndex: dragPage, startCaret: startCaret, endCaret: endCaret, context: context)
    }

    /// 子类覆盖：拖选结束后做什么（选择工具保留选区；标记工具落标注）。
    func finishSelection(pageIndex: Int, startCaret: Int, endCaret: Int, context: ToolContext) {}

    func reset() {
        startCaret = -1
        endCaret = -1
        dragging = false
        dragPage = -1
    }
}

/// 标记类文本工具：拖选文本后，把选中矩形按行合并，交给 AnnotHandler 落标注。
class MarkupTextTool: TextSelectionTool {
    let handler: AnnotHandler

    init(handler: AnnotHandler, id: String, displayName: String, icon: String) {
        self.handler = handler
        super.init(id: id, displayName: displayName, icon: icon)
    }

    override func finishSelection(pageIndex: Int, startCaret: Int, endCaret: Int, context: ToolContext) {
        guard let page = context.page(at: pageIndex) else { return }
        let boxes = page.charBoxes(fromCaret: startCaret, toCaret: endCaret).map { $0.rectValue }
        let lines = Self.fitCharBoxesToLines(boxes)
        guard !lines.isEmpty else { return }
        context.applyMarkup(handler, lineBoxes: lines, pageIndex: pageIndex)
        context.setSelection(nil)
    }

    /// 把同一行的字符矩形合并成行矩形（参考 Windows 的 _FitCharBoxsToLineBox）。
    static func fitCharBoxesToLines(_ boxes: [CGRect]) -> [CGRect] {
        guard !boxes.isEmpty else { return [] }
        let sorted = boxes.sorted { $0.midY > $1.midY } // 用户坐标 Y-up，从上到下
        var lines: [CGRect] = []
        var current: CGRect? = nil

        for b in sorted {
            if let c = current {
                let overlap = min(c.maxY, b.maxY) - max(c.minY, b.minY)
                let minH = min(c.height, b.height)
                if overlap > minH * 0.4 {
                    current = c.union(b)
                } else {
                    lines.append(c)
                    current = b
                }
            } else {
                current = b
            }
        }
        if let c = current {
            lines.append(c)
        }
        return lines
    }
}
