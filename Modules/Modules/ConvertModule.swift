//  ConvertModule.swift
//  转换模块：拆分 / 合并 / 导出（工具已占位）。

import Foundation

final class ConvertModule: EditorModule {
    let kind = ModuleKind.convert
    let displayName = "转换"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let split = StubTool(id: "tool.split", displayName: "拆分", icon: "square.split.2x1")
        let merge = StubTool(id: "tool.merge", displayName: "合并", icon: "square.and.arrow.up")
        let export = StubTool(id: "tool.export", displayName: "导出", icon: "square.and.arrow.up.on.square")
        tools = [split, merge, export]
        activeTool = split
    }
}
