//  GraphicTools.swift
//  测量 + FreeText 变体 + 图标类标注工具。
//  手势：距离=拖拽两点，周长/面积=单击加顶点双击完成，FreeText/图标=点击放置。

import Foundation

/// 距离测量：拖拽两点，经 MeasureAnnotHandler 落标注。
final class MeasureDragTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    let handler: GraphicAnnotHandler

    private var startPoint: CGPoint?
    private var dragPage = -1

    init(handler: GraphicAnnotHandler, id: String, displayName: String, icon: String) {
        self.handler = handler
        self.id = id
        self.displayName = displayName
        self.icon = icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        startPoint = event.point
        dragPage = event.pageIndex
        context.setDraft(DraftShape(pageIndex: event.pageIndex, type: .line, points: [event.point, event.point]))
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard let start = startPoint else { return }
        context.setDraft(DraftShape(pageIndex: dragPage, type: .line, points: [start, event.point]))
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard let start = startPoint else { return }
        context.setDraft(nil)
        context.addGraphicShapeAnnot(handler, points: [start, event.point], pageIndex: dragPage)
        startPoint = nil
    }

    func reset() { startPoint = nil }
}

/// 周长/面积测量：单击加顶点，双击完成，经 MeasureAnnotHandler 落标注。
final class MeasurePolygonTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    let handler: GraphicAnnotHandler
    let draftType: ShapeType

    private var points: [CGPoint] = []
    private var dragPage = -1

    init(handler: GraphicAnnotHandler, draftType: ShapeType, id: String, displayName: String, icon: String) {
        self.handler = handler
        self.draftType = draftType
        self.id = id
        self.displayName = displayName
        self.icon = icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        dragPage = event.pageIndex
        if event.clickCount >= 2 {
            if points.count >= 2 {
                context.setDraft(nil)
                context.addGraphicShapeAnnot(handler, points: points, pageIndex: dragPage)
            }
            points = []
        } else {
            points.append(event.point)
            context.setDraft(DraftShape(pageIndex: event.pageIndex, type: draftType, points: points))
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() { points = [] }
}

/// FreeText 变体 / 图标类标注：点击放置固定尺寸矩形，经 handler 落标注。
final class RectAnnotTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    let handler: GraphicAnnotHandler

    init(handler: GraphicAnnotHandler, id: String, displayName: String, icon: String) {
        self.handler = handler
        self.id = id
        self.displayName = displayName
        self.icon = icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        let isIcon = handler is IconAnnotHandler
        let size = isIcon ? CGSize(width: 24, height: 24) : CGSize(width: 120, height: 24)
        let rect = CGRect(x: event.point.x, y: event.point.y, width: size.width, height: size.height)
        context.addGraphicRectAnnot(handler, rect: rect, target: nil, pageIndex: event.pageIndex)
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() {}
}

/// Callout 标注框：点目标 → 拖框放置，引出线从框指向目标点。
final class CalloutTool: EditorTool {
    let id = "tool.freetext.callout"
    let displayName = "标注框"
    let icon = "text.bubble"
    let handler: GraphicAnnotHandler

    private var targetPoint: CGPoint?
    private var dragPage = -1

    init(handler: GraphicAnnotHandler) {
        self.handler = handler
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        targetPoint = event.point
        dragPage = event.pageIndex
        context.setDraft(DraftShape(pageIndex: event.pageIndex, type: .square, points: [event.point, event.point]))
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard let target = targetPoint else { return }
        context.setDraft(DraftShape(pageIndex: dragPage, type: .square, points: [target, event.point]))
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard let target = targetPoint else { return }
        context.setDraft(nil)

        // 框：从目标点拖到终点；未拖拽（点击）则默认在目标点右上偏移放一个框。
        var box = CGRect(x: target.x, y: target.y, width: 0, height: 0)
        if event.point != target {
            box = CGRect(x: min(target.x, event.point.x), y: min(target.y, event.point.y),
                         width: abs(event.point.x - target.x), height: abs(event.point.y - target.y))
        }
        if box.width < 1 || box.height < 1 {
            box = CGRect(x: target.x + 8, y: target.y + 8, width: 120, height: 24)
        }
        context.addGraphicRectAnnot(handler, rect: box, target: target, pageIndex: dragPage)
        targetPoint = nil
    }

    func reset() { targetPoint = nil }
}
