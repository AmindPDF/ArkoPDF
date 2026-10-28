//  PDFEditorViewModel+Compare.swift
//  文档对比：对比流程、进度、结果状态、AI 分析、导出。

import Foundation

extension PDFEditorViewModel {

    /// 打开对比设置对话框。
    func startCompare() {
        compareSetupPresented = true
    }

    /// 执行对比：后台跑基础对比 + AI 分析，前台显示进度，完成后进入结果视图。
    func runCompare(newURL: URL, mode: CompareMode, filters: CompareFilters) {
        guard let currentDoc = document else { return }
        // 清理上一次对比
        compareNewDocument?.close()
        compareNewDocument = nil
        compareNewURL = nil

        compareSetupPresented = false
        compareMode = mode
        compareFilters = filters
        compareRunning = true
        compareAnalyzing = false
        compareProgress = 0
        compareProgressText = "正在准备…"
        compareDiffs = []
        compareAIResult = AICompareResult(summary: "", changes: [], risks: [])
        compareViewMode = .highlight

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let newDoc = try ArkoDocument(url: newURL)
                DispatchQueue.main.async {
                    self.compareNewDocument = newDoc
                    self.compareNewURL = newURL
                    self.compareProgressText = "正在对比文档…"
                }

                // 基础对比（逐页进度）
                let diffs = CompareEngine.compare(old: currentDoc, new: newDoc, filters: filters) { p in
                    DispatchQueue.main.async { self.compareProgress = p }
                }

                DispatchQueue.main.async {
                    self.compareDiffs = diffs
                    self.compareProgress = 1.0
                }

                if mode == .ai {
                    self.runAICompare(old: currentDoc, new: newDoc, diffs: diffs) { [weak self] in
                        self?.finishCompare()
                    }
                } else {
                    self.finishCompare()
                }
            } catch {
                DispatchQueue.main.async {
                    self.compareRunning = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    /// AI 语义对比：把有差异的页作为对齐段，送 AIProvider 分析，完成后回调。
    private func runAICompare(old: ArkoDocument, new: ArkoDocument, diffs: [PageDiff],
                              completion: @escaping () -> Void) {
        var segments: [AICompareSegment] = []
        for diff in diffs {
            let oldText = old.page(at: diff.pageIndex)?.pageText() ?? ""
            let newText = new.page(at: diff.pageIndex)?.pageText() ?? ""
            segments.append(AICompareSegment(location: "第 \(diff.pageIndex + 1) 页",
                                             oldText: oldText, newText: newText))
        }
        guard !segments.isEmpty else {
            DispatchQueue.main.async {
                self.compareAIResult = AICompareResult(summary: "未发现需 AI 分析的差异。", changes: [], risks: [])
                completion()
            }
            return
        }

        let provider = AIProviderFactory.make(config: compareAIConfig)
        DispatchQueue.main.async {
            self.compareProgressText = "正在 AI 分析…"
            self.compareAnalyzing = true
        }
        provider.analyze(segments: segments) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.compareAnalyzing = false
                switch result {
                case .success(let r):
                    self.compareAIResult = r
                case .failure(let e):
                    self.compareAIResult = AICompareResult(
                        summary: "AI 分析失败：\(e.localizedDescription)", changes: [], risks: [])
                }
                completion()
            }
        }
    }

    /// 对比完成：关闭进度，进入结果视图。
    private func finishCompare() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.compareRunning = false
            self.compareResultPresented = true
        }
    }

    /// 指定页的对比差异（结果视图叠加用）。
    func compareDiff(forPage pageIndex: Int) -> PageDiff? {
        compareDiffs.first { $0.pageIndex == pageIndex }
    }

    /// 结束对比：释放新文档、清空结果。
    func endCompare() {
        compareNewDocument?.close()
        compareNewDocument = nil
        compareNewURL = nil
        compareDiffs = []
        compareAIResult = AICompareResult(summary: "", changes: [], risks: [])
        compareRunning = false
        compareResultPresented = false
    }

    /// 导出对比报告。format：0=纯文本清单，1=合并版 PDF（标记版）。
    func exportCompareReport(to url: URL, format: Int) {
        guard let old = document, let new = compareNewDocument else { return }
        if format == 0 {
            let ai = compareMode == .ai ? compareAIResult : nil
            let text = CompareExportEngine.buildTextReport(old: old, new: new, diffs: compareDiffs, aiResult: ai)
            try? text.write(to: url, atomically: true, encoding: .utf8)
        } else {
            exportMergedPDF(to: url)
        }
    }

    /// 合并版 PDF（标记版）：以旧文档为底，删除红框、新增绿框，导出到 url。
    private func exportMergedPDF(to url: URL) {
        guard let old = document, let path = old.filePath else { return }
        do {
            let copy = try ArkoDocument(url: URL(fileURLWithPath: path))
            defer { copy.close() }
            let red = ArkoPage.makeRGBColor(withRed: 229, green: 72, blue: 77)
            let green = ArkoPage.makeRGBColor(withRed: 48, green: 164, blue: 108)
            for diff in compareDiffs {
                guard let page = copy.page(at: diff.pageIndex) else { continue }
                for rect in diff.deletedRects {
                    _ = page.addMarkRect(at: rect, fillColor: red)
                }
                for rect in diff.addedRects {
                    _ = page.addMarkRect(at: rect, fillColor: green)
                }
            }
            try copy.save(to: url, progress: nil, isCancelled: nil, security: nil)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
