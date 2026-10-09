//  PDFEditorViewModel.swift
//  单一状态源（ObservableObject），同时实现 ToolContext 供工具调用 SDK。

import Foundation
import AppKit
import Combine

enum DisplayMode: String, CaseIterable, Identifiable {
    case single = "单页"
    case singleContinuous = "单页连续"
    case double = "双页"
    case doubleContinuous = "双页连续"
    var id: String { rawValue }

    var isDouble: Bool { self == .double || self == .doubleContinuous }
}

final class PDFEditorViewModel: ObservableObject, ToolContext {

    // MARK: - 文档状态
    @Published var document: ArkoDocument?
    @Published var currentPage: Int = 0
    @Published var pageCount: Int = 0
    @Published var zoom: Double = 1.0
    @Published var displayMode: DisplayMode = .singleContinuous
    @Published var selection: TextSelection?
    @Published var lastError: String?

    // MARK: - 标注状态
    @Published var markupColor: MarkupColor = .yellow
    @Published var markupOpacity: Float = 0.8

    // MARK: - 模块 / 工具
    let modules: [ModuleKind: EditorModule]
    @Published var activeModuleKind: ModuleKind = .reading
    @Published var activeToolID: String = ""

    /// 渲染版本号：标注落地后自增，触发画布重绘。
    @Published var renderRevision: Int = 0

    /// 视口宽度（用于「适合宽度」缩放）。
    @Published var viewportWidth: CGFloat = 800

    // MARK: - 渲染缓存
    private let cache = NSCache<NSString, CGImage>()

    init() {
        var map: [ModuleKind: EditorModule] = [:]
        let reading = ReadingModule()
        let annotate = AnnotateModule()
        let edit = EditModule()
        let pages = PagesModule()
        let protect = ProtectModule()
        let convert = ConvertModule()
        let tools = ToolsModule()
        for m in [reading, annotate, edit, pages, protect, convert, tools] as [EditorModule] {
            map[m.kind] = m
        }
        modules = map
        activeModuleKind = .reading
        activeToolID = reading.activeTool?.id ?? ""
    }

    var activeModule: EditorModule? { modules[activeModuleKind] }
    var activeTool: EditorTool? { activeModule?.activeTool }

    // MARK: - ToolContext

    var currentPageIndex: Int { currentPage }

    func page(at index: Int) -> ArkoPage? {
        document?.page(at: index)
    }

    func setSelection(_ selection: TextSelection?) {
        self.selection = selection
    }

    func applyMarkup(_ handler: AnnotHandler, lineBoxes: [CGRect], pageIndex: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        handler.apply(lineBoxes: lineBoxes, on: page, color: markupColor.sdkColor, opacity: markupOpacity)
        invalidateAllPages()
    }

    // MARK: - 事件路由

    func route(_ phase: ToolPhase, pageIndex: Int, userPoint: CGPoint, modifiers: NSEvent.ModifierFlags) {
        let event = ToolMouseEvent(pageIndex: pageIndex, point: userPoint, modifiers: modifiers)
        activeModule?.route(phase, event, context: self)
    }

    // MARK: - 模块 / 工具切换

    func selectModule(_ kind: ModuleKind) {
        activeModuleKind = kind
        activeToolID = modules[kind]?.activeTool?.id ?? ""
        selection = nil
    }

    func selectTool(_ tool: EditorTool) {
        activeModule?.activeTool = tool
        activeToolID = tool.id
        selection = nil
        tool.activated(context: self)
    }

    // MARK: - 页面组织（PPO）

    func insertBlankPage(after index: Int) {
        guard let doc = document else { return }
        let size = pageSizeInPoints(at: index)
        let w = size.width > 0 ? size.width : 612
        let h = size.height > 0 ? size.height : 792
        doc.insertBlankPage(at: index + 1, width: w, height: h)
        // pageCount/缓存已在 didChangePages 回调里刷新；这里跟随插入的新页
        currentPage = min(index + 1, max(0, pageCount - 1))
    }

    func deletePage(at index: Int) {
        guard let doc = document, pageCount > 1 else { return } // 至少保留一页
        doc.deletePages(from: index, count: 1)
        currentPage = min(currentPage, max(0, pageCount - 1))
    }

    func rotatePageClockwise90(at index: Int) {
        guard let doc = document else { return }
        doc.rotatePageClockwise90(index)
    }

    /// 上移/下移一页（offset 为 -1 或 +1，内部用 SwapPages 实现）。
    func movePage(at index: Int, by offset: Int) {
        guard let doc = document else { return }
        let target = index + offset
        guard target >= 0, target < pageCount else { return }
        doc.swapPage(index, with: target)
        currentPage = target
    }

    // MARK: - 文档操作

    func open(url: URL) {
        close()
        do {
            document = try ArkoDocument(url: url)
            if let doc = document {
                doc.ppoDelegate = self
                pageCount = doc.pageCount
                currentPage = 0
                zoom = 1.0
                cache.removeAllObjects()
            }
        } catch {
            document = nil
            pageCount = 0
            lastError = error.localizedDescription
        }
    }

    func save(to url: URL) {
        guard let doc = document else { return }
        do {
            _ = try doc.save(to: url)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func close() {
        document?.close()
        document = nil
        pageCount = 0
        currentPage = 0
        selection = nil
        cache.removeAllObjects()
    }

    // MARK: - 导航 / 缩放

    func goToPreviousPage() {
        currentPage = targetPage(forDelta: -1)
    }

    func goToNextPage() {
        currentPage = targetPage(forDelta: 1)
    }

    /// 计算翻页后的目标页；双页模式按「跨页(spread)」步进。
    private func targetPage(forDelta delta: Int) -> Int {
        guard pageCount > 0 else { return 0 }
        if displayMode.isDouble {
            let spreadIdx = spreadIndex(forPage: currentPage)
            return clamp(firstPage(ofSpread: spreadIdx + delta))
        } else {
            return clamp(currentPage + delta)
        }
    }

    private func clamp(_ p: Int) -> Int {
        max(0, min(p, pageCount - 1))
    }

    // MARK: 双页跨页(spread)辅助

    /// 当前页所在跨页的下标：0 是封面单独跨页，1 是第 2/3 页，2 是第 4/5 页…
    func spreadIndex(forPage p: Int) -> Int {
        p == 0 ? 0 : (p + 1) / 2
    }

    /// 跨页下标对应的第一页（封面为 0，其余为 1,3,5…）
    func firstPage(ofSpread s: Int) -> Int {
        s <= 0 ? 0 : 2 * s - 1
    }

    /// 跨页数量（封面单独算 1，其余两两一组）
    var spreadCount: Int {
        pageCount == 0 ? 0 : 1 + pageCount / 2
    }

    /// 给定跨页下标，返回 (左页, 右页)。封面跨页左页为 nil。
    func spread(forIndex s: Int) -> (left: Int?, right: Int?) {
        guard s >= 0, s < spreadCount else { return (nil, nil) }
        if s == 0 {
            return (nil, 0)
        }
        let left = 2 * s - 1
        let right = left + 1
        return (left, right < pageCount ? right : nil)
    }

    func zoomIn() { zoom = min(zoom * 1.25, 4.0) }
    func zoomOut() { zoom = max(zoom / 1.25, 0.25) }

    func fitWidth(viewportWidth: CGFloat? = nil) {
        let w = viewportWidth ?? self.viewportWidth
        guard let page = document?.page(at: currentPage), page.widthInPoints > 0 else { return }
        zoom = min(max(Double(w) / Double(page.widthInPoints), 0.1), 8.0)
    }

    func setViewportWidth(_ width: CGFloat) {
        viewportWidth = width
    }

    // MARK: - 渲染

    func pageSizeInPoints(at index: Int) -> CGSize {
        guard let p = document?.page(at: index) else { return .zero }
        return CGSize(width: p.widthInPoints, height: p.heightInPoints)
    }

    /// 渲染一页并缓存（同步；后续可改后台队列 + IPDF_ProgressiveRenderer）。
    func image(forPage index: Int, zoom: Double) -> CGImage? {
        let screenScale = NSScreen.main?.backingScaleFactor ?? 2.0
        let renderScale = zoom * Double(screenScale)
        let key = "\(index)@\(zoom)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let page = document?.page(at: index),
              let cg = page.renderImage(atScale: CGFloat(renderScale)) else {
            return nil
        }
        cache.setObject(cg, forKey: key)
        return cg
    }

    private func invalidateAllPages() {
        cache.removeAllObjects()
        renderRevision += 1
    }
}

// MARK: - PPO 操作通知（OnBefore / OnAfter）

extension PDFEditorViewModel: ArkoDocumentPPODelegate {
    /// 操作前：清空选区、重置工具拖拽状态，避免引用将被释放/重排的页。
    func document(_ document: ArkoDocument, willChangePages operation: ArkoPPOOperation, pages: [NSNumber]) {
        selection = nil
        activeTool?.reset()
    }

    /// 操作后：刷新页数、失效渲染缓存（缩略图/文档视图通过 @Published 自动刷新）。
    func document(_ document: ArkoDocument, didChangePages operation: ArkoPPOOperation) {
        pageCount = document.pageCount
        invalidateAllPages()
    }
}
