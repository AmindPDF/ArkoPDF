//  AnnotHandler.swift
//  处理器层：真正把「一行行选中矩形」落成某种标注。
//  标注模块里不同注释工具复用同一条「选文本→按行合并→落标注」流程，
//  差异只在各自的 AnnotHandler（高亮/下划线/删除线）。

import AppKit

/// 标注类型。对应 SDK ipdf_annots.h 的 ANNOT_TYPE_* 常量。
enum MarkupType: Int {
    case highlight = 10
    case underline = 11
    case squiggly  = 12
    case strikeout = 13
}

/// 标注颜色（原型 4 色）。
enum MarkupColor: String, CaseIterable, Identifiable {
    case yellow, green, blue, red

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yellow: return "黄色"
        case .green:  return "绿色"
        case .blue:   return "蓝色"
        case .red:    return "红色"
        }
    }

    var rgb: (r: UInt8, g: UInt8, b: UInt8) {
        switch self {
        case .yellow: return (255, 214, 10) // #ffd60a
        case .green:  return (48, 209, 88)  // #30d158
        case .blue:   return (10, 132, 255) // #0a84ff
        case .red:    return (255, 69, 58)  // #ff453a
        }
    }

    /// SDK COLOR_MAKERGB 格式（BGR 字节序）。
    var sdkColor: UInt32 {
        ArkoPage.makeRGBColor(withRed: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

/// 处理器协议。对应 Windows 的 handler 层。
protocol AnnotHandler: AnyObject {
    var id: String { get }
    var displayName: String { get }
    var type: MarkupType { get }

    func apply(lineBoxes: [CGRect], on page: ArkoPage, color: UInt32, opacity: Float)
}

final class HighlightAnnotHandler: AnnotHandler {
    let id = "annot.highlight"
    let displayName = "高亮"
    let type = MarkupType.highlight

    func apply(lineBoxes: [CGRect], on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addTextMarkup(ofType: type.rawValue,
                           lineBoxes: lineBoxes.map { NSValue(rect: $0) },
                           color: color,
                           opacity: opacity)
    }
}

final class UnderlineAnnotHandler: AnnotHandler {
    let id = "annot.underline"
    let displayName = "下划线"
    let type = MarkupType.underline

    func apply(lineBoxes: [CGRect], on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addTextMarkup(ofType: type.rawValue,
                           lineBoxes: lineBoxes.map { NSValue(rect: $0) },
                           color: color,
                           opacity: opacity)
    }
}

final class StrikeoutAnnotHandler: AnnotHandler {
    let id = "annot.strikeout"
    let displayName = "删除线"
    let type = MarkupType.strikeout

    func apply(lineBoxes: [CGRect], on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addTextMarkup(ofType: type.rawValue,
                           lineBoxes: lineBoxes.map { NSValue(rect: $0) },
                           color: color,
                           opacity: opacity)
    }
}
