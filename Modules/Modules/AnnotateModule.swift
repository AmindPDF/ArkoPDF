//  AnnotateModule.swift
//  标注模块：文本标记（高亮/下划线/波浪线/删除线）+ 图形（直线/矩形/椭圆/多边形/折线）+ 画笔 + 便签。

import Foundation

final class AnnotateModule: EditorModule {
    let kind = ModuleKind.annotate
    let displayName = "标注"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let highlight = HighlightTool()
        let underline = UnderlineTool()
        let squiggly = SquigglyTool()
        let strikeout = StrikeoutTool()
        let line = DragShapeTool(shapeType: .line)
        let square = DragShapeTool(shapeType: .square)
        let circle = DragShapeTool(shapeType: .circle)
        let polygon = PolygonTool(shapeType: .polygon)
        let polyline = PolygonTool(shapeType: .polyline)
        let ink = InkTool()
        let note = NoteTool()

        tools = [highlight, underline, squiggly, strikeout,
                 line, square, circle, polygon, polyline, ink, note]
        activeTool = highlight
    }
}
