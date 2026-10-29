//  FreeTextInputSheet.swift
//  FreeText 文字输入：放置文本框/打字机/标注框后弹出，输入文字写回标注并重渲染。

import SwiftUI

/// FreeText 输入草稿：目标页 + 标注下标。
struct FreeTextInputDraft: Identifiable {
    let id = UUID()
    let pageIndex: Int
    let annotIndex: Int
}

struct FreeTextInputSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    let draft: FreeTextInputDraft
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("输入文字").font(.headline).padding(16)
            Divider()

            TextEditor(text: $text)
                .font(.system(size: 13))
                .padding(8)

            Divider()
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("确定") {
                    vm.commitFreeText(text, draft: draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(14)
        }
        .frame(width: 420, height: 260)
    }
}
