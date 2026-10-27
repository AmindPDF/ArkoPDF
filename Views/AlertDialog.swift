//  AlertDialog.swift
//  通用提示/确认对话框（公共组件）：图标、色调、标题、提示语、按钮均可由调用方配置。

import SwiftUI

/// 图标色调（决定图标底色与配色）。
enum AlertTone {
    case info, success, warning, danger

    var color: Color {
        switch self {
        case .info:    return .blue
        case .success: return .green
        case .warning: return .orange
        case .danger:  return .red
        }
    }
}

/// 对话框里的一个按钮。
struct AlertDialogButton: Identifiable {
    enum Role { case cancel, primary }

    let id = UUID()
    let title: String
    let role: Role
    let action: () -> Void

    init(_ title: String, role: Role = .cancel, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
}

/// 通用提示/确认对话框：图标 + 色调 + 标题 + 提示语 + 按钮，均可由调用方配置。
struct AlertDialog: View {
    let icon: String          // SF Symbol 名
    let tone: AlertTone
    let title: String
    let message: String
    let buttons: [AlertDialogButton]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(tone.color.opacity(0.15))
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(tone.color)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                ForEach(buttons) { alertButton($0) }
            }
        }
        .padding(20)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2))
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }

    @ViewBuilder
    private func alertButton(_ b: AlertDialogButton) -> some View {
        if b.role == .primary {
            Button(b.title, action: b.action)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        } else {
            Button(b.title, action: b.action)
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
        }
    }
}

/// 全屏半透明遮罩 + 居中对话框（对应设计稿的 .modal-overlay）。
struct AlertOverlay<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea()
            content
        }
    }
}
