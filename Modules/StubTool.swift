//  StubTool.swift
//  尚未实现的工具占位：保留 Module→Tool 结构，待后续接入对应 SDK 能力。

import Foundation

final class StubTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String

    init(id: String, displayName: String, icon: String) {
        self.id = id
        self.displayName = displayName
        self.icon = icon
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() {}
}
