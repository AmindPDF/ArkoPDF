//  PhotoBookSheet.swift
//  PDF 相册排版：照片按 cols×rows 网格排到纸张上生成 PDF。
//  大量照片时两个预览都靠 LazyVGrid / LazyVStack 懒加载，只渲染可见项。

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 类型

struct PhotoPaper: Identifiable {
    let id: String
    let name: String
    let widthMM: Double
    let heightMM: Double
}

struct PhotoLayout: Identifiable {
    let id: String
    let name: String
    let cols: Int
    let rows: Int
}

struct PhotoItem: Identifiable {
    let id = UUID()
    let url: URL
    let pixelWidth: Int
    let pixelHeight: Int
}

private enum PhotoViewMode: String, CaseIterable, Identifiable {
    case grid = "▦"
    case list = "☰"
    var id: String { rawValue }
}

// MARK: - 常量

private let papers: [PhotoPaper] = [
    .init(id: "a4", name: "A4", widthMM: 210, heightMM: 297),
    .init(id: "letter", name: "Letter", widthMM: 216, heightMM: 279),
    .init(id: "5in", name: "5 寸", widthMM: 89, heightMM: 127),
    .init(id: "6in", name: "6 寸", widthMM: 102, heightMM: 152),
    .init(id: "7in", name: "7 寸", widthMM: 127, heightMM: 178),
    .init(id: "square", name: "方 6 寸", widthMM: 152, heightMM: 152),
]

private let layouts: [PhotoLayout] = [
    .init(id: "2x2", name: "2×2", cols: 2, rows: 2),
    .init(id: "2x3", name: "2×3", cols: 2, rows: 3),
    .init(id: "3x3", name: "3×3", cols: 3, rows: 3),
    .init(id: "3x4", name: "3×4", cols: 3, rows: 4),
    .init(id: "4x5", name: "4×5", cols: 4, rows: 5),
]

private let mmToPt = 72.0 / 25.4

// MARK: - 主视图

struct PhotoBookSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var photos: [PhotoItem] = []
    @State private var paper: PhotoPaper = papers[0]
    @State private var layout: PhotoLayout = layouts[0]
    @State private var customN = 4
    @State private var marginMM: Double = 10
    @State private var spaceMM: Double = 3
    @State private var viewMode: PhotoViewMode = .grid
    @State private var isSaving = false

    private var perPage: Int { layout.cols * layout.rows }
    private var pageCount: Int { max(1, Int(ceil(Double(photos.count) / Double(perPage)))) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                controlPanel
                Divider()
                previewPane
            }
            Divider()
            statusBar
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    // MARK: 顶部

    private var header: some View {
        HStack(spacing: 10) {
            Text("相册排版").font(.headline)
            Text("PDF PhotoBook").font(.caption).foregroundColor(.secondary)
            Spacer()
            Button("取消") { dismiss() }
            Button("生成并保存 PDF…") { save() }
                .buttonStyle(.borderedProminent)
                .disabled(photos.isEmpty || isSaving)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: 左侧控制面板

    private var controlPanel: some View {
        VStack(spacing: 0) {
            // 照片区
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("照片（\(photos.count)）")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $viewMode) {
                        ForEach(PhotoViewMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                photoList
                HStack(spacing: 6) {
                    Button("＋ 添加照片") { pickPhotos() }
                    Button("清空") { photos.removeAll() }
                        .disabled(photos.isEmpty)
                }
                .font(.caption)
            }
            .padding(12)

            Divider()

            // 设置区
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    paperSection
                    layoutSection
                    spacingSection
                }
                .padding(12)
            }
        }
        .frame(width: 300)
    }

    /// 照片列表（Lazy 懒加载，200 张不卡）。
    @ViewBuilder
    private var photoList: some View {
        ScrollView {
            if viewMode == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 6)], spacing: 6) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { idx, p in
                        photoThumb(p, index: idx)
                    }
                }
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { idx, p in
                        photoRow(p, index: idx)
                    }
                }
            }
        }
    }

    private func photoThumb(_ p: PhotoItem, index: Int) -> some View {
        thumbnailImage(p)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(alignment: .topTrailing) {
                Button { removePhoto(p) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white, .black.opacity(0.55))
                }
                .buttonStyle(.plain)
                .padding(2)
            }
            .overlay(alignment: .bottomLeading) {
                Text("\(index + 1)")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                    .padding(2)
            }
            .contextMenu {
                Button("删除") { removePhoto(p) }
            }
    }

    private func photoRow(_ p: PhotoItem, index: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.caption2).monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 22, alignment: .trailing)
            thumbnailImage(p)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(p.url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button { removePhoto(p) } label: {
                Image(systemName: "xmark").font(.caption).foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.06)))
    }

    private func thumbnailImage(_ p: PhotoItem) -> some View {
        Group {
            if let ns = NSImage(contentsOf: p.url) {
                Image(nsImage: ns).resizable().scaledToFill()
            } else {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
        }
    }

    // 纸张
    private var paperSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("纸张")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                ForEach(papers) { p in
                    paperCell(p)
                }
            }
        }
    }

    private func paperCell(_ p: PhotoPaper) -> some View {
        VStack(spacing: 2) {
            Text(p.name).font(.caption)
            Text("\(Int(p.widthMM))×\(Int(p.heightMM)) mm").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(paper.id == p.id ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(paper.id == p.id ? Color.accentColor : Color.clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { paper = p }
    }

    // 布局
    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("布局（每页照片数）")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 6)], spacing: 6) {
                ForEach(layouts) { l in
                    layoutCell(l)
                }
            }
            HStack(spacing: 6) {
                Text("自定义 n×n").font(.caption)
                Stepper("\(customN)", value: $customN, in: 1...10)
                    .font(.caption)
            }
        }
    }

    private func layoutCell(_ l: PhotoLayout) -> some View {
        VStack(spacing: 3) {
            gridIcon(cols: l.cols, rows: l.rows)
            Text(l.name).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(layout.id == l.id ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(layout.id == l.id ? Color.accentColor : Color.clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { layout = l }
    }

    private func gridIcon(cols: Int, rows: Int) -> some View {
        VStack(spacing: 1.5) {
            ForEach(0..<min(rows, 4), id: \.self) { _ in
                HStack(spacing: 1.5) {
                    ForEach(0..<min(cols, 4), id: \.self) { _ in
                        Rectangle().fill(Color.secondary.opacity(0.4)).frame(width: 5, height: 5)
                    }
                }
            }
        }
    }

    // 排版
    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("排版")
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("页边距").font(.caption)
                    Spacer()
                    Text("\(Int(marginMM)) mm").font(.caption).foregroundColor(.accentColor).monospacedDigit()
                }
                Slider(value: $marginMM, in: 0...30)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("照片间距").font(.caption)
                    Spacer()
                    Text("\(Int(spaceMM)) mm").font(.caption).foregroundColor(.accentColor).monospacedDigit()
                }
                Slider(value: $spaceMM, in: 0...20)
            }
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
    }

    // MARK: 右侧预览

    private var previewPane: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                ForEach(0..<pageCount, id: \.self) { page in
                    previewPage(page)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func previewPage(_ page: Int) -> some View {
        let scale = CGFloat(min(420.0 / paper.widthMM, 1.0))
        let pw = CGFloat(paper.widthMM) * scale
        let ph = CGFloat(paper.heightMM) * scale
        let m = CGFloat(marginMM * mmToPt) * scale
        let s = CGFloat(spaceMM * mmToPt) * scale
        let cellW = (pw - m * 2 - s * CGFloat(layout.cols - 1)) / CGFloat(layout.cols)
        let cellH = (ph - m * 2 - s * CGFloat(layout.rows - 1)) / CGFloat(layout.rows)

        return VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellW), spacing: s), count: layout.cols),
                      spacing: s) {
                ForEach(0..<perPage, id: \.self) { i in
                    let idx = page * perPage + i
                    if idx < photos.count {
                        thumbnailImage(photos[idx])
                            .frame(width: cellW, height: cellH)
                            .clipped()
                    } else {
                        Color.clear.frame(width: cellW, height: cellH)
                    }
                }
            }
            .padding(m)
            .frame(width: pw, height: ph)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.1)))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 2)

            if pageCount > 1 {
                Text("第 \(page + 1) / \(pageCount) 页")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    // MARK: 状态栏

    private var statusBar: some View {
        HStack(spacing: 16) {
            Text("照片 \(photos.count) 张")
            Text("布局 \(layout.cols)×\(layout.rows)")
            Text("纸张 \(paper.name)（\(Int(paper.widthMM))×\(Int(paper.heightMM))mm）")
            Text("页数 \(pageCount)")
            Spacer()
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: 操作

    private func pickPhotos() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if let (w, h) = Self.pixelSize(of: url) {
                photos.append(PhotoItem(url: url, pixelWidth: w, pixelHeight: h))
            }
        }
    }

    private func removePhoto(_ p: PhotoItem) {
        photos.removeAll { $0.id == p.id }
    }

    private func save() {
        guard !photos.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "PhotoBook.pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            let book = ArkoPhotoBook()
            book.setPaperWidth(Float(paper.widthMM * mmToPt), height: Float(paper.heightMM * mmToPt))
            book.setLayoutCols(Int32(layout.cols), rows: Int32(layout.rows))
            book.setMarginsHorizontal(Float(marginMM * mmToPt), vertical: Float(marginMM * mmToPt))
            book.setSpacingHorizontal(Float(spaceMM * mmToPt), vertical: Float(spaceMM * mmToPt))
            book.setPhotoRatio(Float(5.0 / 7.0))
            for p in photos {
                book.addImage(atPath: p.url.path, pixelWidth: Int32(p.pixelWidth), pixelHeight: Int32(p.pixelHeight))
            }
            var result: Result<Void, Error> = .success(())
            do {
                _ = try book.buildAndSave(to: url)
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success: dismiss()
                case .failure(let e): vm.lastError = e.localizedDescription
                }
            }
        }
    }

    /// 读图片像素尺寸（不加载整图）。
    static func pixelSize(of url: URL) -> (Int, Int)? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (w, h)
    }
}
