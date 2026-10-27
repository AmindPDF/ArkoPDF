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
        let sign = ActionTool(id: "tool.sign", displayName: "签名", icon: "signature") { context in
            context.showSignSheet()
        }
        let digitalSign = StubTool(id: "tool.digitalSign", displayName: "数字签名", icon: "checkmark.seal")
        let redact = RedactTool()
        tools = [addPassword, removePassword, sign, digitalSign, redact]
        activeTool = addPassword
    }
}
