//  CompareUI.swift
//  文档对比：设置对话框 + 结果视图（三种视图 + 侧栏）+ 导出对话框。

import SwiftUI
import AppKit

// MARK: - 对比设置对话框

struct CompareSetupSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newURL: URL?
    @State private var mode: CompareMode = .basic
    @State private var filters = CompareFilters()
    @State private var privacyConfirmed = false

    private let providers = ["DeepSeek", "Qwen", "智谱 GLM", "OpenAI"]

    var body: some View {
        VStack(spacing: 0) {
            Text("文档对比设置").font(.headline).padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field("旧文档（基准）") {
                        fileBox(vm.document?.filePath ?? "（当前打开的文档）")
                    }
                    field("新文档（对比）") {
                        HStack(spacing: 8) {
                            fileBox(newURL?.lastPathComponent ?? "未选择")
                            Button("选择…") { pickNew() }
                        }
                    }
                    field("对比模式") {
                        Picker("", selection: $mode) {
                            ForEach(CompareMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented).labelsHidden()
                    }
                    field("筛选选项") {
                        HStack(spacing: 14) {
                            Toggle("忽略大小写", isOn: $filters.ignoreCase)
                            Toggle("忽略空格", isOn: $filters.ignoreWhitespace)
                            Toggle("忽略标点", isOn: $filters.ignorePunctuation)
                            Toggle("忽略页眉/页脚", isOn: $filters.ignoreHeaderFooter)
                        }
                        .toggleStyle(.checkbox)
                    }
                    if mode == .ai {
                        aiConfig
                    }
                }
                .padding(16)
            }

            Divider()
            HStack {
                Spacer()
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("开始对比") { start() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(newURL == nil)
            }
            .padding(14)
        }
        .frame(width: 500, height: 560)
    }

    private var aiConfig: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("模型来源") {
                Picker("", selection: $vm.compareAIConfig.source) {
                    ForEach(LLMSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.radioGroup).labelsHidden()
            }
            if vm.compareAIConfig.source == .custom {
                field("模型供应商") {
                    Picker("", selection: $vm.compareAIConfig.provider) {
                        ForEach(providers, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                }
                field("API Key") {
                    SecureField("sk-…", text: $vm.compareAIConfig.apiKey).textFieldStyle(.roundedBorder)
                }
                Toggle("我已知晓内容将发送至所选模型", isOn: $privacyConfirmed)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            content()
        }
    }

    private func fileBox(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc")
            Text(text).lineLimit(1).truncationMode(.middle)
            Spacer()
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)
    }

    private func pickNew() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            newURL = url
        }
    }

    private func start() {
        guard let url = newURL else { return }
        vm.runCompare(newURL: url, mode: mode, filters: filters)
    }
}

// MARK: - 结果视图

struct CompareResultView: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var exportPresented = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                content
                sidebar
            }
        }
        .frame(minWidth: 1000, minHeight: 680)
        .sheet(isPresented: $exportPresented) { CompareExportSheet() }
        .onDisappear { vm.endCompare() }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: vm.compareMode == .ai ? "sparkles" : "text.magnifyingglass")
            Text(vm.compareMode.rawValue)
                .font(.system(size: 13, weight: .semibold))
            Divider().frame(height: 18)
            Picker("", selection: $vm.compareViewMode) {
                ForEach(CompareViewMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 260)
            Divider().frame(height: 18)
            Button("上一个差异") { goToDiff(step: -1) }
            Button("下一个差异") { goToDiff(step: 1) }
            Spacer()
            Button("重新设置") { vm.compareSetupPresented = true }
            Button("导出报告") { exportPresented = true }
                .buttonStyle(.borderedProminent)
            Button("关闭") { dismiss() }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView([.horizontal, .vertical]) {
            if let old = vm.document, let new = vm.compareNewDocument {
                switch vm.compareViewMode {
                case .sideBySide:
                    HStack(alignment: .top, spacing: 24) {
                        pageColumn(doc: old, isOld: true)
                        pageColumn(doc: new, isOld: false)
                    }
                    .padding(20)
                case .revision, .highlight:
                    pageColumn(doc: old, isOld: true, allRects: true)
                        .padding(20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func pageColumn(doc: ArkoDocument, isOld: Bool, allRects: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isOld ? "旧文档" : "新文档")
                .font(.system(size: 12)).foregroundColor(.secondary)
            if let page = doc.page(at: vm.currentPage) {
                let diff = vm.compareDiff(forPage: vm.currentPage)
                let deleted = allRects ? (diff?.deletedRects ?? []) : (isOld ? (diff?.deletedRects ?? []) : [])
                let added = allRects ? (diff?.addedRects ?? []) : (isOld ? [] : (diff?.addedRects ?? []))
                ComparePageView(page: page, deletedRects: deleted, addedRects: added, mode: vm.compareViewMode)
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            Text(vm.compareMode == .ai ? "AI 分析结果" : "变更列表")
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            Divider()
            ScrollView {
                if vm.compareMode == .ai {
                    aiSidebar
                } else {
                    basicSidebar
                }
            }
        }
        .frame(width: 300)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var basicSidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if vm.compareDiffs.isEmpty {
                Text("未发现差异").foregroundColor(.secondary).padding(12)
            } else {
                Text("共 \(vm.compareDiffs.count) 页有差异")
                    .font(.system(size: 11.5)).foregroundColor(.secondary).padding(12)
                ForEach(vm.compareDiffs, id: \.pageIndex) { diff in
                    Button {
                        vm.currentPage = diff.pageIndex
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("第 \(diff.pageIndex + 1) 页").font(.system(size: 12.5, weight: .medium))
                                Spacer()
                                if diff.deletedCount > 0 { Text("删 \(diff.deletedCount)").font(.system(size: 11)).foregroundColor(.red) }
                                if diff.addedCount > 0 { Text("增 \(diff.addedCount)").font(.system(size: 11)).foregroundColor(.green) }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(vm.currentPage == diff.pageIndex ? Color.accentColor.opacity(0.12) : Color.clear)
                        .cornerRadius(7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var aiSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            if vm.compareAnalyzing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在 AI 分析…").font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            if !vm.compareAIResult.summary.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("修改摘要").font(.system(size: 12, weight: .semibold))
                    Text(vm.compareAIResult.summary).font(.system(size: 12.5)).fixedSize(horizontal: false, vertical: true)
                }
                .padding(11).background(Color.purple.opacity(0.08)).cornerRadius(8)
            }
            ForEach(vm.compareAIResult.changes) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.category).font(.system(size: 12, weight: .semibold))
                        Text(c.type.rawValue).font(.system(size: 11)).foregroundColor(.secondary)
                        Spacer()
                    }
                    if !c.oldText.isEmpty { Text(c.oldText).font(.system(size: 11.5)).strikethrough().foregroundColor(.red) }
                    if !c.newText.isEmpty { Text(c.newText).font(.system(size: 11.5)).foregroundColor(.green) }
                    if !c.summary.isEmpty { Text(c.summary).font(.system(size: 12)) }
                }
                .padding(11).background(Color(nsColor: .textBackgroundColor)).cornerRadius(8)
            }
            if !vm.compareAIResult.risks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("风险提示").font(.system(size: 12, weight: .semibold)).foregroundColor(.red)
                    ForEach(vm.compareAIResult.risks, id: \.self) { r in
                        Text("• \(r)").font(.system(size: 12)).foregroundColor(.red.opacity(0.9))
                    }
                }
                .padding(11).background(Color.red.opacity(0.08)).cornerRadius(8)
            }
        }
        .padding(12)
    }

    private func goToDiff(step: Int) {
        guard !vm.compareDiffs.isEmpty else { return }
        let pages = vm.compareDiffs.map { $0.pageIndex }.sorted()
        guard let idx = pages.firstIndex(of: vm.currentPage) else {
            vm.currentPage = pages.first ?? vm.currentPage
            return
        }
        let next = idx + step
        if next >= 0 && next < pages.count { vm.currentPage = pages[next] }
    }
}

// MARK: - 单页渲染 + 差异叠加

struct ComparePageView: View {
    let page: ArkoPage
    let deletedRects: [CGRect]
    let addedRects: [CGRect]
    let mode: CompareViewMode

    var body: some View {
        let w = page.widthInPoints
        let h = page.heightInPoints
        ZStack(alignment: .topLeading) {
            if let cg = page.renderImage(atScale: 1.0) {
                Image(nsImage: NSImage(cgImage: cg, size: NSSize(width: w, height: h)))
                    .resizable().frame(width: w, height: h)
            } else {
                Rectangle().fill(Color.white).frame(width: w, height: h)
            }
            Canvas { ctx, _ in
                switch mode {
                case .sideBySide, .highlight:
                    for r in deletedRects { ctx.fill(Path(viewRect(r, h)), with: .color(.red.opacity(0.22))) }
                    for r in addedRects { ctx.fill(Path(viewRect(r, h)), with: .color(.green.opacity(0.22))) }
                case .revision:
                    for r in deletedRects {
                        let vr = viewRect(r, h)
                        var p = Path(); p.move(to: CGPoint(x: vr.minX, y: vr.midY)); p.addLine(to: CGPoint(x: vr.maxX, y: vr.midY))
                        ctx.stroke(p, with: .color(.red), lineWidth: 1)
                    }
                    for r in addedRects {
                        let vr = viewRect(r, h)
                        var p = Path(); p.move(to: CGPoint(x: vr.minX, y: vr.maxY - 1)); p.addLine(to: CGPoint(x: vr.maxX, y: vr.maxY - 1))
                        ctx.stroke(p, with: .color(.green), lineWidth: 1)
                    }
                }
            }
            .frame(width: w, height: h)
        }
        .frame(width: w, height: h)
        .background(Color.white)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private func viewRect(_ r: CGRect, _ pageHeight: CGFloat) -> CGRect {
        CGRect(x: r.minX, y: pageHeight - r.maxY, width: r.width, height: r.height)
    }
}

// MARK: - 导出对话框

struct CompareExportSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var format = 0      // 0=纯文本清单 1=合并版 PDF
    @State private var scope = 0       // 0=全部 1=当前页 2=勾选
    @State private var includeAI = true

    var body: some View {
        VStack(spacing: 0) {
            Text("导出对比报告").font(.headline).padding(16)
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                field("导出形式") {
                    Picker("", selection: $format) {
                        Text("纯文本「修改清单报告」").tag(0)
                        Text("合并版 PDF（带批注与高亮）").tag(1)
                    }
                    .pickerStyle(.radioGroup).labelsHidden()
                }
                field("导出范围") {
                    Picker("", selection: $scope) {
                        Text("全部差异").tag(0)
                        Text("仅当前页").tag(1)
                    }
                    .pickerStyle(.radioGroup).labelsHidden()
                }
                Toggle("包含 AI 分析摘要（仅 AI 模式）", isOn: $includeAI).toggleStyle(.checkbox)
                Text("导出将生成一份全新的 PDF 文件，不影响当前文档。")
                    .font(.system(size: 11.5)).foregroundColor(.secondary)
            }
            .padding(16)
            Divider()
            HStack {
                Spacer()
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("导出") { export() }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 420)
    }

    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            content()
        }
    }

    private func export() {
        let panel = NSSavePanel()
        if format == 0 {
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "对比报告.txt"
        } else {
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "对比结果.pdf"
        }
        if panel.runModal() == .OK, let url = panel.url {
            vm.exportCompareReport(to: url, format: format)
            dismiss()
        }
    }
}

// MARK: - 对比进度覆盖层

struct CompareProgressOverlay: View {
    let text: String
    let progress: Double?   // nil = 不确定（spinner）

    var body: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("正在对比文档").font(.headline)
                if let p = progress {
                    ProgressView(value: p).progressViewStyle(.linear).frame(width: 260)
                } else {
                    ProgressView().controlSize(.small)
                }
                Text(text).font(.system(size: 12)).foregroundColor(.secondary)
            }
            .padding(22)
            .frame(width: 340)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.22), radius: 16, y: 5)
            )
        }
    }
}
