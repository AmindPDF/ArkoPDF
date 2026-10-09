//  EditTools.swift
//  编辑模块工具：段落编辑 / 添加文字 / 添加图片 / 图片编辑 / 链接。
//  对应 Windows 版 editcontent 的 CAmdEdt_EditParaTool / CAmdEdt_AddImageTool /
//  CAmdEdt_ImgObjHandler 以及 annots 的 CAmdEdt_LinkAnnotTool。

import AppKit
import UniformTypeIdentifiers

// MARK: - 段落编辑（点击段落 → 光标/选区 → 格式栏排版 + 插入/删除文字）

final class EditParagraphTool: EditorTool {
    let id = "tool.editParagraph"
    let displayName = "段落编辑"
    let icon = "text.justify"

    private var dragging = false
    private var activePage: Int?

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let ctx = context as? EditContext else { return }
        dragging = true
        activePage = event.pageIndex
        ctx.beginParagraphEdit(pageIndex: event.pageIndex, point: event.point)
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let ctx = context as? EditContext, event.pageIndex == activePage else { return }
        ctx.updateParagraphCaret(pageIndex: event.pageIndex, point: event.point)
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        dragging = false
        activePage = nil
    }

    func reset() {
        dragging = false
        activePage = nil
    }
}

// MARK: - 添加文字/段落（空白处新建段落，命中则编辑）

final class AddTextTool: EditorTool {
    let id = "tool.addText"
    let displayName = "添加文字"
    let icon = "text.append"

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let ctx = context as? EditContext else { return }
        if ctx.beginParagraphEdit(pageIndex: event.pageIndex, point: event.point) == nil {
            // 空白处：新建段落并进入编辑
            ctx.createParagraph(pageIndex: event.pageIndex, point: event.point)
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() {}
}

// MARK: - 添加图片（激活时选文件，点击放置）

final class AddImageTool: EditorTool {
    let id = "tool.addImage"
    let displayName = "添加图片"
    let icon = "photo"

    private var pendingPath: String?

    func activated(context: ToolContext) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            pendingPath = url.path
        } else {
            pendingPath = nil
        }
    }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let ctx = context as? EditContext, let path = pendingPath else { return }
        ctx.addImage(path: path, pageIndex: event.pageIndex, point: event.point)
        pendingPath = nil
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {}
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {}
    func reset() { pendingPath = nil }
}

// MARK: - 图片编辑（选中图片 → 拖动移动 / 右下角拖动缩放；旋转/翻转/删除/替换/导出走 EditBar）

final class EditImageTool: EditorTool {
    let id = "tool.editImage"
    let displayName = "图片编辑"
    let icon = "photo.on.rectangle.angled"

    private var dragging = false
    private var resizeMode = false
    private var startBBox: CGRect = .zero
    private var liveBBox: CGRect = .zero

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let ctx = context as? EditContext else { return }
        if let sel = ctx.beginImageEdit(pageIndex: event.pageIndex, point: event.point) {
            dragging = true
            startBBox = sel.bbox
            liveBBox = sel.bbox
            resizeMode = Self.isNearBottomRight(event.point, in: sel.bbox)
        }
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let ctx = context as? EditContext else { return }
        let dx = event.point.x - startBBox.origin.x
        let dy = event.point.y - startBBox.origin.y
        if resizeMode {
            // 左下角锚点缩放
            let newW = max(1, startBBox.width + dx)
            let newH = max(1, startBBox.height + dy)
            liveBBox = CGRect(x: startBBox.origin.x, y: startBBox.origin.y, width: newW, height: newH)
        } else {
            liveBBox = CGRect(x: startBBox.origin.x + dx,
                              y: startBBox.origin.y + dy,
                              width: startBBox.width, height: startBBox.height)
        }
        ctx.updateImageDrag(pageIndex: event.pageIndex, bbox: liveBBox)
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let ctx = context as? EditContext else { dragging = false; return }
        dragging = false
        ctx.commitImageChange(pageIndex: event.pageIndex, oldBBox: startBBox, newBBox: liveBBox)
    }

    func reset() {
        dragging = false
        resizeMode = false
    }

    private static func isNearBottomRight(_ p: CGPoint, in bbox: CGRect, tol: CGFloat = 12) -> Bool {
        let corner = CGPoint(x: bbox.maxX, y: bbox.maxY)
        return abs(p.x - corner.x) <= tol && abs(p.y - corner.y) <= tol
    }
}

// MARK: - 链接（拖拽矩形 → 填 URL / 页内跳转）

final class LinkTool: EditorTool {
    let id = "tool.link"
    let displayName = "链接"
    let icon = "link"

    private var dragging = false
    private var startPoint: CGPoint?

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext) {
        guard let _ = context as? EditContext else { return }
        dragging = true
        startPoint = event.point
    }

    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let s = startPoint, let ctx = context as? EditContext else { return }
        let r = CGRect(x: min(s.x, event.point.x), y: min(s.y, event.point.y),
                       width: abs(event.point.x - s.x), height: abs(event.point.y - s.y))
        ctx.setLinkDraft(r, pageIndex: event.pageIndex)
    }

    func mouseUp(_ event: ToolMouseEvent, context: ToolContext) {
        guard dragging, let s = startPoint, let ctx = context as? EditContext else {
            dragging = false
            return
        }
        dragging = false
        ctx.setLinkDraft(nil, pageIndex: event.pageIndex)
        let r = CGRect(x: min(s.x, event.point.x), y: min(s.y, event.point.y),
                       width: abs(event.point.x - s.x), height: abs(event.point.y - s.y))
        guard r.width > 4, r.height > 4 else { return }
        ctx.promptLinkTarget(pageIndex: event.pageIndex, rect: r)
    }

    func reset() {
        dragging = false
        startPoint = nil
    }
}
