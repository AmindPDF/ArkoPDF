//  EditModule.swift
//  编辑模块：段落编辑 / 添加文字 / 添加图片 / 图片编辑 / 链接。
//  对应 Windows 版 editcontent 模块（段落、图片）与 annots 的链接工具。

import Foundation

final class EditModule: EditorModule {
    let kind = ModuleKind.edit
    let displayName = "编辑"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let para = EditParagraphTool()
        let addText = AddTextTool()
        let addImage = AddImageTool()
        let editImage = EditImageTool()
        let link = LinkTool()
        tools = [para, addText, addImage, editImage, link]
        activeTool = para
    }
}
