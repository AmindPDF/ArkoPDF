//  DigitalSignSheet.swift
//  数字签名：签名对话框 + 新建证书对话框 + 签名属性（验证）对话框。

import SwiftUI
import AppKit

// MARK: - 签名对话框

struct DigitalSignSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIdentityID: String?
    @State private var reason = "我批准此文档"
    @State private var location = ""
    @State private var lockDocument = true

    private let reasons = ["我是此文档的作者", "我已审阅此文档", "我批准此文档", "我同意此文档的条款"]

    var body: some View {
        VStack(spacing: 0) {
            Text("数字签名").font(.headline).padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    signerSection
                    reasonLocationSection
                    appearanceSection
                    Toggle("签名后锁定文档（禁止后续修改）", isOn: $lockDocument)
                }
                .padding(16)
            }

            Divider()
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("签名") { sign() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedIdentityID == nil)
            }
            .padding(14)
        }
        .frame(width: 480, height: 560)
        .onAppear {
            if vm.signingIdentities.isEmpty { vm.loadSigningIdentities() }
            if selectedIdentityID == nil {
                selectedIdentityID = vm.signingIdentities.first?.id
            }
        }
    }

    // MARK: 签名者

    private var signerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("签名者").font(.system(size: 12)).foregroundColor(.secondary)
            HStack(spacing: 8) {
                Picker("", selection: $selectedIdentityID) {
                    ForEach(vm.signingIdentities) { id in
                        Text("\(id.name)\(id.valid ? "" : "（已过期）")").tag(Optional(id.id))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Button("新建证书…") { vm.newCertPresented = true }
                Button("导入证书…") { importCertificate() }
            }
            Button("证书信息") { showCertInfo() }
        }
    }

    // MARK: 原因 / 位置

    private var reasonLocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("原因").font(.system(size: 12)).foregroundColor(.secondary)
                Picker("", selection: $reason) {
                    ForEach(reasons, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("位置").font(.system(size: 12)).foregroundColor(.secondary)
                TextField("输入签名位置", text: $location)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: 外观

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("签名外观").font(.system(size: 12)).foregroundColor(.secondary)

            // 预览
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(height: 100)
                .overlay(Text("签名预览").font(.system(size: 12)).foregroundColor(.secondary))

            // 类型
            HStack(spacing: 10) {
                Text("类型").font(.system(size: 12.5)).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
                Picker("", selection: $vm.signatureAppearance.type) {
                    ForEach(SignatureAppearanceType.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            // 显示元素
            HStack(spacing: 10) {
                Text("显示元素").font(.system(size: 12.5)).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
                Toggle("名字", isOn: $vm.signatureAppearance.showName).toggleStyle(.checkbox)
                Toggle("日期", isOn: $vm.signatureAppearance.showDate).toggleStyle(.checkbox)
                Toggle("位置", isOn: $vm.signatureAppearance.showLocation).toggleStyle(.checkbox)
                Toggle("原因", isOn: $vm.signatureAppearance.showReason).toggleStyle(.checkbox)
                Toggle("Logo", isOn: $vm.signatureAppearance.showLogo).toggleStyle(.checkbox)
            }

            // Logo 图片
            HStack(spacing: 10) {
                Text("Logo 图片").font(.system(size: 12.5)).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
                Text(vm.signatureAppearance.logoImage == nil ? "（未选择）" : "已选择")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                Spacer()
                Button("选择图片…") { chooseLogo() }
            }

            // 对齐
            HStack(spacing: 10) {
                Text("对齐").font(.system(size: 12.5)).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
                Picker("", selection: $vm.signatureAppearance.align) {
                    ForEach(SignatureTextAlign.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)
                Spacer()
            }

            // 透明度
            HStack(spacing: 10) {
                Text("透明度").font(.system(size: 12.5)).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
                Slider(value: $vm.signatureAppearance.opacity, in: 0.2...1.0)
                Text("\(Int(vm.signatureAppearance.opacity * 100))%")
                    .font(.system(size: 12)).monospacedDigit().foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    // MARK: 动作

    private func sign() {
        guard let id = selectedIdentityID,
              let sel = vm.signingIdentities.first(where: { $0.id == id }),
              let cred = sel.credential else { return }
        let pageIndex = vm.currentPage
        let rect = CGRect(x: 60, y: 60, width: 200, height: 100)  // 默认放置位置（后续可拖拽）
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("signed-\(UUID().uuidString).pdf")
        if vm.signDocument(pageIndex: pageIndex, rect: rect, credential: cred,
                           name: sel.name, reason: reason, location: location, to: url) {
            vm.open(url: url)  // 重新打开已签名文档
            dismiss()
        }
    }

    private func importCertificate() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            if vm.importP12(data: data, password: "") {
                selectedIdentityID = vm.signingIdentities.last?.id
            }
        }
    }

    private func showCertInfo() {
        // TODO(Phase 2): 显示证书详情
    }

    private func chooseLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            vm.signatureAppearance.logoImage = img
        }
    }
}

// MARK: - 新建证书对话框

struct NewCertificateSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var organization = ""
    @State private var validity = "3 年"
    @State private var algorithm = "RSA 2048"
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var savePath = "~/Documents/证书.p12"

    private let validities = ["1 年", "3 年", "5 年"]
    private let algorithms = ["RSA 2048", "RSA 3072", "ECC P-256"]

    var body: some View {
        VStack(spacing: 0) {
            Text("新建证书（自签名）").font(.headline).padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    field("姓名", placeholder: "例如：张三", text: $name)
                    field("邮箱", placeholder: "例如：zhangsan@example.com", text: $email)
                    field("组织（可选）", placeholder: "例如：JiasheTech", text: $organization)
                    pickerField("有效期", selection: $validity, options: validities)
                    pickerField("密钥算法", selection: $algorithm, options: algorithms)
                    secureField("密码", text: $password)
                    secureField("确认密码", text: $confirmPassword)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("保存位置").font(.system(size: 12)).foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            TextField("", text: $savePath).textFieldStyle(.roundedBorder)
                            Button("浏览…") { browse() }
                        }
                    }
                }
                .padding(16)
            }

            Divider()
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("创建") { create() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword)
            }
            .padding(14)
        }
        .frame(width: 440, height: 480)
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder)
        }
    }

    private func secureField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            SecureField("", text: text).textFieldStyle(.roundedBorder)
        }
    }

    private func pickerField(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
        }
    }

    private func browse() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "证书.p12"
        if panel.runModal() == .OK, let url = panel.url {
            savePath = url.path
        }
    }

    private func create() {
        // TODO(Phase 2): 生成自签名证书 + 导出 .p12
        dismiss()
    }
}

// MARK: - 签名属性（验证）对话框

struct SignaturePropertiesSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("签名属性").font(.headline).padding(16)
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                if let sig = vm.selectedSignature {
                    HStack(spacing: 6) {
                        Image(systemName: sig.valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(sig.valid ? .green : .red)
                        Text(sig.statusText).font(.system(size: 14, weight: .semibold))
                    }
                    row("签名者", sig.signerName)
                    row("签名时间", sig.signingTime)
                    row("原因", sig.reason)
                    row("位置", sig.location)
                } else {
                    Text("未选择签名").foregroundColor(.secondary)
                }
                Button("查看证书…") {}
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 420)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label).foregroundColor(.secondary).frame(width: 74, alignment: .leading)
            Text(value)
            Spacer()
        }
        .font(.system(size: 12.5))
    }
}
