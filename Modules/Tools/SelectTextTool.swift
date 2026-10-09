//  SelectTextTool.swift
//  选择工具：拖选文本并保留选区（用于阅读/复制）。

import Foundation

final class SelectTextTool: TextSelectionTool {
    init() {
        super.init(id: "tool.selectText", displayName: "选择", icon: "text.cursor")
    }
}
