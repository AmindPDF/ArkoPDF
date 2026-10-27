//  CertificateManager.swift
//  数字签名证书管理：Keychain 身份枚举 / .p12 导入 / 自签名证书。

import Foundation
import Security

/// 一个可用的签名身份（SecIdentity = 证书 + 私钥）。
struct SigningCredential {
    let identity: SecIdentity
    let name: String          // 证书 CN（显示名）
    let distinguishedName: String

    init(identity: SecIdentity) {
        self.identity = identity
        var cert: SecCertificate?
        SecIdentityCopyCertificate(identity, &cert)
        if let cert = cert {
            self.name = (SecCertificateCopySubjectSummary(cert) as String?) ?? "未命名证书"
            self.distinguishedName = name
        } else {
            self.name = "未命名证书"
            self.distinguishedName = ""
        }
    }
}

enum CertificateManager {

    /// 枚举 Keychain 里所有可用于签名的身份（含私钥）。
    static func loadKeychainIdentities() -> [SigningCredential] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let identities = result as? [SecIdentity] else { return [] }
        return identities.map { SigningCredential(identity: $0) }
    }

    /// 从 .p12 / .pfx 文件导入签名身份。
    static func importP12(data: Data, password: String) -> SigningCredential? {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let items = items as? [[String: Any]],
              !items.isEmpty,
              let identity = items[0][kSecImportItemIdentity as String] as! SecIdentity? else { return nil }
        return SigningCredential(identity: identity)
    }

    /// 新建自签名证书（返回签名身份）。
    /// 注意：macOS 无干净公开 API 生成自签名证书（SecKeyCreateSelfSignedCertificate 已废弃），
    /// 需手动构造 X.509 + 用 SecKeyCreateSignature 自签。此处先用占位实现。
    static func createSelfSigned(name: String, email: String, organization: String,
                                 keySize: Int, validityYears: Int) -> SigningCredential? {
        // TODO(Phase 2): 生成 RSA/ECC 密钥对 + 手动构造并自签 X.509 证书
        return nil
    }
}
