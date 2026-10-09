//  MarkupTools.swift
//  标注模块的文本标记工具：高亮 / 下划线 / 删除线。
//  三者复用 MarkupTextTool 的「选文本→按行合并→落标注」流程，仅绑定不同 Handler。

import Foundation

final class HighlightTool: MarkupTextTool {
    init() {
        super.init(handler: HighlightAnnotHandler(), id: "tool.highlight", displayName: "高亮", icon: "highlighter")
    }
}

final class UnderlineTool: MarkupTextTool {
    init() {
        super.init(handler: UnderlineAnnotHandler(), id: "tool.underline", displayName: "下划线", icon: "underline")
    }
}

final class StrikeoutTool: MarkupTextTool {
    init() {
        super.init(handler: StrikeoutAnnotHandler(), id: "tool.strikeout", displayName: "删除线", icon: "strikethrough")
    }
}

final class SquigglyTool: MarkupTextTool {
    init() {
        super.init(handler: SquigglyAnnotHandler(), id: "tool.squiggly", displayName: "波浪线", icon: "scribble")
    }
}
