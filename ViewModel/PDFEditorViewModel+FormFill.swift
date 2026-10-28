//  PDFEditorViewModel+FormFill.swift
//  表单填充：鼠标/键盘事件路由到 ArkoFormFill，变化后重绘。

import AppKit

extension PDFEditorViewModel {

    /// 文档打开后设置表单填充回调（变化 → 失效渲染缓存重绘）。
    func setupFormFillCallbacks() {
        document?.formFill?.onInvalidate = { [weak self] in
            DispatchQueue.main.async { self?.invalidateAllPages() }
        }
        document?.formFill?.onChange = { [weak self] in
            DispatchQueue.main.async { self?.invalidateAllPages() }
        }
    }

    /// 路由鼠标事件到表单填充。返回 true 表示已处理（调用方应停止继续分发）。
    func routeFormFill(phase: ToolPhase, pageIndex: Int, userPoint: CGPoint,
                       modifiers: NSEvent.ModifierFlags) -> Bool {
        guard let doc = document, let ff = doc.formFill, let page = doc.page(at: pageIndex) else {
            return false
        }
        let mod: Int32 = modifiers.contains(.shift) ? 1 : 0   // 简化：仅区分 shift
        switch phase {
        case .down:
            let type = ff.formFieldType(at: page, x: userPoint.x, y: userPoint.y)
            guard type >= 0 else { return false }
            formFillActive = ff.onLButtonDown(at: page, x: userPoint.x, y: userPoint.y, modifier: mod)
            return formFillActive
        case .up:
            if formFillActive {
                formFillActive = false
                _ = ff.onLButtonUp(at: page, x: userPoint.x, y: userPoint.y, modifier: mod)
                return true
            }
            return false
        case .drag:
            return false
        }
    }

    /// 键盘按键路由到表单填充（文本输入用）。
    func routeFormFillKey(keyCode: Int, modifier: Int) -> Bool {
        guard let doc = document, let ff = doc.formFill, let page = doc.page(at: currentPage) else {
            return false
        }
        return ff.onKeyDown(at: page, keyCode: Int32(keyCode), modifier: Int32(modifier))
    }

    /// 字符输入路由到表单填充。
    func routeFormFillChar(nChar: Int, modifier: Int) -> Bool {
        guard let doc = document, let ff = doc.formFill, let page = doc.page(at: currentPage) else {
            return false
        }
        return ff.onChar(at: page, nChar: Int32(nChar), modifier: Int32(modifier))
    }

    /// 保存前失焦表单字段（把正在编辑的值写回字段）。
    func commitFormFill() {
        _ = document?.formFill?.forceKillFocus()
    }
}
