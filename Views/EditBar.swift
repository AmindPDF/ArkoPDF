//  EditBar.swift
//  编辑浮动栏：段落格式栏 / 图片编辑栏 + 链接设置弹窗。
//  当有段落或图片选区时显示在文档视图顶部。

import SwiftUI

// MARK: - 编辑浮动栏

struct EditBarView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        Group {
            if let sel = vm.paragraphSelection {
                ParagraphBar(sel: sel)
            } else if let sel = vm.imageSelection {
                ImageBar(sel: sel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        )
    }
}

// MARK: - 段落格式栏

private struct ParagraphBar: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let sel: ParagraphSelection

    @State private var textToInsert: String = ""

    private var pageIndex: Int { sel.pageIndex }

    var body: some View {
        HStack(spacing: 10) {
            // 插入文字
            TextField("输入文字", text: $textToInsert)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .onSubmit { insert() }
            Button("插入") { insert() }
                .disabled(textToInsert.isEmpty)

            Divider().frame(height: 20)

            // 加粗 / 斜体 / 下划线 / 删除线（切换）
            toggleButton("B", active: sel.isBold) { vm.applyParagraphStyle(.toggleBold, pageIndex: pageIndex) }
                .font(.system(size: 13, weight: .bold))
            toggleButton("I", active: sel.isItalic) { vm.applyParagraphStyle(.toggleItalic, pageIndex: pageIndex) }
                .font(.system(size: 13)).italic()
            toggleButton("U", active: sel.isUnderline) { vm.applyParagraphStyle(.toggleUnderline, pageIndex: pageIndex) }
                .font(.system(size: 13)).underline()
            toggleButton("S", active: sel.isStrikeout) { vm.applyParagraphStyle(.toggleStrikeout, pageIndex: pageIndex) }
                .font(.system(size: 13)).strikethrough()

            Divider().frame(height: 20)

            // 字号
            Menu {
                ForEach([8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72], id: \.self) { size in
                    Button("\(size) pt") { vm.applyParagraphStyle(.fontSize(Float(size)), pageIndex: pageIndex) }
                }
            } label: {
                Text("\(Int(sel.fontSize)) pt")
                    .monospacedDigit()
                    .frame(minWidth: 46)
            }
            .menuStyle(.borderlessButton)

            // 文字颜色
            HStack(spacing: 4) {
                ForEach(MarkupColor.allCases) { c in
                    let (r, g, b) = c.rgb
                    Button {
                        vm.applyParagraphStyle(.textColor(ARGBColor.make(Int(r), Int(g), Int(b))), pageIndex: pageIndex)
                    } label: {
                        Circle()
                            .fill(color(c))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().frame(height: 20)

            Button("删除") { vm.deleteSelectionText(pageIndex: pageIndex) }
            Button("删除段落") { vm.deleteWholeParagraph(pageIndex: pageIndex) }

            Button("完成") { vm.clearParagraphEdit() }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func insert() {
        let t = textToInsert
        guard !t.isEmpty else { return }
        vm.insertText(t, pageIndex: pageIndex)
        textToInsert = ""
    }

    private func toggleButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(width: 18, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 4).fill(active ? Color.accentColor.opacity(0.3) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func color(_ c: MarkupColor) -> Color {
        let (r, g, b) = c.rgb
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - 图片编辑栏

private struct ImageBar: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let sel: ImageSelection

    var body: some View {
        HStack(spacing: 8) {
            Button { op(.rotateLeft) } label: { Image(systemName: "rotate.left") }
            Button { op(.rotateRight) } label: { Image(systemName: "rotate.right") }
            Button { op(.flipHorizontal) } label: { Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
            Button { op(.flipVertical) } label: { Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down") }

            Divider().frame(height: 20)

            Button { op(.bringToFront) } label: { Image(systemName: "square.3.stack.3d.top.filled") }
                .help("置顶")
            Button { op(.sendToBack) } label: { Image(systemName: "square.3.stack.3d.bottom.filled") }
                .help("置底")

            Divider().frame(height: 20)

            Button { op(.replace) } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                .help("替换图片")
            Button { op(.export) } label: { Image(systemName: "square.and.arrow.up") }
                .help("导出图片")

            Divider().frame(height: 20)

            Button { op(.delete) } label: { Image(systemName: "trash") }
                .foregroundColor(.red)
                .help("删除图片")

            Button("完成") { vm.imageSelection = nil }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func op(_ operation: ImageOperation) {
        vm.applyImageOperation(operation, pageIndex: sel.pageIndex, objectIndex: sel.objectIndex)
    }
}

// MARK: - 链接设置弹窗

struct LinkSettingSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let draft: LinkDraft

    private enum LinkMode: String, CaseIterable {
        case url = "网址"
        case page = "页内跳转"
    }

    @State private var mode: LinkMode = .url
    @State private var urlText: String = "https://"
    @State private var targetPage: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("链接目标").font(.headline)

            Picker("类型", selection: $mode) {
                ForEach(LinkMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .url {
                TextField("https://…", text: $urlText)
                    .textFieldStyle(.roundedBorder)
            } else {
                Stepper(value: $targetPage, in: 0...max(0, vm.pageCount - 1)) {
                    Text("目标页：第 \(targetPage + 1) 页")
                }
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("确定") { confirm() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { targetPage = vm.currentPage }
    }

    private func confirm() {
        switch mode {
        case .url:
            let u = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !u.isEmpty else { return }
            vm.addLink(pageIndex: draft.pageIndex, rect: draft.rect, target: .url(u))
        case .page:
            vm.addLink(pageIndex: draft.pageIndex, rect: draft.rect, target: .page(targetPage))
        }
        dismiss()
    }
}
