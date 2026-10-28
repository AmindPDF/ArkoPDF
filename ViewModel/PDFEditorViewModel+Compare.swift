//  PDFEditorViewModel+Compare.swift
//  文档对比：打开新文档并执行对比，产出逐页差异。

import Foundation

extension PDFEditorViewModel {

    /// 对比当前文档与 url 指定的新文档。
    func runCompare(withNewDocumentAt url: URL) {
        guard let currentDoc = document else { return }
        do {
            let newDoc = try ArkoDocument(url: url)
            defer { newDoc.close() }
            let diffs = CompareEngine.compare(old: currentDoc, new: newDoc)
            compareDiffs = diffs
            compareActive = !diffs.isEmpty
            compareSummaryPresented = true
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// 指定页的对比差异（叠加高亮用），无差异返回 nil。
    func compareDiff(forPage pageIndex: Int) -> PageDiff? {
        compareDiffs.first { $0.pageIndex == pageIndex }
    }

    /// 结束对比模式。
    func endCompare() {
        compareDiffs = []
        compareActive = false
    }
}
