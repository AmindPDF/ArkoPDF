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

        // 测量
        let distance = MeasureDragTool(handler: DistanceMeasureHandler(), id: "tool.measure.distance", displayName: "距离", icon: "ruler")
        let perimeter = MeasurePolygonTool(handler: PerimeterMeasureHandler(), draftType: .polyline, id: "tool.measure.perimeter", displayName: "周长", icon: "sum")
        let area = MeasurePolygonTool(handler: AreaMeasureHandler(), draftType: .polygon, id: "tool.measure.area", displayName: "面积", icon: "square.dashed")

        // FreeText 变体
        let textbox = RectAnnotTool(handler: TextboxHandler(), id: "tool.freetext.textbox", displayName: "文本框", icon: "textformat")
        let typewriter = RectAnnotTool(handler: TypeWriterHandler(), id: "tool.freetext.typewriter", displayName: "打字机", icon: "keyboard")
        let callout = CalloutTool(handler: CalloutHandler())

        // 图标类
        let stamp = RectAnnotTool(handler: StampHandler(), id: "tool.annot.stamp", displayName: "图章", icon: "checkmark.seal")
        let attachment = RectAnnotTool(handler: AttachmentHandler(), id: "tool.annot.attachment", displayName: "附件", icon: "paperclip")
        let sound = RectAnnotTool(handler: SoundHandler(), id: "tool.annot.sound", displayName: "音频", icon: "speaker.wave.2")
        let movie = RectAnnotTool(handler: MovieHandler(), id: "tool.annot.movie", displayName: "视频", icon: "film")

        tools = [highlight, underline, squiggly, strikeout,
                 line, square, circle, polygon, polyline, ink, note,
                 distance, perimeter, area,
                 textbox, typewriter, callout,
                 stamp, attachment, sound, movie]
        activeTool = highlight
    }
}
