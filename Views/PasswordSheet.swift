//  PasswordSheet.swift
//  文档安全：添加打开密码 / 权限密码，设置加密算法与权限。
//  入口：保护模块「添加密码」→ 下拉菜单（三条目）→ 密码设置对话框（两个 Tab）。

import SwiftUI

// MARK: - 类型

enum PasswordTab: String, CaseIterable, Identifiable {
    case openPassword = "打开密码"
    case permissionPassword = "权限密码"
    var id: String { rawValue }
}

enum EncryptionAlgorithm: String, CaseIterable, Identifiable {
    case rc4_128 = "128 位 RC4"
    case aes_128 = "128 位 AES"
    case aes_256 = "256 位 AES"
    var id: String { rawValue }
    /// SDK ENCRYPT_CIPHER_*：RC4=1 / AES=2 / AES2(256)=3
    var cipher: Int32 { self == .rc4_128 ? 1 : (self == .aes_128 ? 2 : 3) }
    var keylen: Int32 { self == .aes_256 ? 256 : 128 }
}

enum PrintPermission: String, CaseIterable, Identifiable {
    case none = "禁止打印"
    case lowRes = "低分辨率打印（150 dpi）"
    case highRes = "高分辨率打印"
    var id: String { rawValue }
}

enum ChangePermission: String, CaseIterable, Identifiable {
    case none = "禁止修改"
    case assemble = "插入、删除、旋转页面"
    case fillForm = "填写表单域或签署已有的签名域"
    case annotateForm = "添加批注、填写表单、签署签名域"
    case allExceptExtract = "除提取页面外全部允许"
    var id: String { rawValue }
}

/// SDK USER_PERM_* 权限位。
enum UserPerm {
    static let print: UInt32 = 0x0004
    static let modify: UInt32 = 0x0008
    static let extract: UInt32 = 0x0010
    static let annotForm: UInt32 = 0x0020
    static let fillForm: UInt32 = 0x0100
    static let extractAccess: UInt32 = 0x0200
    static let assemble: UInt32 = 0x0400
    static let printHigh: UInt32 = 0x0800
    /// 全部权限（PSL_ALL_PERMISSION = 0xFFFFFFFC）
    static let allPermissions: UInt32 = 0xFFFFFFFC
    /// 保留位基础（PSL_NO_PERMISSION = 0xFFFFF0C0）
    static let baseReserved: UInt32 = 0xFFFFF0C0
}

/// 把打印许可 / 修改许可 / 复制 / 无障碍 组合成 SDK permissions 位掩码（对齐 Windows PasswordProtectionDlg）。
func combinedPermissions(printPerm: PrintPermission, changePerm: ChangePermission,
                         allowCopy: Bool, allowAccessibility: Bool) -> UInt32 {
    var flags: UInt32 = UserPerm.baseReserved
    switch printPerm {
    case .none: break
    case .lowRes: flags |= UserPerm.print
    case .highRes: flags |= UserPerm.print | UserPerm.printHigh
    }
    switch changePerm {
    case .none: break
    case .assemble: flags |= UserPerm.assemble
    case .fillForm: flags |= UserPerm.fillForm
    case .annotateForm: flags |= UserPerm.annotForm | UserPerm.fillForm
    case .allExceptExtract: flags |= UserPerm.assemble | UserPerm.fillForm | UserPerm.annotForm
    }
    if allowCopy { flags |= UserPerm.extract | UserPerm.extractAccess }
    if allowAccessibility { flags |= UserPerm.extractAccess }
    return flags
}

// MARK: - 密码输入框（带显示/隐藏）

private struct PasswordField: View {
    let label: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption)
            HStack(spacing: 6) {
                Group {
                    if isVisible {
                        TextField(label, text: $text)
                    } else {
                        SecureField(label, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.35))
            )
        }
    }
}

// MARK: - 密码设置对话框

struct PasswordSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State var initialTab: PasswordTab = .openPassword

    @State private var openPassword = ""
    @State private var confirmOpenPassword = ""
    @State private var permissionPassword = ""
    @State private var confirmPermissionPassword = ""
    @State private var encryption: EncryptionAlgorithm = .aes_256
    @State private var encryptMetadata = false
    @State private var printPerm: PrintPermission = .highRes
    @State private var changePerm: ChangePermission = .annotateForm
    @State private var allowCopy = true
    @State private var allowAccessibility = true

    private let hint = "若已设置打开密码，文档仍可使用权限密码打开并设置权限。\n保存文档后安全设置才会生效。"

    var body: some View {
        VStack(spacing: 0) {
            // 标题 + Tab
            VStack(alignment: .leading, spacing: 12) {
                Text("密码设置").font(.headline)
                Picker("", selection: $initialTab) {
                    ForEach(PasswordTab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)

            Divider()

            // 内容
            ScrollView {
                if initialTab == .openPassword {
                    openPasswordPane
                } else {
                    permissionPasswordPane
                }
            }
            .padding(20)

            Divider()

            // 底部按钮
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("应用") { apply() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 480)
    }

    // 打开密码 Tab
    private var openPasswordPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            PasswordField(label: "文档打开密码", text: $openPassword)
            PasswordField(label: "确认密码", text: $confirmOpenPassword)

            DisclosureGroup("更多加密选项") {
                VStack(alignment: .leading, spacing: 12) {
                    algorithmPicker
                    Toggle("加密所有文档内容（元数据）", isOn: $encryptMetadata)
                }
                .padding(.top, 8)
            }

            Text(hint)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // 权限密码 Tab
    private var permissionPasswordPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            PasswordField(label: "权限密码", text: $permissionPassword)
            PasswordField(label: "确认密码", text: $confirmPermissionPassword)

            DisclosureGroup("更多加密选项") {
                VStack(alignment: .leading, spacing: 12) {
                    printPermissionPicker
                    changePermissionPicker
                    Toggle("允许复制文本、图片以及其他内容", isOn: $allowCopy)
                    Toggle("允许视力障碍用户通过屏幕阅读器获取文本内容", isOn: $allowAccessibility)
                    algorithmPicker
                    Toggle("加密所有文档内容（元数据）", isOn: $encryptMetadata)
                }
                .padding(.top, 8)
            }

            Text(hint)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var algorithmPicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("加密算法").font(.caption).foregroundColor(.secondary)
            Picker("", selection: $encryption) {
                ForEach(EncryptionAlgorithm.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
        }
    }

    private var printPermissionPicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("打印许可").font(.caption).foregroundColor(.secondary)
            Picker("", selection: $printPerm) {
                ForEach(PrintPermission.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .labelsHidden()
        }
    }

    private var changePermissionPicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("修改许可").font(.caption).foregroundColor(.secondary)
            Picker("", selection: $changePerm) {
                ForEach(ChangePermission.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .labelsHidden()
        }
    }

    private func apply() {
        // 打开密码
        if initialTab == .openPassword {
            guard !openPassword.isEmpty else {
                vm.lastError = "请输入打开密码"
                return
            }
            guard openPassword == confirmOpenPassword else {
                vm.lastError = "两次输入的打开密码不一致"
                return
            }
            vm.applySecurity(ownerPassword: nil, userPassword: openPassword,
                             encryption: encryption, encryptMetadata: encryptMetadata,
                             printPerm: nil, changePerm: nil, allowCopy: nil, allowAccessibility: nil)
        } else {
            // 权限密码
            guard !permissionPassword.isEmpty else {
                vm.lastError = "请输入权限密码"
                return
            }
            guard permissionPassword == confirmPermissionPassword else {
                vm.lastError = "两次输入的权限密码不一致"
                return
            }
            vm.applySecurity(ownerPassword: permissionPassword, userPassword: nil,
                             encryption: encryption, encryptMetadata: encryptMetadata,
                             printPerm: printPerm, changePerm: changePerm,
                             allowCopy: allowCopy, allowAccessibility: allowAccessibility)
        }
        dismiss()
    }
}

// MARK: - 添加密码下拉菜单（三条目）

struct PasswordMenuSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            menuRow(title: "文档打开密码", desc: "打开文档时需输入密码") {
                dismiss()
                vm.passwordTab = .openPassword
            }
            menuRow(title: "编辑权限密码", desc: "限制文档编辑、打印等文档操作") {
                dismiss()
                vm.passwordTab = .permissionPassword
            }
            Divider()
            menuRow(title: "文档属性", desc: "查看文档详细信息") {
                dismiss()
                vm.showDocProperties = true
            }
        }
        .padding(6)
        .frame(width: 300)
    }

    private func menuRow(title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(desc).font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.clear)
        )
    }
}

// MARK: - 文档属性（简单展示）

struct DocPropertiesSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("文档属性").font(.headline)
            Divider()
            infoRow("页数", "\(vm.pageCount)")
            infoRow("加密", (vm.document?.isEncrypted() ?? false) ? "是" : "否")
            Divider()
            HStack {
                Spacer()
                Button("关闭") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
        .font(.body)
    }
}
