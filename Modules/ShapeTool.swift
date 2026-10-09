//  ShapeTool.swift
//  图形标注工具：直线/矩形/椭圆（拖拽）、多边形/折线（多点）、画笔（自由）、便签（点击）。

import Foundation

/// 拖拽型图形工具（line/square/circle）：down 记录起点，drag 预览，up 落标注。
final class DragShapeTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    let shapeType: ShapeType

    private var startPoint: CGPoint?
    private var dragPage = -1

    init(shapeType: ShapeType) {
        self.shapeType = shapeType
        self.id = "tool.shape.\(shapeType.rawValue)"
        self.displayName = shapeType.displayName
        self.icon = shapeType.icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        startPoint = event.point
        dragPage = event.pageIndex
        context.setDraft(DraftShape(pageIndex: event.pageIndex, type: shapeType, points: [event.point, event.point]))
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard let start = startPoint else { return }
        context.setDraft(DraftShape(pageIndex: dragPage, type: shapeType, points: [start, event.point]))
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard let start = startPoint else { return }
        context.setDraft(nil)
        context.addShapeAnnot(shapeType, points: [start, event.point], pageIndex: dragPage)
        startPoint = nil
    }

    func reset() {
        startPoint = nil
    }
}

/// 多边形/折线工具：单击加顶点，双击完成。
final class PolygonTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    let shapeType: ShapeType

    private var points: [CGPoint] = []
    private var dragPage = -1

    init(shapeType: ShapeType) {
        self.shapeType = shapeType
        self.id = "tool.shape.\(shapeType.rawValue)"
        self.displayName = shapeType.displayName
        self.icon = shapeType.icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        dragPage = event.pageIndex
        if event.clickCount >= 2 {
            if points.count >= 2 {
                context.setDraft(nil)
                context.addShapeAnnot(shapeType, points: points, pageIndex: dragPage)
            }
            points = []
        } else {
            points.append(event.point)
            context.setDraft(DraftShape(pageIndex: event.pageIndex, type: shapeType, points: points))
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}

    func reset() {
        points = []
    }
}

/// 画笔工具（自由绘制，一次拖拽一条笔画）。
final class InkTool: EditorTool {
    let id = "tool.shape.ink"
    let displayName = ShapeType.ink.displayName
    let icon = ShapeType.ink.icon

    private var points: [CGPoint] = []
    private var dragPage = -1

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        points = [event.point]
        dragPage = event.pageIndex
        context.setDraft(DraftShape(pageIndex: event.pageIndex, type: .ink, points: points))
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        points.append(event.point)
        context.setDraft(DraftShape(pageIndex: dragPage, type: .ink, points: points))
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        context.setDraft(nil)
        if points.count >= 2 {
            context.addShapeAnnot(.ink, points: points, pageIndex: dragPage)
        }
        points = []
    }

    func reset() { points = [] }
}

/// 便签工具：点击放置便签。
final class NoteTool: EditorTool {
    let id = "tool.note"
    let displayName = "便签"
    let icon = "note.text"

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        context.addNoteAnnot(at: event.point, pageIndex: event.pageIndex)
    }
    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() {}
}
