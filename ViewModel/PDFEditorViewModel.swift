//  PDFEditorViewModel.swift
//  单一状态源（ObservableObject），同时实现 ToolContext 供工具调用 SDK。

import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

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
    let type: Int          // ANNOT_TYPE 原始值
    let color: MarkupColor
    let opacity: Float
    let rect: CGRect

    var typeName: String { AnnotKind.name(forType: type) }
    var typeIcon: String { AnnotKind.icon(forType: type) }

    var id: String { "\(pageIndex)-\(annotIndex)" }
    var pageLabel: String { "第 \(pageIndex + 1) 页" }
}

/// 大纲（书签树）里的一项。
struct OutlineItem: Identifiable {
    let title: String
    let level: Int
    let page: Int
    let path: [Int]

    var id: String { path.map(String.init).joined(separator: "-") }
}

final class PDFEditorViewModel: NSObject, ObservableObject, ToolContext, EditContext {

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

    /// 当前文档大纲（书签树，扁平列表）。
    @Published var outline: [OutlineItem] = []

    /// 图形标注拖拽草稿（画布预览用）。
    @Published var draft: DraftShape?

    // MARK: - 编辑状态（段落 / 图片 / 链接）
    /// 当前段落编辑选区（画布高亮 + 格式栏状态）。
    @Published var paragraphSelection: ParagraphSelection?
    /// 当前图片对象选区（画布高亮 + 图片编辑栏）。
    @Published var imageSelection: ImageSelection?
    /// 链接拖拽草稿矩形（画布预览）。
    @Published var linkDraft: LinkDraft?
    /// 待用户填写链接目标的拖拽结果（触发链接设置弹窗）。
    @Published var pendingLink: LinkDraft?

    /// 页面组织高级操作弹窗（提取/插入/替换）。
    @Published var pageSheet: PageSheetKind?

    /// 相册排版弹窗。
    @Published var isPhotoBookPresented = false

    /// 密码/安全弹窗状态。
    @Published var passwordMenuPresented = false
    @Published var passwordTab: PasswordTab?
    @Published var showDocProperties = false
    /// 待保存的安全设置（内存暂存，保存文档后生效；nil = 不改变安全）。
    @Published var pendingSecurity: ArkoSecurityOptions?
    /// 移除密码：确认对话框 / 完成对话框。
    @Published var removePasswordConfirmPresented = false
    @Published var removePasswordDonePresented = false

    /// 保存进度状态（SaveProgressOverlay 用）。
    @Published var isSaving = false
    @Published var saveProgress: Double = 0
    @Published var saveTitle: String = "保存…"
    private let saveCancelFlag = SaveCancelFlag()

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

    // 段落编辑的内部状态：当前正在编辑的段落对象 + 页码（不发布，仅编辑操作使用）。
    // 注意：编辑方法在 PDFEditorViewModel+Edit.swift（扩展），故此处需 internal 可见。
    var editingParagraph: ArkoParagraph?
    var editingPage: Int?

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

        annotEvents.send(AnnotEvent(kind: .added, pageIndex: pageIndex, annotType: handler.type.rawValue))
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
                      let rectValue = info["rect"] as? NSValue else { continue }
                let color = MarkupColor.from(sdkColor: colorNum.uint32Value)
                items.append(AnnotationItem(pageIndex: p, annotIndex: a, type: typeNum.intValue,
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
            description: "删除\(item.typeName)",
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
            description: "修改\(item.typeName)颜色",
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
            description: "修改\(item.typeName)透明度",
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

    // MARK: - 图形 / 便签标注

    func setDraft(_ draft: DraftShape?) {
        self.draft = draft
    }

    func addShapeAnnot(_ type: ShapeType, points: [CGPoint], pageIndex: Int) {
        guard let page = document?.page(at: pageIndex), points.count >= 2 else { return }
        page.addShapeAnnot(ofType: type.rawValue,
                           points: points.map { NSValue(point: $0) },
                           color: markupColor.sdkColor,
                           opacity: markupOpacity,
                           borderWidth: 2)
        let annotIndex = page.annotCount - 1
        let annotHandler = page.annotHandler(at: annotIndex)

        undoManager.register(UndoItem(
            description: "添加\(type.displayName)",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.removeAnnot(byHandler: annotHandler) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addAnnot(byHandler: annotHandler, at: annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .added, pageIndex: pageIndex, annotType: type.rawValue))
        refreshAnnotations()
        invalidateAllPages()
    }

    func addNoteAnnot(at point: CGPoint, pageIndex: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        let rect = CGRect(x: point.x, y: point.y - 20, width: 22, height: 22)
        page.addNoteAnnot(at: rect, contents: "备注", color: markupColor.sdkColor, opacity: markupOpacity)
        let annotIndex = page.annotCount - 1
        let annotHandler = page.annotHandler(at: annotIndex)

        undoManager.register(UndoItem(
            description: "添加便签",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.removeAnnot(byHandler: annotHandler) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addAnnot(byHandler: annotHandler, at: annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .added, pageIndex: pageIndex, annotType: 1))  // ANNOT_TYPE_TEXT
        refreshAnnotations()
        invalidateAllPages()
    }

    // MARK: - 大纲（书签树）

    /// 重建大纲数据源。
    func refreshOutline() {
        guard let doc = document else { outline = []; return }
        var items: [OutlineItem] = []
        for info in doc.outlineItems() {
            guard let title = info["title"] as? String,
                  let levelNum = info["level"] as? NSNumber,
                  let pageNum = info["page"] as? NSNumber,
                  let pathArr = info["path"] as? [NSNumber] else { continue }
            items.append(OutlineItem(title: title,
                                    level: levelNum.intValue,
                                    page: pageNum.intValue,
                                    path: pathArr.map { $0.intValue }))
        }
        outline = items
    }

    /// 在某大纲项下添加子项（parent 为 nil 表示加到根）。
    func addOutlineItem(title: String, under parent: OutlineItem?) {
        guard let doc = document else { return }
        doc.addBookmark(title, underPath: parent?.path.map { NSNumber(value: $0) })
        refreshOutline()
    }

    func renameOutlineItem(_ item: OutlineItem, title: String) {
        guard let doc = document else { return }
        doc.renameBookmark(atPath: item.path.map { NSNumber(value: $0) }, title: title)
        refreshOutline()
    }

    func removeOutlineItem(_ item: OutlineItem) {
        guard let doc = document else { return }
        doc.removeBookmark(atPath: item.path.map { NSNumber(value: $0) })
        refreshOutline()
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

    func route(_ phase: ToolPhase, pageIndex: Int, userPoint: CGPoint, modifiers: NSEvent.ModifierFlags, clickCount: Int) {
        let event = ToolMouseEvent(pageIndex: pageIndex, point: userPoint, modifiers: modifiers, clickCount: clickCount)
        activeModule?.route(phase, event, context: self)
    }

    // MARK: - 模块 / 工具切换

    func selectModule(_ kind: ModuleKind) {
        activeModuleKind = kind
        activeToolID = modules[kind]?.activeTool?.id ?? ""
        selection = nil
        clearParagraphEdit()
        imageSelection = nil
        linkDraft = nil
        pendingLink = nil
    }

    func selectTool(_ tool: EditorTool) {
        activeModule?.activeTool = tool
        activeToolID = tool.id
        selection = nil
        clearParagraphEdit()
        imageSelection = nil
        linkDraft = nil
        pendingLink = nil
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
                },
                dispose: {
                    ArkoDocument.destroyPageHandlerClones(clones)
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

    // MARK: - PPO 高级（提取 / 插入 / 替换页面）

    func showPageSheet(_ kind: PageSheetKind) {
        pageSheet = kind
    }

    func showPhotoBook() {
        isPhotoBookPresented = true
    }

    // MARK: - 密码 / 安全

    func showPasswordMenu() {
        passwordMenuPresented = true
    }

    /// 设置安全（内存暂存，保存文档后生效）：打开密码（userPassword）或权限密码（ownerPassword）。
    func applySecurity(ownerPassword: String?, userPassword: String?,
                       encryption: EncryptionAlgorithm, encryptMetadata: Bool,
                       printPerm: PrintPermission?, changePerm: ChangePermission?,
                       allowCopy: Bool?, allowAccessibility: Bool?) {
        let perms: UInt32
        if let p = printPerm, let c = changePerm, let copy = allowCopy, let access = allowAccessibility {
            perms = combinedPermissions(printPerm: p, changePerm: c, allowCopy: copy, allowAccessibility: access)
        } else {
            // 仅设打开密码（无权限密码）时保留全部权限
            perms = UserPerm.allPermissions
        }
        let opts = ArkoSecurityOptions()
        opts.permissions = perms
        opts.ownerPassword = ownerPassword
        opts.userPassword = userPassword
        opts.cipher = encryption.cipher
        opts.keylen = encryption.keylen
        opts.encryptMetadata = encryptMetadata
        opts.removeSecurity = false
        pendingSecurity = opts
    }

    /// 点击「移除密码」：先弹出确认对话框（确认后才真正移除）。
    func removeSecurity() {
        removePasswordConfirmPresented = true
    }

    func cancelRemovePassword() {
        removePasswordConfirmPresented = false
    }

    /// 用户确认移除：内存暂存 removeSecurity 标记，弹出完成对话框。
    func confirmRemoveSecurity() {
        removePasswordConfirmPresented = false
        let opts = ArkoSecurityOptions()
        opts.removeSecurity = true
        pendingSecurity = opts
        removePasswordDonePresented = true
    }

    func dismissRemovePasswordDone() {
        removePasswordDonePresented = false
    }

    /// 完成对话框「保存」：关对话框后走保存流程。
    func saveAfterRemovePassword() {
        removePasswordDonePresented = false
        saveDocument()
    }

    /// 弹出保存面板并保存（菜单「保存」与「移除密码完成」的「保存」按钮共用）。
    func saveDocument() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            save(to: url)
        }
    }

    /// 提取页面到新 PDF（不改当前文档，无撤销）。
    func extractPages(_ range: PageRange, to url: URL) {
        let pages = range.resolve(pageCount: pageCount)
        guard !pages.isEmpty else { return }
        do {
            _ = try document?.extractPages(pages.map { NSNumber(value: $0) }, to: url)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// 从源 PDF 插入页面（改变当前文档，含撤销）。
    func insertPages(from sourceURL: URL, pages: [Int], at index: Int) {
        guard let doc = document, !pages.isEmpty else { return }
        let insertAt = index
        let count = pages.count
        doc.insertPages(from: sourceURL, pages: pages.map { NSNumber(value: $0) }, at: insertAt)

        // 撤销：删除插入的页；重做：用克隆句柄恢复插入的页
        let clones = doc.clonePageHandlers(from: insertAt, count: count)
        if let clones = clones {
            undoManager.register(UndoItem(
                description: "插入页面",
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.deletePages(from: insertAt, count: count) }
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.restorePages(withClones: clones, at: insertAt) }
                },
                dispose: { ArkoDocument.destroyPageHandlerClones(clones) }
            ))
        }
        currentPage = min(insertAt, max(0, pageCount - 1))
    }

    /// 替换页面（改变当前文档，含撤销）。
    func replacePages(from sourceURL: URL, pages: [Int], at start: Int, count: Int) {
        guard let doc = document, !pages.isEmpty else { return }
        let clones = doc.clonePageHandlers(from: start, count: count)
        doc.replacePages(from: sourceURL, pages: pages.map { NSNumber(value: $0) }, at: start, count: count)

        if let clones = clones {
            undoManager.register(UndoItem(
                description: "替换页面",
                undo: { ctx in
                    ctx.performUndoRedo {
                        ctx.document?.deletePages(from: start, count: count)
                        ctx.document?.restorePages(withClones: clones, at: start)
                    }
                },
                redo: { ctx in
                    ctx.performUndoRedo {
                        ctx.document?.replacePages(from: sourceURL, pages: pages.map { NSNumber(value: $0) }, at: start, count: count)
                    }
                },
                dispose: { ArkoDocument.destroyPageHandlerClones(clones) }
            ))
        }
        currentPage = min(start, max(0, pageCount - 1))
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
                refreshOutline()
            }
        } catch {
            document = nil
            pageCount = 0
            lastError = error.localizedDescription
        }
    }

    func save(to url: URL) {
        guard let doc = document else { return }
        let security = pendingSecurity  // 快照：本次保存应用的安全设置
        isSaving = true
        saveProgress = 0
        saveTitle = "保存…"
        saveCancelFlag.isCancelled = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                _ = try doc.save(to: url, progress: { p in
                    DispatchQueue.main.async { self.saveProgress = Double(p) }
                }, isCancelled: { [weak self] in
                    self?.saveCancelFlag.isCancelled ?? false
                }, security: security)
                DispatchQueue.main.async { self.isSaving = false }
            } catch {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func cancelSave() {
        saveCancelFlag.isCancelled = true
    }

    func close() {
        document?.close()
        document = nil
        pageCount = 0
        currentPage = 0
        selection = nil
        annotations = []
        outline = []
        focusedAnnotationID = nil
        clearParagraphEdit()
        imageSelection = nil
        linkDraft = nil
        pendingLink = nil
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

    /// 按倍率缩放（⌘+滚轮 / 捏合用），并夹紧到 [0.25, 4]。
    func zoomBy(_ factor: Double) {
        zoom = min(max(zoom * factor, 0.25), 4.0)
    }

    /// 实际大小（100%）。
    func actualSize() { zoom = 1.0 }

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

    func invalidateAllPages() {
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
