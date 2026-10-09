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

/// 标注面板里的一项（定位到某页的第几个标注）。
struct AnnotationItem: Identifiable {
    let pageIndex: Int
    let annotIndex: Int
    let type: MarkupType
    let color: MarkupColor
    let opacity: Float
    let rect: CGRect

    var id: String { "\(pageIndex)-\(annotIndex)" }
    var pageLabel: String { "第 \(pageIndex + 1) 页" }
}

final class PDFEditorViewModel: NSObject, ObservableObject, ToolContext {

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

    /// 标注变更事件广播（创建/修改/删除），供各模块/工具/面板/视图订阅。
    let annotEvents = PassthroughSubject<AnnotEvent, Never>()

    /// 当前文档所有标注（标注面板数据源）。
    @Published var annotations: [AnnotationItem] = []

    /// 当前「定位」的标注（标注面板点击后跳转并高亮描边）。
    @Published var focusedAnnotationID: String?

    /// 撤销/重做栈。
    let undoManager = ArkoUndoManager()

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

    override init() {
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
        super.init()
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
        let annotIndex = page.annotCount - 1  // AddAnnot 追加到末尾
        let annotHandler = page.annotHandler(at: annotIndex)  // 记录句柄

        // 撤销/重做：按句柄删除/重插入
        undoManager.register(UndoItem(
            description: "添加\(handler.displayName)",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.removeAnnot(byHandler: annotHandler) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addAnnot(byHandler: annotHandler, at: annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .added, pageIndex: pageIndex, annotType: handler.type))
        refreshAnnotations()
        invalidateAllPages()
    }

    /// 重建标注面板数据源（遍历所有页的标注）。
    func refreshAnnotations() {
        guard let doc = document else { annotations = []; return }
        var items: [AnnotationItem] = []
        for p in 0..<doc.pageCount {
            guard let page = doc.page(at: p) else { continue }
            for a in 0..<page.annotCount {
                guard let info = page.annotInfo(at: a),
                      let typeNum = info["type"] as? NSNumber,
                      let colorNum = info["color"] as? NSNumber,
                      let opacityNum = info["opacity"] as? NSNumber,
                      let rectValue = info["rect"] as? NSValue,
                      let type = MarkupType(rawValue: typeNum.intValue) else { continue }
                let color = MarkupColor.from(sdkColor: colorNum.uint32Value)
                items.append(AnnotationItem(pageIndex: p, annotIndex: a, type: type,
                                            color: color, opacity: opacityNum.floatValue,
                                            rect: rectValue.rectValue))
            }
        }
        annotations = items
    }

    /// 删除某条标注。
    func deleteAnnotation(_ item: AnnotationItem) {
        guard let page = document?.page(at: item.pageIndex) else { return }
        let annotIndex = item.annotIndex
        let annotHandler = page.annotHandler(at: annotIndex)  // 记录被删标注的句柄 + index
        let type = item.type
        page.removeAnnot(at: annotIndex)

        undoManager.register(UndoItem(
            description: "删除\(type.displayName)",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.addAnnot(byHandler: annotHandler, at: annotIndex) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.removeAnnot(byHandler: annotHandler) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .removed, pageIndex: item.pageIndex, annotType: type))
        refreshAnnotations()
        invalidateAllPages()
    }

    /// 修改某条标注的颜色。
    func changeAnnotationColor(_ item: AnnotationItem, to color: MarkupColor) {
        guard let page = document?.page(at: item.pageIndex) else { return }
        let oldColor = item.color
        page.setAnnotColor(color.sdkColor, at: item.annotIndex)

        undoManager.register(UndoItem(
            description: "修改\(item.type.displayName)颜色",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.setAnnotColor(oldColor.sdkColor, at: item.annotIndex) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.setAnnotColor(color.sdkColor, at: item.annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .modified, pageIndex: item.pageIndex, annotType: item.type))
        refreshAnnotations()
        invalidateAllPages()
    }

    /// 修改某条标注的透明度。
    func changeAnnotationOpacity(_ item: AnnotationItem, to opacity: Float) {
        guard let page = document?.page(at: item.pageIndex) else { return }
        let oldOpacity = item.opacity
        page.setAnnotOpacity(opacity, at: item.annotIndex)

        undoManager.register(UndoItem(
            description: "修改\(item.type.displayName)透明度",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.setAnnotOpacity(oldOpacity, at: item.annotIndex) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: item.pageIndex)?.setAnnotOpacity(opacity, at: item.annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .modified, pageIndex: item.pageIndex, annotType: item.type))
        refreshAnnotations()
        invalidateAllPages()
    }

    /// 定位到某条标注（跳页 + 高亮描边）。
    func focusAnnotation(_ item: AnnotationItem) {
        currentPage = item.pageIndex
        focusedAnnotationID = item.id
    }

    /// 供撤销/重做闭包调用：执行原始操作并刷新，不注册新撤销项。
    func performUndoRedo(_ op: () -> Void) {
        op()
        pageCount = document?.pageCount ?? 0
        currentPage = min(currentPage, max(0, pageCount - 1))
        refreshAnnotations()
        invalidateAllPages()
    }

    func undo() {
        undoManager.undo(context: self)
        focusedAnnotationID = nil
    }

    func redo() {
        undoManager.redo(context: self)
        focusedAnnotationID = nil
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
        let insertAt = index + 1
        doc.insertBlankPage(at: insertAt, width: w, height: h)

        undoManager.register(UndoItem(
            description: "插入空白页",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.deletePages(from: insertAt, count: 1) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.insertBlankPage(at: insertAt, width: w, height: h) }
            }
        ))

        currentPage = min(insertAt, max(0, pageCount - 1))
    }

    func deletePage(at index: Int) {
        guard let doc = document, pageCount > 1 else { return } // 至少保留一页
        // 删除前克隆页面句柄（页面数据仍在 PDF 里，删除只是断开引用）
        let clones = doc.clonePageHandlers(from: index, count: 1)
        doc.deletePages(from: index, count: 1)

        if let clones = clones {
            undoManager.register(UndoItem(
                description: "删除页面",
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.restorePages(withClones: clones, at: index) }
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.deletePages(from: index, count: 1) }
                }
            ))
        }

        currentPage = min(currentPage, max(0, pageCount - 1))
    }

    func rotatePageClockwise90(at index: Int) {
        guard let doc = document else { return }
        let old = doc.pageRotation(at: index)
        let new = (old + 1) % 4
        doc.setPageRotation(new, at: index)

        undoManager.register(UndoItem(
            description: "旋转页面",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.setPageRotation(old, at: index) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.setPageRotation(new, at: index) }
            }
        ))
    }

    /// 上移/下移一页（offset 为 -1 或 +1，内部用 SwapPages 实现）。
    func movePage(at index: Int, by offset: Int) {
        guard let doc = document else { return }
        let target = index + offset
        guard target >= 0, target < pageCount else { return }
        doc.swapPage(index, with: target)

        // Swap 是自反的：撤销/重做都再交换一次。
        undoManager.register(UndoItem(
            description: "移动页面",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.swapPage(index, with: target) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.swapPage(index, with: target) }
            }
        ))

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
                refreshAnnotations()
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
        annotations = []
        focusedAnnotationID = nil
        undoManager.reset()
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
        refreshAnnotations()  // 页索引已重排，重建标注列表
        invalidateAllPages()
    }
}
