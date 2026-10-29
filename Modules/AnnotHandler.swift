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

    var displayName: String {
        switch self {
        case .highlight: return "高亮"
        case .underline: return "下划线"
        case .squiggly:  return "波浪线"
        case .strikeout: return "删除线"
        }
    }

    var icon: String {
        switch self {
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .squiggly:  return "scribble"
        case .strikeout: return "strikethrough"
        }
    }
}

/// 图形标注类型（对应 SDK ANNOT_TYPE_*，line/rect/ellipse 用 2 点，polygon/polyline 用 n 点）。
enum ShapeType: Int, CaseIterable, Identifiable {
    case line = 4
    case square = 5
    case circle = 6
    case polygon = 7
    case polyline = 8
    case ink = 9

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .line: return "直线"
        case .square: return "矩形"
        case .circle: return "椭圆"
        case .polygon: return "多边形"
        case .polyline: return "折线"
        case .ink: return "画笔"
        }
    }

    var icon: String {
        switch self {
        case .line: return "line.diagonal"
        case .square: return "square"
        case .circle: return "circle"
        case .polygon: return "pentagon"
        case .polyline: return "scribble.variable"
        case .ink: return "pencil.tip"
        }
    }

    /// 拖拽型（line/square/circle 用 down→up 两点的工具）还是多点型（polygon/polyline）。
    var isDragBased: Bool {
        self == .line || self == .square || self == .circle
    }
}

/// 标注变更事件（创建/修改/删除），通过 PassthroughSubject 广播给各模块/面板/视图。
struct AnnotEvent {
    enum Kind {
        case added, modified, removed
    }
    let kind: Kind
    let pageIndex: Int
    let annotType: Int  // ANNOT_TYPE 原始值
}

/// 由 ANNOT_TYPE 原始值取显示名/图标（覆盖文本标记、图形、便签、FreeText/图标等所有类型）。
enum AnnotKind {
    static func name(forType t: Int) -> String {
        if let m = MarkupType(rawValue: t) { return m.displayName }
        if let s = ShapeType(rawValue: t) { return s.displayName }
        if t == 1 { return "便签" }  // ANNOT_TYPE_TEXT
        if t == 3 { return "文本" }  // ANNOT_TYPE_FREETEXT
        if t == 15 { return "图章" } // ANNOT_TYPE_STAMP
        if t == 17 { return "附件" } // ANNOT_TYPE_FILEATTACHMENT
        if t == 18 { return "音频" } // ANNOT_TYPE_SOUND
        if t == 19 { return "视频" } // ANNOT_TYPE_MOVIE
        return "标注"
    }

    static func icon(forType t: Int) -> String {
        if let m = MarkupType(rawValue: t) { return m.icon }
        if let s = ShapeType(rawValue: t) { return s.icon }
        if t == 1 { return "note.text" }
        if t == 3 { return "textbox" }
        if t == 15 { return "checkmark.seal" }
        if t == 17 { return "paperclip" }
        if t == 18 { return "speaker.wave.2" }
        if t == 19 { return "film" }
        return "square.dashed"
    }
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

    /// 从 SDK COLOR_MAKERGB 反查颜色（匹配不到则回退黄色）。
    static func from(sdkColor: UInt32) -> MarkupColor {
        for c in allCases where c.sdkColor == sdkColor { return c }
        return .yellow
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

final class SquigglyAnnotHandler: AnnotHandler {
    let id = "annot.squiggly"
    let displayName = "波浪线"
    let type = MarkupType.squiggly

    func apply(lineBoxes: [CGRect], on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addTextMarkup(ofType: type.rawValue,
                           lineBoxes: lineBoxes.map { NSValue(rect: $0) },
                           color: color,
                           opacity: opacity)
    }
}

// MARK: - 图形/矩形类标注处理器（测量 / FreeText 变体 / 图章 / 附件 / 音视频）

/// ANNOT_TYPE 常量（对应 SDK ipdf_annots.h）。
enum GraphicAnnotType: Int {
    case freeText = 3
    case stamp = 15
    case fileAttachment = 17
    case sound = 18
    case movie = 19
}

/// 非文本标记的标注处理器。形状类（测量）用 apply(points:)，矩形类（FreeText/图标）用 apply(rect:)。
protocol GraphicAnnotHandler: AnyObject {
    var id: String { get }
    var displayName: String { get }
    var annotType: Int { get }       // ANNOT_TYPE_*
    var measureType: Int { get }     // 0=非测量 1=距离 2=周长 3=面积
    var freeTextType: Int { get }    // 0=Textbox 1=Typewriter 2=Callout

    /// 形状类落标注：points 为顶点（测量 line/polygon/polyline）。
    func apply(points: [CGPoint], on page: ArkoPage, color: UInt32, opacity: Float, borderWidth: Int)
    /// 矩形类落标注：rect 为放置矩形（FreeText/图章/附件/音视频）；target 为 Callout 引出线目标点（其余类型忽略）。
    func apply(rect: CGRect, target: CGPoint?, on page: ArkoPage, color: UInt32, opacity: Float)
}

extension GraphicAnnotHandler {
    func apply(points: [CGPoint], on page: ArkoPage, color: UInt32, opacity: Float, borderWidth: Int) {}
    func apply(rect: CGRect, target: CGPoint?, on page: ArkoPage, color: UInt32, opacity: Float) {}
}

/// 测量处理器基类：创建图形标注后写入 /IT。
class MeasureAnnotHandler: GraphicAnnotHandler {
    let id: String
    let displayName: String
    let annotType: Int
    let measureType: Int
    let freeTextType = 0

    init(id: String, displayName: String, annotType: Int, measureType: Int) {
        self.id = id
        self.displayName = displayName
        self.annotType = annotType
        self.measureType = measureType
    }

    func apply(points: [CGPoint], on page: ArkoPage, color: UInt32, opacity: Float, borderWidth: Int) {
        page.addShapeAnnot(ofType: annotType,
                           points: points.map { NSValue(point: $0) },
                           color: color,
                           opacity: opacity,
                           borderWidth: borderWidth)
        page.setMeasureType(Int32(measureType), atIndex: page.annotCount - 1)
    }
}

final class DistanceMeasureHandler: MeasureAnnotHandler {
    init() { super.init(id: "annot.measure.distance", displayName: "距离", annotType: ShapeType.line.rawValue, measureType: 1) }
}
final class PerimeterMeasureHandler: MeasureAnnotHandler {
    init() { super.init(id: "annot.measure.perimeter", displayName: "周长", annotType: ShapeType.polyline.rawValue, measureType: 2) }
}
final class AreaMeasureHandler: MeasureAnnotHandler {
    init() { super.init(id: "annot.measure.area", displayName: "面积", annotType: ShapeType.polygon.rawValue, measureType: 3) }
}

/// FreeText 处理器：创建 FreeText 矩形后写入 /IT 变体。
class FreeTextAnnotHandler: GraphicAnnotHandler {
    let id: String
    let displayName: String
    let annotType = GraphicAnnotType.freeText.rawValue
    let measureType = 0
    let freeTextType: Int

    init(id: String, displayName: String, freeTextType: Int) {
        self.id = id
        self.displayName = displayName
        self.freeTextType = freeTextType
    }

    func apply(rect: CGRect, target: CGPoint?, on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addRectAnnot(ofType: annotType, inRect: rect, color: color, opacity: opacity, contents: "")
        page.setFreeTextType(Int32(freeTextType), atIndex: page.annotCount - 1)
    }
}

final class TextboxHandler: FreeTextAnnotHandler {
    init() { super.init(id: "annot.freetext.textbox", displayName: "文本框", freeTextType: 0) }
}
final class TypeWriterHandler: FreeTextAnnotHandler {
    init() { super.init(id: "annot.freetext.typewriter", displayName: "打字机", freeTextType: 1) }
}
final class CalloutHandler: FreeTextAnnotHandler {
    init() { super.init(id: "annot.freetext.callout", displayName: "标注框", freeTextType: 2) }

    override func apply(rect: CGRect, target: CGPoint?, on page: ArkoPage, color: UInt32, opacity: Float) {
        super.apply(rect: rect, target: target, on: page, color: color, opacity: opacity)
        // 引出线目标点：优先用传入的 target，否则默认在文本框下方 24pt 处。
        let t = target ?? CGPoint(x: rect.midX, y: rect.minY - 24)
        page.setCalloutPointX(t.x, y: t.y, atIndex: page.annotCount - 1)
    }
}

/// 图标类处理器（图章/附件/音视频）：矩形内画图标。
class IconAnnotHandler: GraphicAnnotHandler {
    let id: String
    let displayName: String
    let annotType: Int
    let measureType = 0
    let freeTextType = 0

    init(id: String, displayName: String, annotType: Int) {
        self.id = id
        self.displayName = displayName
        self.annotType = annotType
    }

    func apply(rect: CGRect, target: CGPoint?, on page: ArkoPage, color: UInt32, opacity: Float) {
        page.addRectAnnot(ofType: annotType, inRect: rect, color: color, opacity: opacity, contents: "")
    }
}

final class StampHandler: IconAnnotHandler {
    init() { super.init(id: "annot.stamp", displayName: "图章", annotType: GraphicAnnotType.stamp.rawValue) }
}
final class AttachmentHandler: IconAnnotHandler {
    init() { super.init(id: "annot.attachment", displayName: "附件", annotType: GraphicAnnotType.fileAttachment.rawValue) }
}
final class SoundHandler: IconAnnotHandler {
    init() { super.init(id: "annot.sound", displayName: "音频", annotType: GraphicAnnotType.sound.rawValue) }
}
final class MovieHandler: IconAnnotHandler {
    init() { super.init(id: "annot.movie", displayName: "视频", annotType: GraphicAnnotType.movie.rawValue) }
}
