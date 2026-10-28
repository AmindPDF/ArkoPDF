//  CompareEngine.swift
//  文档对比引擎：逐页「朋友匹配」字符，识别 新增/删除。
//
//  对旧/新两页字符做位置近、尺寸近、内容相同的匹配，未匹配者即差异。
//  该方式对 PDF 文本提取顺序（多栏/浮动文本）更稳健，优于纯序列 diff。

import Foundation
import CoreGraphics

enum CompareEngine {

    /// 位置容差（pt）与尺寸容差。
    static let positionTolerance: CGFloat = 2.0
    static let sizeTolerance: CGFloat = 1.5
    /// 页眉/页脚忽略比例（按页面高度）。
    static let headerRatio: CGFloat = 0.08
    static let footerRatio: CGFloat = 0.06

    /// 对比两个文档，逐页返回差异（仅包含有差异的页）。
    static func compare(old: ArkoDocument, new: ArkoDocument,
                        filters: CompareFilters = CompareFilters()) -> [PageDiff] {
        let pageCount = max(old.pageCount, new.pageCount)
        var results: [PageDiff] = []
        for p in 0..<pageCount {
            let oldChars = extractChars(document: old, pageIndex: p, filters: filters)
            let newChars = extractChars(document: new, pageIndex: p, filters: filters)
            let diff = diffPage(oldChars: oldChars, newChars: newChars, pageIndex: p, filters: filters)
            if !diff.isEmpty {
                results.append(diff)
            }
        }
        return results
    }

    /// 从某页提取有效字符（过滤控制/空白/标点/页眉页脚，按需忽略大小写）。
    static func extractChars(document: ArkoDocument, pageIndex: Int,
                             filters: CompareFilters) -> [PageCharInfo] {
        guard let page = document.page(at: pageIndex) else { return [] }
        let pageHeight = page.heightInPoints
        return page.charInfoList().compactMap { dict in
            guard let u = dict["u"] as? Int,
                  let x = dict["x"] as? Double,
                  let y = dict["y"] as? Double,
                  let w = dict["w"] as? Double,
                  let h = dict["h"] as? Double,
                  let fs = dict["fs"] as? Double else { return nil }
            var unicode = UInt32(u)
            if isControlChar(unicode) { return nil }
            if w < 0.5 || h < 0.5 { return nil }
            if filters.ignoreWhitespace && isWhitespace(unicode) { return nil }
            if filters.ignorePunctuation && isPunctuation(unicode) { return nil }
            if filters.ignoreHeaderFooter && pageHeight > 0 {
                let rect = CGRect(x: x, y: y, width: w, height: h)
                // 位于页面顶部/底部固定比例区域内视为页眉页脚
                if rect.maxY > pageHeight * (1 - headerRatio) || rect.minY < pageHeight * footerRatio {
                    return nil
                }
            }
            if filters.ignoreCase { unicode = lowercased(unicode) }
            return PageCharInfo(unicode: unicode,
                                rect: CGRect(x: x, y: y, width: w, height: h),
                                fontSize: Float(fs))
        }
    }

    static func isControlChar(_ u: UInt32) -> Bool { u < 32 }

    static func isWhitespace(_ u: UInt32) -> Bool {
        u == 32 || u == 160 || u == 9 || u == 0x3000  // 空格 / 不间断空格 / 制表 / 全角空格
    }

    static func isPunctuation(_ u: UInt32) -> Bool {
        let ranges: [ClosedRange<UInt32>] = [
            0x21...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E,   // ASCII 标点
            0x3000...0x303F,                                        // CJK 标点
            0xFF01...0xFF0F, 0xFF1A...0xFF20, 0xFF3B...0xFF40, 0xFF5B...0xFF65  // 全角标点
        ]
        return ranges.contains { $0.contains(u) }
    }

    static func lowercased(_ u: UInt32) -> UInt32 {
        if u >= 65 && u <= 90 { return u + 32 }  // ASCII A-Z → a-z
        return u
    }

    /// 用「朋友匹配」对比两页字符。
    static func diffPage(oldChars: [PageCharInfo], newChars: [PageCharInfo],
                         pageIndex: Int, filters: CompareFilters) -> PageDiff {
        var newMatched = [Bool](repeating: false, count: newChars.count)
        var deleted: [CGRect] = []
        var added: [CGRect] = []

        for oldChar in oldChars {
            var found = false
            for (j, newChar) in newChars.enumerated() {
                if newMatched[j] { continue }
                if oldChar.unicode != newChar.unicode { continue }
                if abs(oldChar.rect.origin.x - newChar.rect.origin.x) > positionTolerance { continue }
                if abs(oldChar.rect.origin.y - newChar.rect.origin.y) > positionTolerance { continue }
                if abs(oldChar.rect.width - newChar.rect.width) > sizeTolerance { continue }
                if abs(oldChar.rect.height - newChar.rect.height) > sizeTolerance { continue }
                newMatched[j] = true
                found = true
                break
            }
            if !found {
                deleted.append(oldChar.rect)
            }
        }

        for (j, newChar) in newChars.enumerated() where !newMatched[j] {
            added.append(newChar.rect)
        }

        return PageDiff(pageIndex: pageIndex,
                        deletedRects: mergeRects(deleted),
                        addedRects: mergeRects(added))
    }

    /// 按行合并相邻字符矩形（同 y 的矩形合并为一个行矩形）。
    static func mergeRects(_ rects: [CGRect]) -> [CGRect] {
        guard !rects.isEmpty else { return [] }
        var lines: [[CGRect]] = []
        for rect in rects {
            var placed = false
            for i in 0..<lines.count {
                if abs(lines[i][0].origin.y - rect.origin.y) <= positionTolerance {
                    lines[i].append(rect)
                    placed = true
                    break
                }
            }
            if !placed {
                lines.append([rect])
            }
        }
        return lines.map { line in
            line.dropFirst().reduce(line[0]) { $0.union($1) }
        }
    }
}
