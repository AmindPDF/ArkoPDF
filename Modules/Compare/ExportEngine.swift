//  ExportEngine.swift
//  对比结果导出：纯文本「修改清单报告」。

import Foundation

enum CompareExportEngine {

    /// 生成纯文本修改清单报告。
    static func buildTextReport(old: ArkoDocument, new: ArkoDocument,
                                diffs: [PageDiff], aiResult: AICompareResult?) -> String {
        var lines: [String] = []
        lines.append("文档对比报告")
        lines.append("生成时间：\(Self.nowString())")
        lines.append("")

        // AI 摘要（可选）
        if let ai = aiResult, !ai.summary.isEmpty {
            lines.append("【修改摘要】")
            lines.append(ai.summary)
            lines.append("")
        }

        // 逐页变更
        if diffs.isEmpty {
            lines.append("未发现差异。")
        } else {
            for diff in diffs {
                let page = diff.pageIndex + 1
                for rect in diff.deletedRects {
                    let text = old.page(at: diff.pageIndex)?.text(inRect: rect) ?? ""
                    lines.append("[第 \(page) 页] 删除 | \(text)")
                }
                for rect in diff.addedRects {
                    let text = new.page(at: diff.pageIndex)?.text(inRect: rect) ?? ""
                    lines.append("[第 \(page) 页] 新增 | \(text)")
                }
            }
        }

        // AI 风险（可选）
        if let ai = aiResult, !ai.risks.isEmpty {
            lines.append("")
            lines.append("【风险提示】")
            for r in ai.risks { lines.append("- \(r)") }
        }

        return lines.joined(separator: "\n")
    }

    private static func nowString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}
