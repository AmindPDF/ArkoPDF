//  SelfSignedCertificate.swift
//  自签名数字证书生成：手动构造 X.509 v3 证书（ASN.1 DER）+ 用 SecKeyCreateSignature 自签，
//  再通过 SecIdentityCreateWithCertificate 组装成 SecIdentity。
//
//  注意：macOS 无干净的公开 API 生成自签名证书（SecKeyCreateSelfSignedCertificate 已废弃），
//  本文件手写精简 DER 编码器 + X.509 构造。需在 macOS 上编译验证。

import Foundation
import Security
import CryptoKit

// MARK: - ASN.1 DER 编码器（精简）

enum DER {
    static func length(_ n: Int) -> Data {
        if n < 0x80 {
            return Data([UInt8(n)])
        }
        var bytes: [UInt8] = []
        var v = n
        while v > 0 {
            bytes.insert(UInt8(v & 0xFF), at: 0)
            v >>= 8
        }
        return Data([UInt8(0x80 | bytes.count)] + bytes)
    }

    static func tlv(_ tag: UInt8, _ content: Data) -> Data {
        var d = Data([tag])
        d.append(length(content.count))
        d.append(content)
        return d
    }

    static func sequence(_ content: Data) -> Data { tlv(0x30, content) }
    static func set(_ content: Data) -> Data { tlv(0x31, content) }

    static func integer(_ value: Int) -> Data {
        // 最小字节数的大端表示
        var bytes: [UInt8] = []
        var v = value
        while v > 0 {
            bytes.insert(UInt8(v & 0xFF), at: 0)
            v >>= 8
        }
        if bytes.isEmpty { bytes = [0] }
        if bytes[0] & 0x80 != 0 { bytes.insert(0, at: 0) }
        return tlv(0x02, Data(bytes))
    }

    static func integer(_ bytes: Data) -> Data {
        var b = bytes
        while b.count > 1 && b.first == 0 { b.removeFirst() }
        if let first = b.first, first & 0x80 != 0 { b.insert(0, at: 0) }
        return tlv(0x02, b)
    }

    static func bitString(_ data: Data) -> Data {
        tlv(0x03, Data([0x00]) + data)  // 0x00 = unused bits 数
    }

    static func octetString(_ data: Data) -> Data { tlv(0x04, data) }

    static func null() -> Data { Data([0x05, 0x00]) }

    static func oid(_ oid: String) -> Data {
        let comps = oid.split(separator: ".").map { Int($0) ?? 0 }
        var bytes: [UInt8] = [UInt8(40 * comps[0] + comps[1])]
        for c in comps.dropFirst(2) {
            var v = c
            var tmp: [UInt8] = [UInt8(v & 0x7F)]
            v >>= 7
            while v > 0 {
                tmp.append(UInt8(0x80 | (v & 0x7F)))
                v >>= 7
            }
            bytes.append(contentsOf: tmp.reversed())
        }
        return tlv(0x06, Data(bytes))
    }

    static func utf8String(_ s: String) -> Data {
        tlv(0x0C, s.data(using: .utf8) ?? Data())
    }

    static func printableString(_ s: String) -> Data {
        tlv(0x13, s.data(using: .ascii) ?? Data())
    }

    static func utcTime(_ date: Date) -> Data {
        let f = DateFormatter()
        f.dateFormat = "yyMMddHHmmss'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        return tlv(0x17, f.string(from: date).data(using: .ascii) ?? Data())
    }

    static func contextSpecific(_ tag: UInt8, _ content: Data) -> Data {
        tlv(0xA0 | tag, content)
    }
}

// MARK: - X.509 自签名证书

enum SelfSignedCertificate {

    // 常用 OID
    private static let rsaEncryption = "1.2.840.113549.1.1.1"
    private static let sha256WithRSA = "1.2.840.113549.1.1.11"
    private static let commonName = "2.5.4.3"
    private static let organizationName = "2.5.4.10"
    private static let emailAddress = "1.2.840.113549.1.9.1"

    /// 生成自签名证书 + SecIdentity。
    /// - Returns: 签名身份（SecIdentity = 证书 + 私钥）。
    static func create(name: String, email: String, organization: String,
                       keySize: Int, validityYears: Int) -> SecIdentity? {
        // 1. 生成 RSA 私钥（持久化到默认 keychain）
        let keyLabel = "ArkoPDF Self-Signed \(UUID().uuidString.prefix(8))"
        let keyAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: keySize,
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: keyLabel,
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttrs as CFDictionary, &error) else {
            let nsError = error?.takeRetainedValue() as NSError?
            NSLog("[ArkoPDF SelfSigned] SecKeyCreateRandomKey failed: %@", nsError?.localizedDescription ?? "unknown")
            return nil
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            NSLog("[ArkoPDF SelfSigned] SecKeyCopyPublicKey failed")
            return nil
        }
        guard let pubData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            NSLog("[ArkoPDF SelfSigned] SecKeyCopyExternalRepresentation failed")
            return nil
        }

        // 2. 构造证书 DER
        let der = Self.buildCertificate(name: name, email: email, organization: organization,
                                        publicKeyDER: pubData, privateKey: privateKey,
                                        validityYears: validityYears)
        guard let cert = SecCertificateCreateWithData(nil, der as CFData) else {
            NSLog("[ArkoPDF SelfSigned] SecCertificateCreateWithData failed (invalid DER?)")
            return nil
        }

        // 3. 组装 SecIdentity（证书 + 私钥，含运行时兜底）
        return Self.makeIdentity(cert: cert, publicKeyDER: pubData, keyLabel: keyLabel)
    }

    /// 组装 SecIdentity（证书 + 私钥）。
    /// SecIdentityCreateWithCertificate 通过在 keychain 里按「证书公钥 SHA-1 == 私钥
    /// kSecAttrApplicationLabel」匹配私钥；而 SecKeyCreateRandomKey 未必正确写入该标签，
    /// 故先直接尝试，失败则补写标签（并把证书一并写入 keychain）后重试。
    /// 所有 Security 调用失败时都打日志（返回码 + 可读错误），便于在 Mac 上定位。
    private static func makeIdentity(cert: SecCertificate, publicKeyDER: Data, keyLabel: String) -> SecIdentity? {
        var identity: SecIdentity?
        let s1 = SecIdentityCreateWithCertificate(nil, cert, &identity)
        if s1 == errSecSuccess, let id = identity { return id }
        Self.logSecError(s1, "SecIdentityCreateWithCertificate (primary)")

        // 兜底 1：给私钥补 kSecAttrApplicationLabel（= 公钥 SHA-1）
        let pubKeyHash = Self.sha1(publicKeyDER)
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: keyLabel,
        ]
        let keyUpdate: [String: Any] = [
            kSecAttrApplicationLabel as String: pubKeyHash,
        ]
        Self.logSecError(SecItemUpdate(keyQuery as CFDictionary, keyUpdate as CFDictionary),
                         "SecItemUpdate(kSecAttrApplicationLabel)")

        // 兜底 2：把证书也写入 keychain（带同一 application label，便于与私钥关联）
        let certItem: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrApplicationLabel as String: pubKeyHash,
        ]
        _ = SecItemDelete(certItem as CFDictionary)   // 已存在则先删，避免重复（失败是预期的）
        Self.logSecError(SecItemAdd(certItem as CFDictionary, nil), "SecItemAdd(certificate)")

        var retryIdentity: SecIdentity?
        let s2 = SecIdentityCreateWithCertificate(nil, cert, &retryIdentity)
        if s2 == errSecSuccess, let id = retryIdentity { return id }
        Self.logSecError(s2, "SecIdentityCreateWithCertificate (retry)")
        return nil
    }

    /// 仅在失败时打印 Security 返回码的可读错误。
    private static func logSecError(_ status: OSStatus, _ context: String) {
        guard status != errSecSuccess else { return }
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown error"
        NSLog("[ArkoPDF SelfSigned] %@ → %@ (%d)", context, message, status)
    }

    /// SHA-1（keychain 的 kSecAttrApplicationLabel 约定为公钥的 SHA-1）。
    private static func sha1(_ data: Data) -> Data {
        Data(Insecure.SHA1.hash(data: data))
    }

    /// 构造完整 X.509 v3 自签名证书 DER。
    private static func buildCertificate(name: String, email: String, organization: String,
                                         publicKeyDER: Data, privateKey: SecKey,
                                         validityYears: Int) -> Data {
        let serial = DER.integer(Self.randomSerial())
        let sigAlgID = DER.sequence(DER.oid(sha256WithRSA) + DER.null())
        let subject = Self.name(cn: name, o: organization, email: email)
        let notBefore = Date().addingTimeInterval(-86400)
        let notAfter = Calendar.current.date(byAdding: .year, value: validityYears, to: Date()) ?? Date()

        let validity = DER.sequence(DER.utcTime(notBefore) + DER.utcTime(notAfter))

        // SubjectPublicKeyInfo：RSA 公钥（PKCS#1）作为 BIT STRING
        let spkiAlg = DER.sequence(DER.oid(rsaEncryption) + DER.null())
        let spki = DER.sequence(spkiAlg + DER.bitString(publicKeyDER))

        // TBSCertificate（v3 = [0] EXPLICIT 0x02）
        let version = DER.contextSpecific(0, DER.integer(2))
        let tbs = DER.sequence(version + serial + sigAlgID + subject + validity + subject + spki)

        // 签名
        var sigError: Unmanaged<CFError>?
        guard let sig = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256,
                                              tbs as CFData, &sigError) as Data? else {
            return Data()
        }

        // Certificate = TBSCertificate + signatureAlgorithm + signatureValue
        return DER.sequence(tbs + sigAlgID + DER.bitString(sig))
    }

    private static func randomSerial() -> Data {
        var bytes = [UInt8](repeating: 0, count: 8)
        for i in 0..<8 { bytes[i] = UInt8.random(in: 1...255) }
        bytes[0] = UInt8.random(in: 1...0x7F)  // 保证 INTEGER 为正
        return Data(bytes)
    }

    /// 构造 X.509 Name（SEQUENCE OF SET OF AttributeTypeAndValue）。
    private static func name(cn: String, o: String, email: String) -> Data {
        var rdn = Data()
        if !cn.isEmpty {
            rdn.append(DER.set(DER.sequence(DER.oid(commonName) + DER.utf8String(cn))))
        }
        if !o.isEmpty {
            rdn.append(DER.set(DER.sequence(DER.oid(organizationName) + DER.utf8String(o))))
        }
        if !email.isEmpty {
            rdn.append(DER.set(DER.sequence(DER.oid(emailAddress) + DER.utf8String(email))))
        }
        return DER.sequence(rdn)
    }
}
