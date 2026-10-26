//  PagesModule.swift
//  页面模块：页面组织（模式）/ 插入 / 删除 / 旋转，通过 PPO 执行实际操作。

import Foundation

final class PagesModule: EditorModule {
    let kind = ModuleKind.pages
    let displayName = "页面"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        // 页面组织 = 页面管理模式（拖拽重排延后；当前操作在缩略图右键菜单 + 下方工具）
        let organize = StubTool(id: "tool.pageOrganize", displayName: "页面组织", icon: "square.on.square")

        let insert = ActionTool(id: "tool.pageInsert", displayName: "插入页面", icon: "plus.square") { context in
            context.insertBlankPage(after: context.currentPageIndex)
        }
        let remove = ActionTool(id: "tool.pageDelete", displayName: "删除页面", icon: "trash") { context in
            context.deletePage(at: context.currentPageIndex)
        }
        let rotate = ActionTool(id: "tool.pageRotate", displayName: "旋转页面", icon: "rotate.right") { context in
            context.rotatePageClockwise90(at: context.currentPageIndex)
        }
        let extract = ActionTool(id: "tool.pageExtract", displayName: "提取页面", icon: "square.and.arrow.up.on.square") { context in
            context.showPageSheet(.extract)
        }
        let insertFrom = ActionTool(id: "tool.pageInsertFrom", displayName: "从文档插入", icon: "doc.on.doc") { context in
            context.showPageSheet(.insert)
        }
        let replace = ActionTool(id: "tool.pageReplace", displayName: "替换页面", icon: "arrow.triangle.2.circlepath") { context in
            context.showPageSheet(.replace)
        }

        tools = [organize, insert, remove, rotate, extract, insertFrom, replace]
        activeTool = organize
    }
}
