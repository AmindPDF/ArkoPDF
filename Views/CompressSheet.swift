//  CompressSheet.swift
//  压缩文档：预设 + 图片质量/DPI + 优化项 + 丢弃/扁平化/清理 + 分析 + 压缩并保存。

import SwiftUI
import AppKit

// MARK: - 压缩预设

enum CompressPreset: String, CaseIterable, Identifiable {
    case max, std, high, lossless
    var id: String { rawValue }

    var title: String {
        switch self { case .max: return "最大压缩"; case .std: return "标准"; case .high: return "高质量"; case .lossless: return "无损" }
    }
    var subtitle: String {
        switch self { case .max: return "画质最低"; case .std: return "均衡"; case .high: return "画质优先"; case .lossless: return "不重压图片" }
    }
    var quality: Int {
        switch self { case .max: return 30; case .std: return 60; case .high: return 85; case .lossless: return 0 }
    }
    var dpi: Int {
        switch self { case .max: return 150; case .std: return 200; case .high: return 300; case .lossless: return 0 }
    }
    var isLossless: Bool { self == .lossless }
}

// MARK: - 审计结果

struct CompressAudit {
    let image: Int64
    let stream: Int64
    let invalidObj: Int64
    let font: Int64
    let discard: Int64
    let flatten: Int64
    let total: Int64

    init(image: Int64, stream: Int64, invalidObj: Int64, font: Int64, discard: Int64, flatten: Int64, total: Int64) {
        self.image = image
        self.stream = stream
        self.invalidObj = invalidObj
        self.font = font
        self.discard = discard
        self.flatten = flatten
        self.total = total
    }

    init?(dict: [AnyHashable: Any]?) {
        guard let d = dict else { return nil }
        func v(_ key: String) -> Int64 { (d[key] as? NSNumber)?.int64Value ?? 0 }
        image = v("image")
        stream = v("stream")
        invalidObj = v("invalidObj")
        font = v("font")
        discard = v("discard")
        flatten = v("flatten")
        total = v("total")
    }

    static let zero = CompressAudit(image: 0, stream: 0, invalidObj: 0, font: 0, discard: 0, flatten: 0, total: 0)
}

private func byteString(_ bytes: Int64) -> String {
    let f = ByteCountFormatter()
    f.countStyle = .file
    return f.string(fromByteCount: bytes)
}

// MARK: - 视图

struct CompressSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    // 预设 + 图片
    @State private var preset: CompressPreset = .std
    @State private var quality: Double = 60
    @State private var dpi: Int = 200

    // 通用优化
    @State private var flateStreams = true
    @State private var lzwToFlate = true
    @State private var removeInvalidObjects = true
    @State private var unembedFonts = true

    // 丢弃对象
    @State private var discardJavaScript = false
    @State private var discardThumbnails = true
    @State private var discardPrintSettings = false
    @State private var discardBookmarks = false
    @State private var discardAttachments = false
    @State private var discardPrivateData = false
    @State private var discardMetadata = true
    @State private var discardFormFields = false
    @State private var discardExternalCrossRefs = false

    // 扁平化 / 清理
    @State private var flattenFormFields = false
    @State private var flattenAnnotations = false
    @State private var removeInvalidBookmarks = false
    @State private var removeInvalidLinks = false
    @State private var removeUnreferencedDests = false

    // 状态
    @State private var fileSizeText = ""
    @State private var audit: CompressAudit?
    @State private var isAuditing = false
    @State private var isCompressing = false
    @State private var progress: Double = 0
    @State private var errorMessage: String?

    private let dpiOptions: [(Int, String)] = [(0, "不降采样"), (150, "150 DPI"), (200, "200 DPI"), (300, "300 DPI")]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    qualitySection
                    generalSection
                    discardSection
                    flattenSection
                    cleanupSection
                    if audit != nil { auditSection }
                    if isCompressing { progressSection }
                }
                .padding(16)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 640)
        .onAppear(perform: loadFileSize)
        .alert("压缩文档", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: 头部（标题 + 预设）

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("压缩文档").font(.headline)
            Text(fileSizeText).font(.caption).foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(Array(CompressPreset.allCases.enumerated()), id: \.element) { index, p in
                    Button { selectPreset(p) } label: {
                        VStack(spacing: 1) {
                            Text(p.title).font(.system(size: 12.5))
                            Text(p.subtitle).font(.system(size: 10)).opacity(0.75)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(preset == p ? .white : .primary)
                    .background(preset == p ? Color.accentColor : Color.clear)
                    if index < CompressPreset.allCases.count - 1 { Divider() }
                }
            }
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(nsColor: .separatorColor)))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(16)
    }

    // MARK: 图片质量 + DPI

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("图片质量（彩色 / 灰度 → JPEG）").font(.system(size: 12)).foregroundColor(.secondary)
                HStack {
                    Slider(value: $quality, in: 1...100, step: 1) { Text("质量") }
                        .disabled(preset.isLossless)
                    Text("\(Int(quality))").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 34, alignment: .trailing)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("图片降采样").font(.system(size: 12)).foregroundColor(.secondary)
                Picker("", selection: $dpi) {
                    ForEach(dpiOptions, id: \.0) { Text($0.1).tag($0.0) }
                }
                .labelsHidden()
                .disabled(preset.isLossless)
            }
        }
    }

    // MARK: 通用优化

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("通用优化").font(.system(size: 12)).foregroundColor(.secondary)
            Toggle("对象流 Flate 压缩（无过滤 / LZW）", isOn: $flateStreams).toggleStyle(.checkbox)
            Toggle("删除无效对象", isOn: $removeInvalidObjects).toggleStyle(.checkbox)
            Toggle("字体取消嵌入（非符号字体）", isOn: $unembedFonts).toggleStyle(.checkbox)
        }
    }

    // MARK: 丢弃对象

    private var discardSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("页面缩略图", isOn: $discardThumbnails).toggleStyle(.checkbox)
                Toggle("文档元数据（标题 / 作者 / XMP）", isOn: $discardMetadata).toggleStyle(.checkbox)
                Toggle("JavaScript 动作", isOn: $discardJavaScript).toggleStyle(.checkbox)
                Toggle("嵌入打印设置", isOn: $discardPrintSettings).toggleStyle(.checkbox)
                Toggle("书签", isOn: $discardBookmarks).toggleStyle(.checkbox)
                Toggle("文件附件", isOn: $discardAttachments).toggleStyle(.checkbox)
                Toggle("其它应用私有数据", isOn: $discardPrivateData).toggleStyle(.checkbox)
                Toggle("表单字段", isOn: $discardFormFields).toggleStyle(.checkbox)
                Toggle("外部交叉引用", isOn: $discardExternalCrossRefs).toggleStyle(.checkbox)
            }
            .padding(.top, 6)
        } label: {
            Text("丢弃对象").font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // MARK: 扁平化 / 清理

    private var flattenSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("扁平化表单字段", isOn: $flattenFormFields).toggleStyle(.checkbox)
                Toggle("扁平化标注", isOn: $flattenAnnotations).toggleStyle(.checkbox)
            }
            .padding(.top, 6)
        } label: {
            Text("扁平化").font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    private var cleanupSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("删除无效书签", isOn: $removeInvalidBookmarks).toggleStyle(.checkbox)
                Toggle("删除无效链接", isOn: $removeInvalidLinks).toggleStyle(.checkbox)
                Toggle("删除未引用命名目的地", isOn: $removeUnreferencedDests).toggleStyle(.checkbox)
            }
            .padding(.top, 6)
        } label: {
            Text("清理").font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // MARK: 分析结果

    private var auditSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("分析结果（估算）").font(.system(size: 12, weight: .semibold))
                Spacer()
                if isAuditing { ProgressView().controlSize(.small) }
            }
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                auditRow("图片优化", audit!.image)
                auditRow("流压缩", audit!.stream)
                auditRow("删除无效对象", audit!.invalidObj)
                auditRow("字体取消嵌入", audit!.font)
                auditRow("丢弃对象", audit!.discard)
                Divider()
                HStack {
                    Text("预计可节省").font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(byteString(audit!.total)).font(.system(size: 12, weight: .semibold)).foregroundColor(.green)
                }
                .padding(.vertical, 7)
            }
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))

            if let audit = audit, audit.total > 0 {
                Text("以上为估算值，实际以压缩后为准。")
                    .font(.system(size: 10.5)).foregroundColor(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    private func auditRow(_ name: String, _ bytes: Int64) -> some View {
        HStack {
            Text(name).font(.system(size: 12)).foregroundColor(.secondary)
            Spacer()
            Text(byteString(bytes)).font(.system(size: 12))
        }
        .padding(.vertical, 6)
    }

    // MARK: 进度

    private var progressSection: some View {
        HStack(spacing: 12) {
            Text("压缩中…").font(.system(size: 12)).foregroundColor(.secondary)
            ProgressView(value: progress, total: 1.0)
            Text("\(Int(progress * 100))%").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: 底部按钮

    private var footer: some View {
        HStack {
            Button(isCompressing ? "取消" : "关闭") {
                if isCompressing {
                    // 取消标志由后台 isCancelled 块读取
                    cancelCompression()
                } else {
                    dismiss()
                }
            }
            Spacer()
            Button("分析") { runAudit() }
                .disabled(isAuditing || isCompressing)
            Button("压缩并保存") { runCompress() }
                .buttonStyle(.borderedProminent)
                .disabled(isAuditing || isCompressing)
        }
        .padding(14)
    }

    // MARK: 逻辑

    private func selectPreset(_ p: CompressPreset) {
        preset = p
        if !p.isLossless {
            quality = Double(p.quality)
            dpi = p.dpi
        }
    }

    private func loadFileSize() {
        guard let path = vm.document?.filePath, !path.isEmpty else {
            fileSizeText = "当前文档"
            return
        }
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        fileSizeText = "当前文档 · \(byteString(size))"
    }

    private func buildOptions() -> ArkoCompressOptions {
        let o = ArkoCompressOptions()
        if preset.isLossless {
            o.colorCompression = .retain
            o.monoCompression = .retain
        } else {
            o.colorCompression = ArkoColorCompression(rawValue: 1) ?? .retain   // JPEG
            o.monoCompression = ArkoMonoCompression(rawValue: 3) ?? .retain     // CCITT4
        }
        o.quality = Int32(quality)
        o.downsampleDPI = Int32(dpi)
        o.downsampleAbove = Int32(dpi)    // 仅当有效 DPI 高于目标时才降采样
        o.mustReduceSize = true
        o.flateStreams = flateStreams
        o.lzwToFlate = lzwToFlate
        o.removeInvalidObjects = removeInvalidObjects
        o.unembedFonts = unembedFonts
        o.discardJavaScript = discardJavaScript
        o.discardPageThumbnails = discardThumbnails
        o.discardPrintSettings = discardPrintSettings
        o.discardBookmarks = discardBookmarks
        o.discardFileAttachments = discardAttachments
        o.discardPrivateData = discardPrivateData
        o.discardMetadata = discardMetadata
        o.discardFormFields = discardFormFields
        o.discardExternalCrossRefs = discardExternalCrossRefs
        o.flattenFormFields = flattenFormFields
        o.flattenAnnotations = flattenAnnotations
        o.removeInvalidBookmarks = removeInvalidBookmarks
        o.removeInvalidLinks = removeInvalidLinks
        o.removeUnreferencedNamedDests = removeUnreferencedDests
        return o
    }

    private func runAudit() {
        guard let doc = vm.document else { return }
        let opts = buildOptions()
        isAuditing = true
        audit = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let dict = try doc.auditCompress(options: opts)
                let a = CompressAudit(dict: dict) ?? .zero
                DispatchQueue.main.async {
                    self.audit = a
                    self.isAuditing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAuditing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func runCompress() {
        guard let doc = vm.document else { return }
        let opts = buildOptions()
        let originalPath = doc.filePath
        vm.compressCancelFlag.isCancelled = false
        isCompressing = true
        progress = 0
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                _ = try doc.optimizeCompress(options: opts, progress: { p in
                    DispatchQueue.main.async { self.progress = Double(p) * 0.85 }
                }, isCancelled: { self.vm.compressCancelFlag.isCancelled })

                // 压缩后写回原文件（有原始路径时）
                if !originalPath.isEmpty {
                    _ = try doc.save(to: URL(fileURLWithPath: originalPath), progress: { p in
                        DispatchQueue.main.async { self.progress = 0.85 + Double(p) * 0.15 }
                    }, isCancelled: { self.vm.compressCancelFlag.isCancelled }, security: self.vm.pendingSecurity)
                }

                DispatchQueue.main.async {
                    self.vm.invalidateAllPages()
                    self.isCompressing = false
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCompressing = false
                    if !self.vm.compressCancelFlag.isCancelled {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func cancelCompression() {
        vm.compressCancelFlag.isCancelled = true
    }
}
