//  AnnotateModule.swift
//  标注模块：高亮 / 下划线 / 删除线（各自绑定对应 AnnotHandler）。

import Foundation

final class AnnotateModule: EditorModule {
    let kind = ModuleKind.annotate
    let displayName = "标注"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let highlight = HighlightTool()
        let underline = UnderlineTool()
        let strikeout = StrikeoutTool()
        tools = [highlight, underline, strikeout]
        activeTool = highlight
    }
}
