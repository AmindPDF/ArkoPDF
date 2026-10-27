//  SignatureSheet.swift
//  签名对话框：输入 / 手写 / 图片 三种签名方式。
//  入口：保护模块「签名」工具 → 创建签名 → 点击页面放置。

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 一笔手写笔画。
private struct Stroke {
    let points: [CGPoint]
    let width: CGFloat
    let color: NSColor
}

/// 笔画颜色选项。
private struct PaletteColor: Identifiable {
    let name: String
    let hex: UInt32
    var id: UInt32 { hex }
}

/// 笔画粗细选项。
private struct StrokeWidthOption: Identifiable {
    let label: String
    let value: CGFloat
    var id: CGFloat { value }
}

struct SignatureSheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    private enum Tab: String, CaseIterable, Identifiable {
        case type = "输入"
        case draw = "手写"
        case image = "图片"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .type: return "textformat"
            case .draw: return "pencil.tip"
            case .image: return "photo"
            }
        }
    }

    @State private var tab: Tab = .type

    // 输入
    @State private var typedText = ""

    // 手写
    @State private var strokes: [Stroke] = []
    @State private var strokeColorHex: UInt32 = 0x14143c
    @State private var strokeWidthValue: CGFloat = 4

    // 图片
    @State private var signImage: NSImage?

    private let palette: [PaletteColor] = [
        PaletteColor(name: "深蓝", hex: 0x14143c),
        PaletteColor(name: "蓝", hex: 0x0a84ff),
        PaletteColor(name: "红", hex: 0xff3b30),
        PaletteColor(name: "绿", hex: 0x30d158),
    ]
    private let widths: [StrokeWidthOption] = [
        StrokeWidthOption(label: "细", value: 2),
        StrokeWidthOption(label: "中", value: 4),
        StrokeWidthOption(label: "粗", value: 7),
    ]

    var body: some View {
        VStack(spacing: 0) {
            segmentedControl.padding(14)
            Divider()
            Group {
                switch tab {
                case .type: typePane
                case .draw: drawPane
                case .image: imagePane
                }
            }
            .padding(14)
            Divider()
            foot
        }
        .frame(width: 460, height: 420)
    }

    // MARK: - 分段控件

    private var segmentedControl: some View {
        HStack(spacing: 1) {
            ForEach(Tab.allCases) { t in
                Button {
                    tab = t
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: t.icon).font(.system(size: 12, weight: .medium))
                        Text(t.rawValue).font(.system(size: 13))
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
        .background(RoundedRectangle(cornerRadius: 7).fill(Color(nsColor: .controlBackgroundColor)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.secondary.opacity(0.25)))
    }

    // MARK: - 输入 Tab

    private var typePane: some View {
        VStack(spacing: 10) {
            TextField("在此输入您的签名", text: $typedText)
                .textFieldStyle(.plain)
                .font(.custom("Snell Roundhand", size: 42))
                .multilineTextAlignment(.center)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.3)))
                )
        }
    }

    // MARK: - 手写 Tab

    private var drawPane: some View {
        VStack(spacing: 10) {
            DrawCanvas(strokes: $strokes, color: color(fromHex: strokeColorHex), lineWidth: strokeWidthValue)
                .frame(width: 400, height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.3)))
                )

            // 颜色 + 粗细
            HStack(spacing: 14) {
                Text("颜色").font(.system(size: 12)).foregroundColor(.secondary)
                ForEach(palette) { item in
                    Button {
                        strokeColorHex = item.hex
                    } label: {
                        Circle()
                            .fill(Color(nsColor: color(fromHex: item.hex)))
                            .frame(width: 18, height: 18)
                            .overlay(Circle().strokeBorder(strokeColorHex == item.hex ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: strokeColorHex == item.hex ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .help(item.name)
                }

                Text("粗细").font(.system(size: 12)).foregroundColor(.secondary)
                ForEach(widths) { w in
                    Button {
                        strokeWidthValue = w.value
                    } label: {
                        Text(w.label)
                            .font(.system(size: 12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(strokeWidthValue == w.value ? Color.accentColor : Color.clear)
                            )
                            .foregroundColor(strokeWidthValue == w.value ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 图片 Tab

    private var imagePane: some View {
        VStack {
            if let img = signImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 160)
            } else {
                Button {
                    pickImage()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo").font(.system(size: 26))
                        Text("点击选择图片").font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 底部

    private var foot: some View {
        HStack(spacing: 8) {
            Button("清除") { clear() }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            Spacer()
            Button("取消") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button("确定") { confirm() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(14)
    }

    // MARK: - 动作

    private func clear() {
        typedText = ""
        strokes = []
        signImage = nil
    }

    private func confirm() {
        guard let rendered = renderSignature() else {
            vm.lastError = "请先创建签名"
            return
        }
        vm.confirmSignature(jpegPath: rendered.path, pixelWidth: rendered.width, pixelHeight: rendered.height)
        dismiss()
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            signImage = img
        }
    }

    // MARK: - 渲染到 JPEG

    private func renderSignature() -> (path: String, width: CGFloat, height: CGFloat)? {
        switch tab {
        case .type:
            let t = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return nil }
            return saveJPEG(renderTypedText(t))
        case .draw:
            guard !strokes.isEmpty else { return nil }
            return saveJPEG(renderStrokesToImage(strokes, size: CGSize(width: 400, height: 160)))
        case .image:
            guard let img = signImage else { return nil }
            return saveJPEG(img)
        }
    }

    private func renderTypedText(_ text: String) -> NSImage {
        let size = CGSize(width: 400, height: 160)
        let font = NSFont(name: "Snell Roundhand", size: 48)
            ?? NSFont.systemFont(ofSize: 48, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let attr = NSAttributedString(string: text, attributes: attrs)
        let textSize = attr.size()

        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        let x = (size.width - textSize.width) / 2
        let y = (size.height - textSize.height) / 2
        attr.draw(at: NSPoint(x: x, y: y))
        image.unlockFocus()
        return image
    }

    private func renderStrokesToImage(_ strokes: [Stroke], size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        for stroke in strokes {
            let path = NSBezierPath()
            if let f = stroke.points.first {
                path.move(to: NSPoint(x: f.x, y: size.height - f.y))  // 翻转 Y（Canvas 顶原点 → NSImage 底原点）
            }
            for p in stroke.points.dropFirst() {
                path.line(to: NSPoint(x: p.x, y: size.height - p.y))
            }
            stroke.color.setStroke()
            path.lineWidth = stroke.width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
        image.unlockFocus()
        return image
    }

    private func saveJPEG(_ image: NSImage) -> (path: String, width: CGFloat, height: CGFloat)? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else { return nil }
        let path = NSTemporaryDirectory() + "arko_sign_\(UUID().uuidString).jpg"
        try? jpg.write(to: URL(fileURLWithPath: path))
        return (path, image.size.width, image.size.height)
    }

    private func color(fromHex hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}

// MARK: - 手写画布

private struct DrawCanvas: View {
    @Binding var strokes: [Stroke]
    let color: NSColor
    let lineWidth: CGFloat
    @State private var current: [CGPoint] = []

    var body: some View {
        Canvas { context, _ in
            for stroke in strokes {
                var path = Path()
                if let f = stroke.points.first { path.move(to: f) }
                for p in stroke.points.dropFirst() { path.addLine(to: p) }
                context.stroke(path, with: .color(Color(nsColor: stroke.color)), lineWidth: stroke.width)
            }
            if current.count > 1 {
                var path = Path()
                path.move(to: current[0])
                for p in current.dropFirst() { path.addLine(to: p) }
                context.stroke(path, with: .color(Color(nsColor: color)), lineWidth: lineWidth)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in current.append(v.location) }
                .onEnded { _ in
                    if current.count >= 1 {
                        strokes.append(Stroke(points: current, width: lineWidth, color: color))
                    }
                    current = []
                }
        )
    }
}
