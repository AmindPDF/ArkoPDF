//  PagesModule.swift
//  页面模块：页面组织 / 插入 / 删除 / 旋转（工具已占位）。

import Foundation

final class PagesModule: EditorModule {
    let kind = ModuleKind.pages
    let displayName = "页面"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let organize = StubTool(id: "tool.pageOrganize", displayName: "页面组织", icon: "square.on.square")
        let insert = StubTool(id: "tool.pageInsert", displayName: "插入页面", icon: "plus.square")
        let remove = StubTool(id: "tool.pageDelete", displayName: "删除页面", icon: "trash")
        let rotate = StubTool(id: "tool.pageRotate", displayName: "旋转页面", icon: "rotate.right")
        tools = [organize, insert, remove, rotate]
        activeTool = organize
    }
}
