//  ProtectModule.swift
//  保护模块：加密 / 移除密码 / 权限管理（工具已占位）。

import Foundation

final class ProtectModule: EditorModule {
    let kind = ModuleKind.protect
    let displayName = "保护"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let addPassword = ActionTool(id: "tool.addPassword", displayName: "添加密码", icon: "lock") { context in
            context.showPasswordMenu()
        }
        let removePassword = ActionTool(id: "tool.removePassword", displayName: "移除密码", icon: "lock.open") { context in
            context.removeSecurity()
        }
        let permission = StubTool(id: "tool.permission", displayName: "权限管理", icon: "checkmark.shield")
        tools = [addPassword, removePassword, permission]
        activeTool = addPassword
    }
}
