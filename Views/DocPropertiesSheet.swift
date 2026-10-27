//  DocPropertiesSheet.swift
//  文档属性对话框：描述（元数据）+ 安全（权限摘要）。
//  入口：保护模块「添加密码」下拉菜单 → 文档属性。

import SwiftUI

struct DocPropertiesSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    private enum Tab: String, CaseIterable, Identifiable {
        case description = "描述"
        case security = "安全"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .description: return "doc.text"
            case .security: return "checkmark.shield"
            }
        }
    }

    @State private var tab: Tab = .description

    var body: some View {
        VStack(spacing: 0) {
            segmentedControl
                .padding(14)

            Divider()

            ScrollView {
                Group {
                    if tab == .description { descriptionPane } else { securityPane }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(14)
        }
        .frame(width: 460, height: 540)
    }

    // MARK: - 描述

    private var descriptionPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupBox("描述") {
                fieldRow("文件", vm.document?.filePath ?? "")
                fieldRow("标题", vm.document?.title ?? "")
                fieldRow("作者", vm.document?.author ?? "")
                fieldRow("主题", vm.document?.subject ?? "")
                fieldRow("关键词", "")
                textRow("创建时间", vm.document?.creationDate ?? "")
                textRow("修改时间", vm.document?.modificationDate ?? "")
            }
            groupBox("高级") {
                textRow("应用程序", vm.document?.producer ?? "")
                textRow("PDF版本", vm.document?.pdfVersion ?? "")
                textRow("页面大小", pageSizeString)
                textRow("页数", "\(vm.pageCount)")
            }
        }
    }

    // MARK: - 安全

    private var securityPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupBox("文档安全") {
                Text("文档安全机制用于保护文档的操作限制。要移除安全机制，请将其设置为「无」。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Text("安全方法")
                        .frame(width: 78, alignment: .trailing)
                        .foregroundColor(.secondary)
                    Text(securityMethod)
                    Spacer()
                    Button("更改设置…") { changeSettings() }
                }
                .font(.system(size: 12.5))
            }
            groupBox("文档权限摘要") {
                ForEach(permissionRows) { row in
                    HStack {
                        Text(row.name)
                            .frame(width: 78, alignment: .trailing)
                            .foregroundColor(.secondary)
                        Text(row.allowed ? "允许" : "不允许")
                            .foregroundColor(row.allowed ? .primary : .secondary)
                        Spacer()
                    }
                    .font(.system(size: 12.5))
                }
            }
        }
    }

    // MARK: - 分段控件

    private var segmentedControl: some View {
        HStack(spacing: 1) {
            ForEach(Tab.allCases) { t in
                Button {
                    tab = t
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: t.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(t.rawValue)
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(tab == t ? .white : .secondary)
                .background(tab == t ? Color.accentColor : Color.clear)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(Color.secondary.opacity(0.25))
        )
    }

    // MARK: - 数据

    private var securityMethod: String {
        (vm.document?.isEncrypted() ?? false) ? "密码保护" : "无"
    }

    private var pageSizeString: String {
        let w = (vm.document?.pageWidth ?? 0) / 72.0
        let h = (vm.document?.pageHeight ?? 0) / 72.0
        return String(format: "%.2f × %.2f 英寸", w, h)
    }

    private struct PermissionRow: Identifiable {
        let id = UUID()
        let name: String
        let allowed: Bool
    }

    /// 9 项权限摘要（对齐 Windows Properties_DocSecurityDlg::SetPermission）。
    private var permissionRows: [PermissionRow] {
        let flags = vm.document?.permissionFlags() ?? 0
        let encrypted = vm.document?.isEncrypted() ?? false
        let modify = (flags & UserPerm.modify) != 0
        let annotForm = (flags & UserPerm.annotForm) != 0
        let fillForm = (flags & UserPerm.fillForm) != 0
        return [
            PermissionRow(name: "打印", allowed: (flags & UserPerm.print) != 0),
            PermissionRow(name: "修改文档", allowed: modify),
            PermissionRow(name: "文档组装", allowed: modify || (flags & UserPerm.assemble) != 0),
            PermissionRow(name: "内容访问", allowed: (flags & UserPerm.extract) != 0 || (flags & UserPerm.extractAccess) != 0),
            PermissionRow(name: "内容复制", allowed: (flags & UserPerm.extract) != 0),
            PermissionRow(name: "页面提取", allowed: modify && annotForm),
            PermissionRow(name: "批注", allowed: annotForm),
            PermissionRow(name: "填写表单", allowed: fillForm || annotForm || modify),
            PermissionRow(name: "签署", allowed: (fillForm || annotForm || modify) && !encrypted),
        ]
    }

    private func changeSettings() {
        dismiss()
        // 等本 sheet 关闭后再弹密码设置，避免两个 sheet 叠加
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.passwordTab = .openPassword
        }
    }

    // MARK: - 布局助手

    private func groupBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.secondary.opacity(0.25))
        )
    }

    /// 只读输入框样式行（对应 Windows 的 ES_READONLY EDITTEXT）。
    private func fieldRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(width: 78, alignment: .trailing)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? " " : value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 12.5))
    }

    /// 纯文本值行（对应 Windows 的 LTEXT）。
    private func textRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(width: 78, alignment: .trailing)
                .foregroundColor(.secondary)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12.5))
    }
}
