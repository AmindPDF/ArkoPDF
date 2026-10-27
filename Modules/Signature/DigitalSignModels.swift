//  DigitalSignModels.swift
//  数字签名：签名身份 / 外观 / 文档签名（面板数据源）。

import AppKit

/// 签名身份（Keychain 系统身份 / 导入 .p12 / 新建自签名证书）。
struct SigningIdentity: Identifiable {
    let id: String
    let name: String          // 显示名（证书 CN）
    let distinguishedName: String
    let valid: Bool           // 是否有效（未过期、可签名）
    let source: Source
    var credential: SigningCredential? = nil   // 关联的签名身份（SecIdentity）

    enum Source {
        case keychain          // Keychain 系统身份
        case importedP12       // 导入的 .p12
        case selfSigned        // 新建的自签名证书
    }

    init(id: String, name: String, distinguishedName: String, valid: Bool, source: Source, credential: SigningCredential? = nil) {
        self.id = id
        self.name = name
        self.distinguishedName = distinguishedName
        self.valid = valid
        self.source = source
        self.credential = credential
    }
}

/// 签名外观类型。
enum SignatureAppearanceType: String, CaseIterable, Identifiable {
    case standard = "标准"
    case text = "文本"
    case none = "无"
    var id: String { rawValue }
}

/// 签名文字方向 / 对齐。
enum SignatureTextAlign: String, CaseIterable, Identifiable {
    case left = "左"
    case center = "中"
    case right = "右"
    var id: String { rawValue }
}

/// 签名外观配置。
struct SignatureAppearance {
    var type: SignatureAppearanceType = .standard
    var showName = true
    var showDate = true
    var showLocation = true
    var showReason = true
    var showLogo = true
    var logoImage: NSImage?
    var align: SignatureTextAlign = .left
    var opacity: Float = 1.0        // 0.0~1.0
}

/// 文档上的一条数字签名（签名面板数据源）。
struct DocumentSignature: Identifiable {
    let id: String
    let signerName: String
    let distinguishedName: String
    let signingTime: String
    let reason: String
    let location: String
    let valid: Bool                 // 验证结果
    let isCertified: Bool           // 是否为文档认证（MDP）

    var statusText: String { valid ? "签名有效" : "签名无效" }
}
