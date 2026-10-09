//  PDFDocumentView.swift
//  文档主视图：自定义 NSScrollView 承载页面内容，利用内置放大能力实现
//  捏合/⌘+滚轮中心缩放；单页/单页连续/双页/双页连续四种模式。

import SwiftUI
import AppKit
import Combine

struct PDFDocumentView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        GeometryReader { geo in
            if vm.document == nil {
                placeholder
            } else {
                ZStack(alignment: .top) {
                    PDFScrollView(viewModel: vm)
                        .onAppear { vm.setViewportWidth(geo.size.width) }
                        .onChange(of: geo.size.width) { w in vm.setViewportWidth(w) }
                    // 编辑浮动栏（段落格式 / 图片编辑）
                    EditBarView()
                        .padding(.top, 8)
                }
            }
        }
        .sheet(item: $vm.pendingLink) { draft in
            LinkSettingSheet(draft: draft)
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

// MARK: - 自定义 NSScrollView（放大/中心缩放/捏合）

private struct PDFScrollView: NSViewRepresentable {
    @ObservedObject var viewModel: PDFEditorViewModel

    func makeNSView(context: Context) -> PDFScrollViewImpl {
        let scroll = PDFScrollViewImpl()
        scroll.viewModel = viewModel
        return scroll
    }

    func updateNSView(_ nsView: PDFScrollViewImpl, context: Context) {
        nsView.viewModel = viewModel
        nsView.reloadContentIfNeeded()
    }
}

final class PDFScrollViewImpl: NSScrollView {
    weak var viewModel: PDFEditorViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var syncing = false
    private var currentMode: DisplayMode?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hasVerticalScroller = true
        hasHorizontalScroller = true
        allowsMagnification = true
        minMagnification = 0.25
        maxMagnification = 4.0
        drawsBackground = true
        backgroundColor = NSColor.windowBackgroundColor

        guard let vm = viewModel else { return }
        cancellables.removeAll()

        // vm.zoom → magnification
        vm.$zoom.sink { [weak self] z in
            guard let self = self, !self.syncing else { return }
            self.syncing = true
            self.magnification = CGFloat(z)
            self.syncing = false
        }.store(in: &cancellables)

        // magnification → vm.zoom（捏合时 NSScrollView 自动改 magnification）
        self.publisher(for: \.magnification)
            .sink { [weak self] mag in
                guard let self = self, !self.syncing else { return }
                self.syncing = true
                self.viewModel?.zoom = Double(mag)
                self.syncing = false
            }
            .store(in: &cancellables)

        reloadContent()
        magnification = CGFloat(vm.zoom)
    }

    func reloadContentIfNeeded() {
        guard let vm = viewModel else { return }
        if currentMode != vm.displayMode {
            currentMode = vm.displayMode
            reloadContent()
        }
    }

    private func reloadContent() {
        guard let vm = viewModel else { return }
        let content: AnyView
        switch vm.displayMode {
        case .single: content = AnyView(SinglePageContent())
        case .singleContinuous: content = AnyView(SingleContinuousContent())
        case .double: content = AnyView(DoublePageContent())
        case .doubleContinuous: content = AnyView(DoubleContinuousContent())
        }
        let hosting = NSHostingView(rootView: content.environmentObject(vm))
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        documentView = hosting
    }

    // ⌘+滚轮：以鼠标位置为中心缩放；非 ⌘ 滚轮交给滚动视图正常滚动
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            let delta = event.scrollingDeltaY
            guard delta != 0 else { return }
            let factor = exp(Double(delta) * 0.01)
            let newMag = min(max(magnification * CGFloat(factor), minMagnification), maxMagnification)
            let point = convert(event.locationInWindow, from: nil)
            setMagnification(newMag, centeredAt: point)
            syncing = true
            viewModel?.zoom = Double(newMag)
            syncing = false
        } else {
            super.scrollWheel(with: event)
        }
    }
}

// MARK: - 页面内容（1x 尺寸，缩放交给 NSScrollView）

private struct SinglePageContent: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        PDFPageCanvas(viewModel: vm, pageIndex: vm.currentPage)
            .frame(width: pageW, height: pageH)
            .padding(48)
    }

    private var pageW: CGFloat { vm.pageSizeInPoints(at: vm.currentPage).width }
    private var pageH: CGFloat { vm.pageSizeInPoints(at: vm.currentPage).height }
}

private struct SingleContinuousContent: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<vm.pageCount, id: \.self) { i in
                PDFPageCanvas(viewModel: vm, pageIndex: i)
                    .frame(width: pageW(i), height: pageH(i))
                    .id("page-\(i)")
                    .padding(.horizontal, 48)
            }
        }
        .padding(.vertical, 28)
    }

    private func pageW(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).width }
    private func pageH(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).height }
}

private struct DoublePageContent: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        SpreadContent(spreadIndex: vm.spreadIndex(forPage: vm.currentPage))
            .padding(48)
    }
}

private struct DoubleContinuousContent: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<vm.spreadCount, id: \.self) { s in
                SpreadContent(spreadIndex: s)
                    .id("spread-\(s)")
                    .padding(.horizontal, 48)
            }
        }
        .padding(.vertical, 28)
    }
}

private struct SpreadContent: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let spreadIndex: Int

    private var spread: (left: Int?, right: Int?) {
        vm.spread(forIndex: spreadIndex)
    }

    var body: some View {
        HStack(spacing: 0) {
            if let left = spread.left {
                PDFPageCanvas(viewModel: vm, pageIndex: left)
                    .frame(width: pageW(left), height: pageH(left))
            } else {
                Color.clear
                    .frame(width: pageW(0), height: pageH(0))
            }
            if let right = spread.right {
                PDFPageCanvas(viewModel: vm, pageIndex: right)
                    .frame(width: pageW(right), height: pageH(right))
            }
        }
    }

    private func pageW(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).width }
    private func pageH(_ i: Int) -> CGFloat { vm.pageSizeInPoints(at: i).height }
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

// MARK: - 画布 NSView（1x 尺寸，缩放由外层 NSScrollView 负责）

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
        vm.$focusedAnnotationID.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$draft.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$paragraphSelection.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$imageSelection.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        vm.$linkDraft.sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
    }

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

        // 页面图（固定 1x 渲染，缩放由外层 NSScrollView 放大处理）
        if let cg = vm.image(forPage: pageIndex, zoom: 1.0) {
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
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

        // 定位标注描边
        if let focusID = vm.focusedAnnotationID,
           let focusItem = vm.annotations.first(where: { $0.id == focusID }),
           focusItem.pageIndex == pageIndex {
            drawFocusedAnnotation(focusItem.rect, pageSize: size)
        }

        // 图形标注拖拽草稿预览
        if let draft = vm.draft, draft.pageIndex == pageIndex {
            drawDraft(draft, pageSize: size)
        }

        // 段落编辑选区高亮（蓝色）
        if let ps = vm.paragraphSelection, ps.pageIndex == pageIndex, !ps.boxes.isEmpty {
            drawParagraphSelection(ps.boxes, pageSize: size)
        }

        // 图片编辑选区（蓝色边框 + 四角手柄）
        if let isel = vm.imageSelection, isel.pageIndex == pageIndex {
            drawImageSelection(isel.bbox, pageSize: size)
        }

        // 链接拖拽草稿（虚线蓝色矩形）
        if let ld = vm.linkDraft, ld.pageIndex == pageIndex {
            drawLinkDraft(ld.rect, pageSize: size)
        }
    }

    private func drawParagraphSelection(_ boxes: [CGRect], pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let color = NSColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 0.28)
        ctx.setFillColor(color.cgColor)
        for box in boxes {
            ctx.fill(userToView(box, pageSize: pageSize))
        }
    }

    private func drawImageSelection(_ bbox: CGRect, pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let r = userToView(bbox, pageSize: pageSize)
        let color = NSColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(r)
        // 四角手柄
        let hw: CGFloat = 6
        let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                       CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)]
        ctx.setFillColor(color.cgColor)
        for c in corners {
            ctx.fill(CGRect(x: c.x - hw / 2, y: c.y - hw / 2, width: hw, height: hw))
        }
    }

    private func drawLinkDraft(_ rect: CGRect, pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let r = userToView(rect, pageSize: pageSize)
        let color = NSColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineDash(phase: 0, lengths: [4, 3])
        ctx.stroke(r)
        ctx.setLineDash(phase: 0, lengths: [])
    }

    private func drawFocusedAnnotation(_ rect: CGRect, pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let viewRect = userToView(rect, pageSize: pageSize).insetBy(dx: -4, dy: -4)
        ctx.setStrokeColor(NSColor.controlAccentColor.cgColor)
        ctx.setLineWidth(2.0)
        ctx.stroke(viewRect)
    }

    private func drawDraft(_ draft: DraftShape, pageSize: CGSize) {
        guard let ctx = NSGraphicsContext.current?.cgContext,
              let mc = viewModel?.markupColor else { return }
        let nsColor = NSColor(srgbRed: CGFloat(mc.rgb.r) / 255,
                              green: CGFloat(mc.rgb.g) / 255,
                              blue: CGFloat(mc.rgb.b) / 255,
                              alpha: 1.0)
        ctx.setStrokeColor(nsColor.cgColor)
        ctx.setLineWidth(1.5)

        let pts = draft.points.map { CGPoint(x: $0.x, y: pageSize.height - $0.y) }
        guard pts.count >= 2 else { return }

        let r = CGRect(x: min(pts[0].x, pts[1].x), y: min(pts[0].y, pts[1].y),
                       width: abs(pts[0].x - pts[1].x), height: abs(pts[0].y - pts[1].y))
        switch draft.type {
        case .square:
            ctx.setFillColor(nsColor.withAlphaComponent(0.15).cgColor)
            ctx.fill(r)
            ctx.stroke(r)
        case .circle:
            ctx.setFillColor(nsColor.withAlphaComponent(0.15).cgColor)
            ctx.fillEllipse(in: r)
            ctx.strokeEllipse(in: r)
        default:
            ctx.move(to: pts[0])
            for p in pts.dropFirst() { ctx.addLine(to: p) }
            if draft.type == .polygon { ctx.closePath() }
            ctx.strokePath()
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

    // MARK: 坐标换算（1x，用户坐标 Y-up ↔ 视图坐标 Y-down）

    private func userToView(_ box: CGRect, pageSize: CGSize) -> CGRect {
        CGRect(x: box.minX, y: pageSize.height - box.maxY, width: box.width, height: box.height)
    }

    private func viewToUser(_ p: CGPoint, pageSize: CGSize) -> CGPoint {
        CGPoint(x: p.x, y: pageSize.height - p.y)
    }

    // MARK: 鼠标路由

    override func mouseDown(with event: NSEvent) { route(.down, event) }
    override func mouseDragged(with event: NSEvent) { route(.drag, event) }
    override func mouseUp(with event: NSEvent) { route(.up, event) }

    private func route(_ phase: ToolPhase, _ event: NSEvent) {
        guard let vm = viewModel else { return }
        let p = convert(event.locationInWindow, from: nil)
        let user = viewToUser(p, pageSize: pageSize)
        vm.route(phase, pageIndex: pageIndex, userPoint: user, modifiers: event.modifierFlags, clickCount: event.clickCount)
    }
}
