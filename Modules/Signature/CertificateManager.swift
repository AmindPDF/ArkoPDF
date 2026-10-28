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
    /// 注意：当前仅支持 RSA（keySize 2048/3072）；ECC 暂未实现（可 fallback 到 RSA）。
    static func createSelfSigned(name: String, email: String, organization: String,
                                 keySize: Int, validityYears: Int) -> SigningCredential? {
        let rsaSize = (keySize == 3072) ? 3072 : 2048
        guard let identity = SelfSignedCertificate.create(name: name, email: email,
                                                          organization: organization,
                                                          keySize: rsaSize,
                                                          validityYears: validityYears) else {
            return nil
        }
        return SigningCredential(identity: identity)
    }

    /// 验证 detached PKCS#7 签名。
    /// - Parameters:
    ///   - signedData: ByteRange 拼接的待验数据。
    ///   - contentsHex: 签名字典 /Contents 的十六进制串（可含 < > 定界符）。
    static func verifySignature(signedData: Data, contentsHex: String) -> Bool {
        // 1. 十六进制解码 → PKCS#7
        let hex = contentsHex.trimmingCharacters(in: CharacterSet(charactersIn: "<>\n\r "))
        var pkcs7 = Data()
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            let byteStr = String(hex[idx..<next])
            if let byte = UInt8(byteStr, radix: 16) {
                pkcs7.append(byte)
            }
            idx = next
        }
        guard !pkcs7.isEmpty else { return false }

        // 2. CMSDecoder 验证
        var decoder: CMSDecoder?
        guard CMSDecoderCreate(&decoder) == noErr, let dec = decoder else { return false }

        signedData.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            _ = CMSDecoderUpdateContent(dec, buf.baseAddress, buf.count)
        }
        pkcs7.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            _ = CMSDecoderUpdateMessage(dec, buf.baseAddress, buf.count)
        }
        CMSDecoderFinalizeMessage(dec)

        var status: CMSSignerStatus = kCMSSignerUnsigned
        CMSDecoderCopySignerStatus(dec, 0, &status)
        return status == kCMSSignerValid
    }
}
