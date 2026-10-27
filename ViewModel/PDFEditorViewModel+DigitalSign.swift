//  PDFEditorViewModel+DigitalSign.swift
//  数字签名：加载身份 / 导入 .p12 / 签名。

import Foundation

extension PDFEditorViewModel {

    // MARK: - 数字签名

    /// 从 Keychain 加载可用的签名身份。
    func loadSigningIdentities() {
        let creds = CertificateManager.loadKeychainIdentities()
        signingIdentities = creds.enumerated().map { i, c in
            SigningIdentity(id: "keychain-\(i)",
                            name: c.name,
                            distinguishedName: c.distinguishedName,
                            valid: true,
                            source: .keychain,
                            credential: c)
        }
    }

    /// 导入 .p12 并加入身份列表。返回是否成功。
    @discardableResult
    func importP12(data: Data, password: String) -> Bool {
        guard let cred = CertificateManager.importP12(data: data, password: password) else { return false }
        let identity = SigningIdentity(id: "p12-\(UUID().uuidString)",
                                       name: cred.name,
                                       distinguishedName: cred.distinguishedName,
                                       valid: true,
                                       source: .importedP12,
                                       credential: cred)
        signingIdentities.append(identity)
        return true
    }

    /// 新建自签名证书并加入身份列表。返回是否成功。
    @discardableResult
    func createSelfSigned(name: String, email: String, organization: String, keySize: Int, validityYears: Int) -> Bool {
        guard let cred = CertificateManager.createSelfSigned(name: name, email: email, organization: organization, keySize: keySize, validityYears: validityYears) else {
            return false
        }
        let identity = SigningIdentity(id: "self-\(UUID().uuidString)",
                                       name: cred.name,
                                       distinguishedName: cred.distinguishedName,
                                       valid: true,
                                       source: .selfSigned,
                                       credential: cred)
        signingIdentities.append(identity)
        return true
    }

    /// 数字签名（调用桥接层 ArkoDigitalSign）。
    func signDocument(pageIndex: Int, rect: CGRect, credential: SigningCredential,
                      name: String, reason: String, location: String, to url: URL) -> Bool {
        guard let doc = document else { return false }
        do {
            return try ArkoDigitalSign().sign(document: doc, pageIndex: pageIndex, rect: rect,
                                              identity: credential.identity,
                                              name: name, reason: reason, location: location,
                                              to: url)
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
}
