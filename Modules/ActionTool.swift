//  ActionTool.swift
//  动作型工具：被选中时执行一次性操作（页面管理、压缩等），不参与鼠标状态机。

import Foundation

final class ActionTool: EditorTool {
    let id: String
    let displayName: String
    let icon: String
    private let action: (ToolContext) -> Void

    init(id: String, displayName: String, icon: String, action: @escaping (ToolContext) -> Void) {
        self.id = id
        self.displayName = displayName
        self.icon = icon
        self.action = action
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() {}

    func activated(context: ToolContext) {
        action(context)
    }
}
