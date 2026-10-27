//  PDFEditorViewModel+Redaction.swift
//  密文：框选预览 / 标记 / 应用（Phase B）。

import AppKit

extension PDFEditorViewModel {

    // MARK: - 密文

    /// 拖拽框选实时预览（nil 清除）。
    func setRedactionDraft(_ rect: CGRect?, pageIndex: Int) {
        if let r = rect {
            redactionDraft = (pageIndex, r)
        } else {
            redactionDraft = nil
        }
    }

    /// 添加密文标记（手动工具与批量密文共用的入口，含撤销）。
    func markRedaction(rects: [CGRect], pageIndex: Int) {
        guard let doc = document, let page = doc.page(at: pageIndex) else { return }
        let before = page.annotCount
        let handlers = RedactionEngine.mark(document: doc, pageIndex: pageIndex,
                                            rects: rects, appearance: redactionAppearance)
        guard !handlers.isEmpty else { return }
        let indices = handlers.indices.map { before + $0 }

        undoManager.register(UndoItem(
            description: "密文标记",
            undo: { ctx in
                ctx.performUndoRedo {
                    for h in handlers { ctx.document?.page(at: pageIndex)?.removeAnnot(byHandler: h) }
                }
            },
            redo: { ctx in
                ctx.performUndoRedo {
                    for (h, idx) in zip(handlers, indices) {
                        ctx.document?.page(at: pageIndex)?.addAnnot(byHandler: h, at: idx)
                    }
                }
            }
        ))
        refreshAnnotations()
        invalidateAllPages()
    }

    /// 应用密文（Phase B：ArkoPDFCore 删除底层内容并固化黑块）。
    func applyRedactions() {
        guard let doc = document else { return }
        for p in 0..<doc.pageCount {
            RedactionEngine.apply(document: doc, pageIndex: p)
        }
        invalidateAllPages()
    }
}
