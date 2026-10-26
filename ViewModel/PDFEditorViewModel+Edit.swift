//  PDFEditorViewModel+Edit.swift
//  编辑模块的实现：段落编辑 / 添加文字 / 添加图片 / 图片编辑 / 链接。
//  段落撤销用 SDK 原生 IPDF_ParaUndoItem；图片撤销用 Clone/Copy；链接撤销用标注句柄。

import AppKit
import UniformTypeIdentifiers

extension PDFEditorViewModel {

    // MARK: - 段落 / 文字

    func beginParagraphEdit(pageIndex: Int, point: CGPoint) -> ParagraphSelection? {
        guard let page = document?.page(at: pageIndex),
              let para = page.paragraph(atPointX: point.x, y: point.y) else {
            clearParagraphEdit()
            return nil
        }
        editingParagraph = para
        editingPage = pageIndex
        imageSelection = nil
        var caret = para.caret(atPointX: point.x, y: point.y)
        if caret < 0 { caret = 0 }
        return refreshParagraphSelection(caret: caret, endCaret: caret)
    }

    func createParagraph(pageIndex: Int, point: CGPoint) -> ParagraphSelection? {
        guard let page = document?.page(at: pageIndex) else { return nil }
        let width: CGFloat = 200
        let height: CGFloat = 14
        guard let para = page.newParagraph(atX: point.x, y: point.y, width: width, height: height) else {
            return nil
        }
        editingParagraph = para
        editingPage = pageIndex
        imageSelection = nil

        let paraIndex = page.paragraphCount - 1
        undoManager.register(UndoItem(
            description: "添加文字段落",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.deleteParagraph(at: paraIndex) }
                ctx.clearParagraphEdit()
            },
            redo: { ctx in
                ctx.performUndoRedo {
                    _ = ctx.document?.page(at: pageIndex)?.newParagraph(atX: point.x, y: point.y, width: width, height: height)
                }
                ctx.clearParagraphEdit()
            }
        ))

        return refreshParagraphSelection(caret: 0, endCaret: 0)
    }

    func updateParagraphCaret(pageIndex: Int, point: CGPoint) {
        guard editingPage == pageIndex, let para = editingParagraph, var sel = paragraphSelection else { return }
        let caret = para.caret(atPointX: point.x, y: point.y)
        guard caret >= 0 else { return }
        sel.endCaret = caret
        let s = min(sel.startCaret, caret)
        let e = max(sel.startCaret, caret)
        sel.boxes = para.selBoxes(fromCaret: s, toCaret: e).map { $0.rectValue }
        paragraphSelection = sel
    }

    func insertText(_ text: String, pageIndex: Int) {
        guard !text.isEmpty,
              let para = editingParagraph, editingPage == pageIndex,
              let sel = paragraphSelection else { return }

        var caret = sel.startCaret
        // 有选区先替换（删除选区再插入）
        if sel.startCaret != sel.endCaret {
            let delHandle = para.deleteText(fromCaret: sel.startCaret, toCaret: sel.endCaret)
            if delHandle != 0 {
                registerParaUndo(delHandle, pageIndex: pageIndex, description: "删除文字")
            }
            caret = para.currentCaret
        }

        // 按插入字符选择字体：caret 处字体若支持该字符则复用，否则用完整默认字体（参考 Windows GetFont）
        let font = para.fontHandle(forInsertingText: text, atCaret: caret,
                                   defaultFont: document?.defaultFontHandle ?? 0)
        let handle = para.insertText(text, atCaret: caret, fontHandle: font,
                                     fontSize: sel.fontSize, color: sel.textColor,
                                     bold: sel.isBold, italic: sel.isItalic,
                                     underline: sel.isUnderline, strikeout: sel.isStrikeout)
        if handle != 0 {
            registerParaUndo(handle, pageIndex: pageIndex, description: "插入文字")
            let c = para.currentCaret
            _ = refreshParagraphSelection(caret: c, endCaret: c)
        }
        invalidateAllPages()
    }

    func deleteSelectionText(pageIndex: Int) {
        guard let para = editingParagraph, editingPage == pageIndex,
              let sel = paragraphSelection else { return }
        var handle: UInt64 = 0
        var desc = "删除文字"
        if sel.startCaret != sel.endCaret {
            handle = para.deleteText(fromCaret: sel.startCaret, toCaret: sel.endCaret)
            desc = "删除文字"
        } else {
            handle = para.backspace(atCaret: sel.startCaret)
            desc = "退格"
        }
        if handle != 0 {
            registerParaUndo(handle, pageIndex: pageIndex, description: desc)
            let c = para.currentCaret
            _ = refreshParagraphSelection(caret: c, endCaret: c)
        }
        invalidateAllPages()
    }

    func applyParagraphStyle(_ style: ParagraphStyle, pageIndex: Int) {
        guard let para = editingParagraph, editingPage == pageIndex,
              let sel = paragraphSelection else { return }
        let s = sel.startCaret
        let e = sel.endCaret
        var handle: UInt64 = 0
        var desc = ""
        switch style {
        case .toggleBold:      handle = para.setBold(fromCaret: s, toCaret: e);       desc = "加粗"
        case .toggleItalic:    handle = para.setItalic(fromCaret: s, toCaret: e);     desc = "斜体"
        case .toggleUnderline: handle = para.setUnderline(fromCaret: s, toCaret: e);  desc = "下划线"
        case .toggleStrikeout: handle = para.setStrikeout(fromCaret: s, toCaret: e);  desc = "删除线"
        case .fontSize(let size): handle = para.setFontSize(size, fromCaret: s, toCaret: e); desc = "字号"
        case .textColor(let argb): handle = para.setTextColor(argb, fromCaret: s, toCaret: e); desc = "颜色"
        }
        if handle != 0 {
            registerParaUndo(handle, pageIndex: pageIndex, description: desc)
            let c = para.currentCaret
            _ = refreshParagraphSelection(caret: c, endCaret: c)
        }
        invalidateAllPages()
    }

    func deleteWholeParagraph(pageIndex: Int) {
        guard let page = document?.page(at: pageIndex),
              let para = editingParagraph, editingPage == pageIndex else { return }
        // 删除段落：SDK 原生 DeleteParagraph 撤销项（Undo 还原、Redo 再删）
        let handle = ArkoParagraph.createUndoItem(ofType: ArkoParaUndoType.deleteParagraph.rawValue)
        page.deleteParagraph(byHandle: para.paragraphHandle, undoItem: handle)
        if handle != 0 {
            undoManager.register(UndoItem(
                description: "删除段落",
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.paraUndoItem(handle) }
                    ctx.clearParagraphEdit()
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.paraRedoItem(handle) }
                    ctx.clearParagraphEdit()
                },
                dispose: { ArkoParagraph.releaseUndoItem(handle) }
            ))
        }
        clearParagraphEdit()
        invalidateAllPages()
    }

    // MARK: - 图片

    func beginImageEdit(pageIndex: Int, point: CGPoint) -> ImageSelection? {
        guard let page = document?.page(at: pageIndex) else {
            imageSelection = nil
            return nil
        }
        let idx = page.pageObjectIndex(atPointX: point.x, y: point.y)
        guard idx >= 0,
              let info = page.pageObjectInfo(at: idx),
              (info["image"] as? NSNumber)?.boolValue == true,
              let bbox = (info["bbox"] as? NSValue)?.rectValue else {
            imageSelection = nil
            return nil
        }
        let sel = ImageSelection(pageIndex: pageIndex, objectIndex: idx, bbox: bbox)
        imageSelection = sel
        paragraphSelection = nil
        editingParagraph = nil
        editingPage = nil
        return sel
    }

    func updateImageDrag(pageIndex: Int, bbox: CGRect) {
        guard var sel = imageSelection, sel.pageIndex == pageIndex else { return }
        sel.bbox = bbox
        imageSelection = sel
    }

    func commitImageChange(pageIndex: Int, oldBBox: CGRect, newBBox: CGRect) {
        guard let page = document?.page(at: pageIndex),
              let sel = imageSelection, sel.pageIndex == pageIndex else { return }
        let idx = sel.objectIndex

        let before = page.clonePageObject(at: idx)

        let dx = Float(newBBox.origin.x - oldBBox.origin.x)
        let dy = Float(newBBox.origin.y - oldBBox.origin.y)
        if abs(dx) > 0.01 || abs(dy) > 0.01 {
            page.movePageObject(at: idx, byX: dx, y: dy)
        }
        if abs(newBBox.width - oldBBox.width) > 0.5 || abs(newBBox.height - oldBBox.height) > 0.5 {
            page.resizePageObject(at: idx, toWidth: Float(newBBox.width), height: Float(newBBox.height))
        }

        let after = page.clonePageObject(at: idx)
        registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: after, description: "移动/缩放图片")

        var updated = sel
        updated.bbox = newBBox
        imageSelection = updated
        invalidateAllPages()
    }

    func applyImageOperation(_ op: ImageOperation, pageIndex: Int, objectIndex: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        let idx = objectIndex
        switch op {
        case .rotateLeft:
            let before = page.clonePageObject(at: idx)
            page.rotatePageObject(at: idx, byAngle: Float.pi / 2)
            registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: nil, description: "旋转图片")
        case .rotateRight:
            let before = page.clonePageObject(at: idx)
            page.rotatePageObject(at: idx, byAngle: -Float.pi / 2)
            registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: nil, description: "旋转图片")
        case .flipHorizontal:
            let before = page.clonePageObject(at: idx)
            page.flipPageObject(at: idx, horizontal: true)
            registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: nil, description: "水平翻转")
        case .flipVertical:
            let before = page.clonePageObject(at: idx)
            page.flipPageObject(at: idx, horizontal: false)
            registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: nil, description: "垂直翻转")
        case .delete:
            deleteImageObject(pageIndex: pageIndex, idx: idx)
        case .replace:
            replaceImageObject(pageIndex: pageIndex, idx: idx)
        case .export:
            exportImageObject(pageIndex: pageIndex, idx: idx)
        case .sendToBack:
            page.sendPageObjectToBack(at: idx)
            invalidateAllPages()
        case .bringToFront:
            page.bringPageObjectToFront(at: idx)
            invalidateAllPages()
        }
    }

    func addImage(path: String, pageIndex: Int, point: CGPoint) {
        guard let page = document?.page(at: pageIndex) else { return }
        guard let jpgPath = Self.convertToJPEGIfNeeded(path: path) else { return }

        var pxW: CGFloat = 100, pxH: CGFloat = 100
        if let img = NSImage(contentsOfFile: jpgPath), img.size.width > 0, img.size.height > 0 {
            pxW = img.size.width
            pxH = img.size.height
        }
        let maxDim: CGFloat = 200
        let scale = min(1, maxDim / max(pxW, pxH))
        let w = Float(pxW * scale)
        let h = Float(pxH * scale)

        let idx = page.addImage(withJpegPath: jpgPath, atX: Float(point.x), y: Float(point.y),
                                width: w, height: h, alpha: 1.0)
        guard idx >= 0 else { return }

        let clone = page.clonePageObject(at: idx)
        if clone != 0 {
            undoManager.register(UndoItem(
                description: "添加图片",
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.deletePageObject(at: idx) }
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addPageObjectClone(clone, atZOrder: idx) }
                },
                dispose: { ArkoPage.releasePageObjectClone(clone) }
            ))
        }

        if let info = page.pageObjectInfo(at: idx), let bbox = (info["bbox"] as? NSValue)?.rectValue {
            imageSelection = ImageSelection(pageIndex: pageIndex, objectIndex: idx, bbox: bbox)
        }
        invalidateAllPages()
    }

    // MARK: - 链接

    func setLinkDraft(_ rect: CGRect?, pageIndex: Int) {
        if let r = rect {
            linkDraft = LinkDraft(pageIndex: pageIndex, rect: r)
        } else {
            linkDraft = nil
        }
    }

    func promptLinkTarget(pageIndex: Int, rect: CGRect) {
        pendingLink = LinkDraft(pageIndex: pageIndex, rect: rect)
    }

    func addLink(pageIndex: Int, rect: CGRect, target: LinkTarget) {
        guard let page = document?.page(at: pageIndex) else { return }
        let handler = page.addLinkAnnot(in: rect)
        guard handler != 0 else { return }
        switch target {
        case .url(let url):
            page.setLinkURI(url, forAnnotHandler: handler)
        case .page(let p):
            page.setLinkDestinationPage(p, zoomMode: 2, forAnnotHandler: handler)  // 2 = 适合页面
        }

        let annotIndex = page.annotCount - 1
        undoManager.register(UndoItem(
            description: "添加链接",
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.removeAnnot(byHandler: handler) }
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addAnnot(byHandler: handler, at: annotIndex) }
            }
        ))

        annotEvents.send(AnnotEvent(kind: .added, pageIndex: pageIndex, annotType: 2))  // ANNOT_TYPE_LINK
        refreshAnnotations()
        invalidateAllPages()
    }

    // MARK: - 内部辅助

    /// 重读当前段落的光标/格式，刷新发布状态。
    @discardableResult
    func refreshParagraphSelection(caret: Int, endCaret: Int) -> ParagraphSelection? {
        guard let para = editingParagraph else { return nil }
        let s = min(caret, endCaret)
        let e = max(caret, endCaret)
        let boxes = para.selBoxes(fromCaret: s, toCaret: e).map { $0.rectValue }
        let c = max(0, caret)
        let sel = ParagraphSelection(
            pageIndex: editingPage ?? 0,
            startCaret: s, endCaret: e,
            fontSize: para.fontSize(atCaret: c),
            textColor: para.textColor(atCaret: c),
            isBold: para.isBold(atCaret: c),
            isItalic: para.isItalic(atCaret: c),
            isUnderline: para.isUnderline(atCaret: c),
            isStrikeout: para.isStrikeout(atCaret: c),
            boxes: boxes
        )
        paragraphSelection = sel
        return sel
    }

    func clearParagraphEdit() {
        editingParagraph = nil
        editingPage = nil
        paragraphSelection = nil
    }

    /// 撤销/重做段落编辑后重读光标状态。
    func resyncParagraphAfterUndo(pageIndex: Int) {
        guard editingPage == pageIndex, let para = editingParagraph else { return }
        let c = para.currentCaret
        _ = refreshParagraphSelection(caret: c, endCaret: c)
    }

    private func registerParaUndo(_ handle: UInt64, pageIndex: Int, description: String) {
        guard handle != 0 else { return }
        undoManager.register(UndoItem(
            description: description,
            undo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.paraUndoItem(handle) }
                ctx.resyncParagraphAfterUndo(pageIndex: pageIndex)
            },
            redo: { ctx in
                ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.paraRedoItem(handle) }
                ctx.resyncParagraphAfterUndo(pageIndex: pageIndex)
            },
            dispose: { ArkoParagraph.releaseUndoItem(handle) }
        ))
    }

    /// 注册「变换类」图片操作的撤销：before=变换前克隆，after 为空则在内部克隆"变换后"状态。
    private func registerImageTransformUndo(pageIndex: Int, idx: Int, before: UInt64, after: UInt64?, description: String) {
        var afterClone = after
        if before != 0 && afterClone == nil {
            afterClone = document?.page(at: pageIndex)?.clonePageObject(at: idx) ?? 0
        }
        if before != 0 && (afterClone ?? 0) != 0 {
            let a = afterClone!
            undoManager.register(UndoItem(
                description: description,
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.copyPageObject(at: idx, fromClone: before) }
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.copyPageObject(at: idx, fromClone: a) }
                },
                dispose: {
                    ArkoPage.releasePageObjectClone(before)
                    ArkoPage.releasePageObjectClone(a)
                }
            ))
        } else {
            if before != 0 { ArkoPage.releasePageObjectClone(before) }
            if let a = afterClone, a != 0 { ArkoPage.releasePageObjectClone(a) }
        }
        invalidateAllPages()
    }

    private func deleteImageObject(pageIndex: Int, idx: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        let clone = page.clonePageObject(at: idx)
        page.deletePageObject(at: idx)
        imageSelection = nil
        if clone != 0 {
            undoManager.register(UndoItem(
                description: "删除图片",
                undo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.addPageObjectClone(clone, atZOrder: idx) }
                },
                redo: { ctx in
                    ctx.performUndoRedo { ctx.document?.page(at: pageIndex)?.deletePageObject(at: idx) }
                },
                dispose: { ArkoPage.releasePageObjectClone(clone) }
            ))
        }
        invalidateAllPages()
    }

    private func replaceImageObject(pageIndex: Int, idx: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url,
              let jpgPath = Self.convertToJPEGIfNeeded(path: url.path) else { return }

        let before = page.clonePageObject(at: idx)
        page.replaceImage(at: idx, withJpegPath: jpgPath)
        registerImageTransformUndo(pageIndex: pageIndex, idx: idx, before: before, after: nil, description: "替换图片")
    }

    private func exportImageObject(pageIndex: Int, idx: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = "image.jpg"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        _ = page.exportImage(at: idx, toJpegPath: url.path)
    }

    /// PNG → 临时 JPEG（SDK AddImage/ReplaceImage 只接受 jpg）。
    private static func convertToJPEGIfNeeded(path: String) -> String? {
        let ext = (path as NSString).pathExtension.lowercased()
        if ext == "jpg" || ext == "jpeg" { return path }
        guard let img = NSImage(contentsOfFile: path),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: 0.9)]) else {
            return nil
        }
        let temp = NSTemporaryDirectory() + "arko_\(UUID().uuidString).jpg"
        do {
            try data.write(to: URL(fileURLWithPath: temp))
            return temp
        } catch {
            return nil
        }
    }
}
