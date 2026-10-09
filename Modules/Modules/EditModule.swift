//  EditModule.swift
//  编辑模块：段落编辑 / 添加段落 / 图片修改（工具已占位，待接入 SDK 段落与图片编辑能力）。

import Foundation

final class EditModule: EditorModule {
    let kind = ModuleKind.edit
    let displayName = "编辑"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let para = StubTool(id: "tool.editParagraph", displayName: "段落编辑", icon: "text.justify")
        let addPara = StubTool(id: "tool.addParagraph", displayName: "添加段落", icon: "text.append")
        let image = StubTool(id: "tool.editImage", displayName: "图片修改", icon: "photo")
        tools = [para, addPara, image]
        activeTool = para
    }
}
