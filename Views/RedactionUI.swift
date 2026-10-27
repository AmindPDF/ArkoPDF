//  RedactionUI.swift
//  密文 UI：浮动选项条 + 外观设置对话框。

import SwiftUI
import AppKit

// MARK: - 浮动选项条（密文工具激活时显示）

struct RedactionOptionsBar: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        HStack(spacing: 10) {
            Text("填充色").font(.system(size: 12)).foregroundColor(.secondary)
            ForEach(RedactionFillColor.allCases) { c in
                Button {
                    vm.redactionAppearance.fillColor = c
                } label: {
                    Circle()
                        .fill(Color(nsColor: c.nsColor))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(
                            vm.redactionAppearance.fillColor == c ? Color.accentColor : Color.secondary.opacity(0.4),
                            lineWidth: vm.redactionAppearance.fillColor == c ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
            Divider().frame(height: 18)
            Button("外观设置…") { vm.redactAppearancePresented = true }
            Button("应用密文…") { vm.redactApplyConfirmPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        )
    }
}

// MARK: - 外观设置对话框

struct RedactionAppearanceSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fillColor: RedactionFillColor = .black
    @State private var useOverlay = false
    @State private var overlayKind: OverlayKind = .custom
    @State private var customText = ""
    @State private var codeSetIndex = 0
    @State private var codeIndex = 0
    @State private var fontName = "Helvetica"
    @State private var fontSize = 12
    @State private var fontColor: RedactionFillColor = .black
    @State private var alignment: RedactionTextAlignment = .left

    private enum OverlayKind { case custom, code }

    private let fonts = ["Helvetica", "Courier", "Times", "PingFang SC"]
    private let fontSizes = [8, 10, 12, 16, 20, 24]
    private let codeSets = ExemptionCodes.all

    var body: some View {
        VStack(spacing: 0) {
            Text("密文外观设置").font(.headline).padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 填充色
                    VStack(alignment: .leading, spacing: 6) {
                        Text("填充色").font(.system(size: 12)).foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            ForEach(RedactionFillColor.allCases) { c in
                                Button {
                                    fillColor = c
                                } label: {
                                    Circle()
                                        .fill(Color(nsColor: c.nsColor))
                                        .frame(width: 20, height: 20)
                                        .overlay(Circle().strokeBorder(fillColor == c ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Toggle("使用叠加文字", isOn: $useOverlay)

                    if useOverlay {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("叠加文字来源", selection: $overlayKind) {
                                Text("自定义文字").tag(OverlayKind.custom)
                                Text("密文代码（豁免码）").tag(OverlayKind.code)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()

                            if overlayKind == .custom {
                                TextField("输入要叠加的文字", text: $customText)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("代码集", selection: $codeSetIndex) {
                                    ForEach(codeSets.indices, id: \.self) { i in
                                        Text(codeSets[i].name).tag(i)
                                    }
                                }
                                .labelsHidden()
                                Picker("豁免码", selection: $codeIndex) {
                                    ForEach(codeSets[codeSetIndex].codes.indices, id: \.self) { i in
                                        Text(codeSets[codeSetIndex].codes[i].display).tag(i)
                                    }
                                }
                                .labelsHidden()
                            }

                            // 样式
                            HStack(spacing: 12) {
                                Picker("字体", selection: $fontName) {
                                    ForEach(fonts, id: \.self) { Text($0).tag($0) }
                                }
                                Picker("字号", selection: $fontSize) {
                                    ForEach(fontSizes, id: \.self) { Text("\($0)").tag($0) }
                                }
                            }
                            HStack(spacing: 12) {
                                Text("颜色").font(.system(size: 12)).foregroundColor(.secondary)
                                ForEach(RedactionFillColor.allCases) { c in
                                    Button {
                                        fontColor = c
                                    } label: {
                                        Circle().fill(Color(nsColor: c.nsColor)).frame(width: 16, height: 16)
                                            .overlay(Circle().strokeBorder(fontColor == c ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2))
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                                Text("对齐").font(.system(size: 12)).foregroundColor(.secondary)
                                Picker("", selection: $alignment) {
                                    ForEach(RedactionTextAlignment.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .labelsHidden()
                                .frame(width: 80)
                            }
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
                Button("确定") { apply(); dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 460, height: 480)
        .onAppear(perform: load)
    }

    private func load() {
        let a = vm.redactionAppearance
        fillColor = a.fillColor
        useOverlay = a.useOverlayText
        fontName = a.fontName
        fontSize = a.fontSize
        fontColor = a.fontColor
        alignment = a.alignment
        switch a.overlaySource {
        case .custom(let s):
            overlayKind = .custom
            customText = s
        case .exemptionCode(let setName, let code):
            overlayKind = .code
            codeSetIndex = codeSets.firstIndex(where: { $0.name == setName }) ?? 0
            codeIndex = codeSets[codeSetIndex].codes.firstIndex(where: { $0.code == code }) ?? 0
        }
    }

    private func apply() {
        var a = RedactionAppearance()
        a.fillColor = fillColor
        a.useOverlayText = useOverlay
        if useOverlay {
            switch overlayKind {
            case .custom:
                a.overlaySource = .custom(customText)
            case .code:
                let set = codeSets[codeSetIndex]
                let code = set.codes[codeIndex]
                a.overlaySource = .exemptionCode(setName: set.name, code: code.code)
            }
        }
        a.fontName = fontName
        a.fontSize = fontSize
        a.fontColor = fontColor
        a.alignment = alignment
        vm.redactionAppearance = a
    }
}
