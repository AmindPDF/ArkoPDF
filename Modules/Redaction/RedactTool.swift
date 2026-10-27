//  RedactTool.swift
//  手动密文工具：拖拽框选矩形，或选中文字 → 按行生成密文标记。
//  通过 ToolContext.markRedaction 落标记（与批量密文共用 RedactionEngine）。

import AppKit

final class RedactTool: EditorTool {
    let id = "tool.redact"
    let displayName = "密文"
    let icon = "rectangle.inset.filled"

    private enum Mode { case none, text, rect }
    private var mode: Mode = .none
    private var dragPage = -1
    private var startPoint = CGPoint.zero
    private var startCaret = -1
    private var endCaret = -1

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let page = context.page(at: event.pageIndex) else { return }
        dragPage = event.pageIndex
        let caret = page.caret(atUserPointX: event.point.x, y: event.point.y, tolerance: 2.0)
        if caret >= 0 {
            // 命中文字：走文字标记
            mode = .text
            startCaret = caret
            endCaret = caret
            context.setSelection(nil)
        } else {
            // 空白：走矩形框选
            mode = .rect
            startPoint = event.point
            context.setRedactionDraft(nil, pageIndex: event.pageIndex)
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard event.pageIndex == dragPage else { return }
        switch mode {
        case .text:
            guard let page = context.page(at: event.pageIndex) else { return }
            let caret = page.caret(atUserPointX: event.point.x, y: event.point.y, tolerance: 2.0)
            if caret >= 0 { endCaret = caret }
            let boxes = page.charBoxes(fromCaret: startCaret, toCaret: endCaret).map { $0.rectValue }
            context.setSelection(TextSelection(pageIndex: dragPage, startCaret: startCaret,
                                               endCaret: endCaret, charBoxes: boxes))
        case .rect:
            let r = CGRect(x: min(startPoint.x, event.point.x),
                           y: min(startPoint.y, event.point.y),
                           width: abs(event.point.x - startPoint.x),
                           height: abs(event.point.y - startPoint.y))
            context.setRedactionDraft(r, pageIndex: event.pageIndex)
        case .none:
            break
        }
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        defer { reset() }
        guard event.pageIndex == dragPage else { return }
        switch mode {
        case .text:
            guard startCaret >= 0, endCaret >= 0, endCaret != startCaret,
                  let page = context.page(at: dragPage) else { return }
            let boxes = page.charBoxes(fromCaret: startCaret, toCaret: endCaret).map { $0.rectValue }
            let lines = MarkupTextTool.fitCharBoxesToLines(boxes)
            guard !lines.isEmpty else { return }
            context.setSelection(nil)
            context.markRedaction(rects: lines, pageIndex: dragPage)
        case .rect:
            let r = CGRect(x: min(startPoint.x, event.point.x),
                           y: min(startPoint.y, event.point.y),
                           width: abs(event.point.x - startPoint.x),
                           height: abs(event.point.y - startPoint.y))
            context.setRedactionDraft(nil, pageIndex: dragPage)
            guard r.width > 2, r.height > 2 else { return }
            context.markRedaction(rects: [r], pageIndex: dragPage)
        case .none:
            break
        }
    }

    func reset() {
        mode = .none
        dragPage = -1
        startCaret = -1
        endCaret = -1
        startPoint = .zero
    }
}
