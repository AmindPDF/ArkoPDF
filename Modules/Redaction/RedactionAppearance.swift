//  RedactionAppearance.swift
//  密文外观模型：填充色 + 叠加文字（自定义/豁免码）+ 样式。
//  供手动密文与批量密文共用（可复用模块的一部分）。

import AppKit

/// 密文填充色。
enum RedactionFillColor: String, CaseIterable, Identifiable {
    case black = "黑"
    case gray = "灰"
    case white = "白"
    var id: String { rawValue }

    var rgb: (r: Int, g: Int, b: Int) {
        switch self {
        case .black: return (0, 0, 0)
        case .gray: return (142, 142, 147)
        case .white: return (255, 255, 255)
        }
    }
    var sdkColor: UInt32 {
        ArkoPage.makeRGBColor(withRed: UInt8(rgb.r), green: UInt8(rgb.g), blue: UInt8(rgb.b))
    }
    var nsColor: NSColor {
        NSColor(srgbRed: CGFloat(rgb.r) / 255, green: CGFloat(rgb.g) / 255, blue: CGFloat(rgb.b) / 255, alpha: 1)
    }
}

/// 豁免码条目（如 FOIA (b)(6)）。
struct ExemptionCode: Identifiable {
    let code: String
    let desc: String
    var id: String { code }
    var display: String { "\(code) \(desc)" }
}

/// 豁免码集（一个预设清单）。
struct ExemptionCodeSet: Identifiable {
    let name: String
    let codes: [ExemptionCode]
    var id: String { name }
}

/// 预置豁免码集。
enum ExemptionCodes {
    static let usFOIA = ExemptionCodeSet(name: "美国 FOIA 豁免码", codes: [
        ExemptionCode(code: "(b)(1)(A)", desc: "国家安全"),
        ExemptionCode(code: "(b)(1)(B)", desc: "国家安全"),
        ExemptionCode(code: "(b)(2)", desc: "内部人事规则"),
        ExemptionCode(code: "(b)(3)(A)", desc: "法规豁免"),
        ExemptionCode(code: "(b)(3)(B)", desc: "法规豁免"),
        ExemptionCode(code: "(b)(4)", desc: "商业秘密"),
        ExemptionCode(code: "(b)(5)", desc: "审议过程特权"),
        ExemptionCode(code: "(b)(6)", desc: "个人隐私"),
        ExemptionCode(code: "(b)(7)(A)", desc: "执法"),
        ExemptionCode(code: "(b)(7)(B)", desc: "执法"),
        ExemptionCode(code: "(b)(7)(C)", desc: "执法"),
    ])
    static let all: [ExemptionCodeSet] = [usFOIA]
}

/// 叠加文字来源。
enum RedactionOverlaySource {
    case custom(String)
    case exemptionCode(setName: String, code: String)
}

/// 叠加文字对齐。
enum RedactionTextAlignment: String, CaseIterable, Identifiable {
    case left = "左"
    case center = "中"
    case right = "右"
    var id: String { rawValue }
}

/// 密文外观设置。
struct RedactionAppearance {
    var fillColor: RedactionFillColor = .black
    var useOverlayText: Bool = false
    var overlaySource: RedactionOverlaySource = .custom("")
    var fontName: String = "Helvetica"
    var fontSize: Int = 12
    var fontColor: RedactionFillColor = .black
    var alignment: RedactionTextAlignment = .left

    /// 叠加文字字符串（存到标注 contents；未启用/空返回 nil）。
    var overlayTextString: String? {
        guard useOverlayText else { return nil }
        switch overlaySource {
        case .custom(let s):
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        case .exemptionCode(_, let code):
            return code
        }
    }
}
