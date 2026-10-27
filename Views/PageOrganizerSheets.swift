//  PageOrganizerSheets.swift
//  页面组织高级操作弹窗：提取 / 插入 / 替换页面，含页码范围选择器
//  （全部 / 范围 / 奇数 / 偶数 / 自定义页码组合 "1,3-5,7-21,24"）。

import SwiftUI
import UniformTypeIdentifiers

/// 页面操作弹窗类型（触发 .sheet）。
enum PageSheetKind: String, Identifiable {
    case extract, insert, replace
    var id: String { rawValue }
}

// MARK: - 页码范围选择器（共用）

struct PageRangePicker: View {
    @Binding var range: PageRange
    let pageCount: Int

    private enum Mode: String, CaseIterable, Identifiable {
        case all = "全部", range = "范围", odd = "奇数页", even = "偶数页", custom = "自定义"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .all
    @State private var startText = "1"
    @State private var endText = ""
    @State private var customText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("选择范围", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in sync() }

            switch mode {
            case .all, .odd, .even:
                EmptyView()
            case .range:
                HStack(spacing: 6) {
                    Text("起始页").font(.caption)
                    TextField("1", text: $startText).textFieldStyle(.roundedBorder).frame(width: 56)
                    Text("~").font(.caption)
                    Text("结束页").font(.caption)
                    TextField("\(max(1, pageCount))", text: $endText).textFieldStyle(.roundedBorder).frame(width: 56)
                }
                .onChange(of: startText) { _ in sync() }
                .onChange(of: endText) { _ in sync() }
            case .custom:
                HStack(spacing: 6) {
                    Text("页码").font(.caption)
                    TextField("1,3-5,7-21,24", text: $customText).textFieldStyle(.roundedBorder)
                }
                .onChange(of: customText) { _ in sync() }
            }

            Text("将选择 \(range.resolvedCount(pageCount: pageCount)) 页")
                .font(.caption).foregroundColor(.secondary)
        }
        .onAppear { sync() }
    }

    private func sync() {
        switch mode {
        case .all: range = .all
        case .range:
            let s = Int(startText) ?? 1
            let e = Int(endText) ?? max(1, pageCount)
            range = .range(start: s, end: e)
        case .odd: range = .odd
        case .even: range = .even
        case .custom: range = .custom(customText)
        }
    }
}

// MARK: - 提取页面

struct ExtractSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @State private var range: PageRange = .all
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("提取页面").font(.headline)
            PageRangePicker(range: $range, pageCount: vm.pageCount)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("提取并导出…") {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.nameFieldStringValue = "extracted.pdf"
                    if panel.runModal() == .OK, let url = panel.url {
                        vm.extractPages(range, to: url)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

// MARK: - 插入页面

struct InsertPagesSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @State private var sourceURL: URL?
    @State private var sourcePageCount: Int = 0
    @State private var range: PageRange = .all
    @State private var insertAtText = "1"
    @State private var position: Position = .after
    @Environment(\.dismiss) private var dismiss

    private enum Position: String, CaseIterable, Identifiable {
        case before = "之前", after = "之后"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("插入页面").font(.headline)

            HStack(spacing: 8) {
                Button("选择源 PDF…") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        sourceURL = url
                        sourcePageCount = ArkoDocument.pageCount(of: url)
                    }
                }
                if let u = sourceURL {
                    Text("\(u.lastPathComponent)（\(sourcePageCount) 页）")
                        .font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }

            PageRangePicker(range: $range, pageCount: sourcePageCount)

            HStack(spacing: 6) {
                Text("插入到第").font(.caption)
                TextField("1", text: $insertAtText).textFieldStyle(.roundedBorder).frame(width: 56)
                Text("页").font(.caption)
                Picker("", selection: $position) {
                    ForEach(Position.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("插入") {
                    guard let url = sourceURL else { return }
                    let pages = range.resolve(pageCount: sourcePageCount)
                    var at = (Int(insertAtText) ?? 1) - 1  // 0-based
                    if position == .after { at += 1 }
                    at = max(0, min(at, vm.pageCount))
                    vm.insertPages(from: url, pages: pages, at: at)
                    dismiss()
                }
                .disabled(sourceURL == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

// MARK: - 替换页面

struct ReplacePagesSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @State private var sourceURL: URL?
    @State private var sourcePageCount: Int = 0
    @State private var range: PageRange = .all
    @State private var startText = "1"
    @State private var countText = "1"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("替换页面").font(.headline)

            HStack(spacing: 8) {
                Button("选择源 PDF…") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        sourceURL = url
                        sourcePageCount = ArkoDocument.pageCount(of: url)
                    }
                }
                if let u = sourceURL {
                    Text("\(u.lastPathComponent)（\(sourcePageCount) 页）")
                        .font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }

            PageRangePicker(range: $range, pageCount: sourcePageCount)

            HStack(spacing: 6) {
                Text("替换：从第").font(.caption)
                TextField("1", text: $startText).textFieldStyle(.roundedBorder).frame(width: 56)
                Text("页起 共").font(.caption)
                TextField("1", text: $countText).textFieldStyle(.roundedBorder).frame(width: 56)
                Text("页").font(.caption)
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("替换") {
                    guard let url = sourceURL else { return }
                    let pages = range.resolve(pageCount: sourcePageCount)
                    let start = (Int(startText) ?? 1) - 1
                    let count = Int(countText) ?? 1
                    vm.replacePages(from: url, pages: pages, at: start, count: count)
                    dismiss()
                }
                .disabled(sourceURL == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

// MARK: - 分发

struct PageOrganizerSheet: View {
    let kind: PageSheetKind

    var body: some View {
        switch kind {
        case .extract: ExtractSheet()
        case .insert: InsertPagesSheet()
        case .replace: ReplacePagesSheet()
        }
    }
}
