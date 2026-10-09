//  ProtectModule.swift
//  保护模块：加密 / 移除密码 / 权限管理（工具已占位）。

import Foundation

final class ProtectModule: EditorModule {
    let kind = ModuleKind.protect
    let displayName = "保护"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let encrypt = StubTool(id: "tool.encrypt", displayName: "加密", icon: "lock")
        let removePwd = StubTool(id: "tool.removePassword", displayName: "移除密码", icon: "lock.open")
        let permission = StubTool(id: "tool.permission", displayName: "权限管理", icon: "checkmark.shield")
        tools = [encrypt, removePwd, permission]
        activeTool = encrypt
    }
}
