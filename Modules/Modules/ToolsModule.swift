//  ToolsModule.swift
//  工具模块：压缩 / 打印 / OCR / 手写签名（工具已占位）。

import Foundation

final class ToolsModule: EditorModule {
    let kind = ModuleKind.tools
    let displayName = "工具"
    let tools: [EditorTool]
    var activeTool: EditorTool?

    init() {
        let compress = StubTool(id: "tool.compress", displayName: "压缩", icon: "arrow.down.circle")
        let print = StubTool(id: "tool.print", displayName: "打印", icon: "printer")
        let ocr = StubTool(id: "tool.ocr", displayName: "OCR", icon: "text.viewfinder")
        let sign = StubTool(id: "tool.signature", displayName: "手写签名", icon: "signature")
        let photoBook = ActionTool(id: "tool.photoBook", displayName: "相册", icon: "photo.on.rectangle.angled") { context in
            context.showPhotoBook()
        }
        tools = [photoBook, compress, print, ocr, sign]
        activeTool = photoBook
    }
}
