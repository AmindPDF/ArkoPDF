//  PDFDocumentView.swift
//  文档主视图：单页 / 单页连续 / 双页 / 双页连续四种模式，
//  页面画布（NSView）负责渲染、选区高亮、鼠标路由。

import SwiftUI
import AppKit
import Combine

struct PDFDocumentView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        GeometryReader { geo in
            content
                .onAppear { vm.setViewportWidth(geo.size.width) }
                .onChange(of: geo.size.width) { newWidth in vm.setViewportWidth(newWidth) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.document == nil {
            placeholder
        } else {
            switch vm.displayMode {
            case .single: SinglePageView()
            case .singleContinuous: SingleContinuousView()
            case .double: DoublePageView()
            case .doubleContinuous: DoubleContinuousView()
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("打开一个 PDF 开始编辑")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 单页模式

private struct SinglePageView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            PDFPageCanvas(viewModel: vm, pageIndex: vm.currentPage)
                .frame(width: frameW, height: frameH)
                .padding(48)
        }
    }

    private var frameW: CGFloat {
        vm.pageSizeInPoints(at: vm.currentPage).width * CGFloat(vm.zoom)
    }
    private var frameH: CGFloat {
        vm.pageSizeInPoints(at: vm.currentPage).height * CGFloat(vm.zoom)
    }
}

// MARK: - 单页连续模式

private struct SingleContinuousView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<vm.pageCount, id: \.self) { i in
                    PDFPageCanvas(viewModel: vm, pageIndex: i)
                        .frame(width: pageW(i), height: pageH(i))
                        .id("page-\(i)")
                        .padding(.horizontal, 48)
                }
            }
            .padding(.vertical, 28)
        }
    }

    private func pageW(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).width * CGFloat(vm.zoom) }
    private func pageH(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).height * CGFloat(vm.zoom) }
}

// MARK: - 双页模式（单跨页）

private struct DoublePageView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            SpreadView(spreadIndex: vm.spreadIndex(forPage: vm.currentPage))
                .padding(48)
        }
    }
}

// MARK: - 双页连续模式

private struct DoubleContinuousView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<vm.spreadCount, id: \.self) { s in
                    SpreadView(spreadIndex: s)
                        .id("spread-\(s)")
                        .padding(.horizontal, 48)
                }
            }
            .padding(.vertical, 28)
        }
    }
}

// MARK: - 一个跨页（两页并排）

private struct SpreadView: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let spreadIndex: Int

    private var spread: (left: Int?, right: Int?) {
        vm.spread(forIndex: spreadIndex)
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左页；封面跨页左页为空 → 留白占位
            if let left = spread.left {
                PDFPageCanvas(viewModel: vm, pageIndex: left)
                    .frame(width: pageW(left), height: pageH(left))
            } else {
                Color.clear
                    .frame(width: pageW(0), height: pageH(0))
            }
            // 右页
            if let right = spread.right {
                PDFPageCanvas(viewModel: vm, pageIndex: right)
                    .frame(width: pageW(right), height: pageH(right))
            }
        }
    }

    private func pageW(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).width * CGFloat(vm.zoom) }
    private func pageH(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).height * CGFloat(vm.zoom) }
}

// MARK: - 画布（NSViewRepresentable）

private struct PDFPageCanvas: NSViewRepresentable {
    @ObservedObject var viewModel: PDFEditorViewModel
    let pageIndex: Int

    func makeNSView(context: Context) -> PDFPageCanvasView {
        let view = PDFPageCanvasView()
        view.viewModel = viewModel
        view.pageIndex = pageIndex
        return view
    }

    func updateNSView(_ nsView: PDFPageCanvasView, context: Context) {
        nsView.viewModel = viewModel
        nsView.pageIndex = pageIndex
        nsView.needsDisplay = true
    }
}

// MARK: - 画布 NSView

final class PDFPageCanvasView: NSView {
    weak var viewModel: PDFEditorViewModel?
    var pageIndex: Int = 0

    private var cancellables = Set<AnyCancellable>()

    /// 顶部为原点的翻转坐标系：与 SDK 产出的自顶向下位图一致，鼠标换算简单。
    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let vm = viewModel else { return }
        cancellables.removeAll()
        vm.$selection.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$renderRevision.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$zoom.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
    }

    private var zoom: CGFloat { CGFloat(viewModel?.zoom ?? 1.0) }

    private var pageSize: CGSize {
        guard let vm = viewModel else { return .zero }
        return vm.pageSizeInPoints(at: pageIndex)
    }

    // MARK: 绘制

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let vm = viewModel else { return }
        let size = pageSize
        guard size.width > 0, size.height > 0 else { return }

        // 页面图
        if let cg = vm.image(forPage: pageIndex, zoom: Double(zoom)) {
            let rect = CGRect(x: 0, y: 0, width: size.width * zoom, height: size.height * zoom)
            let nsImage = NSImage(cgImage: cg, size: NSSize(width: CGFloat(cg.width), height: CGFloat(cg.height)))
            nsImage.draw(in: rect,
                         from: .zero,
                         operation: .sourceOver,
                         fraction: 1.0,
                         respectFlipped: true,
                         hints: nil)
        }

        // 选区高亮
        if let sel = vm.selection, sel.pageIndex == pageIndex, !sel.charBoxes.isEmpty {
            drawSelection(sel, pageSize: size)
        }
    }

    private func drawSelection(_ sel: TextSelection, pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let (r, g, b) = viewModel?.markupColor.rgb ?? (255, 214, 10)
        let color = NSColor(srgbRed: CGFloat(r) / 255,
                            green: CGFloat(g) / 255,
                            blue: CGFloat(b) / 255,
                            alpha: 0.35)
        ctx.setFillColor(color.cgColor)
        for box in sel.charBoxes {
            ctx.fill(userToView(box, pageSize: pageSize))
        }
    }

    // MARK: 坐标换算（用户坐标 Y-up 左下原点 ↔ 视图坐标 Y-down 左上原点）

    private func userToView(_ box: CGRect, pageSize: CGSize) -> CGRect {
        CGRect(x: box.minX * zoom,
               y: (pageSize.height - box.maxY) * zoom,
               width: box.width * zoom,
               height: box.height * zoom)
    }

    private func viewToUser(_ p: CGPoint, pageSize: CGSize) -> CGPoint {
        CGPoint(x: p.x / zoom, y: pageSize.height - p.y / zoom)
    }

    // MARK: 鼠标路由

    override func mouseDown(with event: NSEvent) { route(.down, event) }
    override func mouseDragged(with event: NSEvent) { route(.drag, event) }
    override func mouseUp(with event: NSEvent) { route(.up, event) }

    private func route(_ phase: ToolPhase, _ event: NSEvent) {
        guard let vm = viewModel else { return }
        let p = convert(event.locationInWindow, from: nil)
        let user = viewToUser(p, pageSize: pageSize)
        vm.route(phase, pageIndex: pageIndex, userPoint: user, modifiers: event.modifierFlags)
    }
}
