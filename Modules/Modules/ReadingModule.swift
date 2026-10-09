//  ReadingModule.swift
//  阅读模块：文本选择。

import Foundation

final class ReadingModule: EditorModule {
    let kind = ModuleKind.reading
    let displayName = "阅读"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let select = SelectTextTool()
        tools = [select]
        activeTool = select
    }
}
