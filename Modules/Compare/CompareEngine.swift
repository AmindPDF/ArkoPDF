//  CompareEngine.swift
//  文档对比引擎：逐页「朋友匹配」字符，识别 新增/删除。
//
//  参照 Foxit ComparePDF：把文本解析成字符（内容+位置+尺寸），
//  对旧/新两页字符做位置近、尺寸近、内容相同的匹配，未匹配者即差异。
//  该方式对 PDF 文本提取顺序（多栏/浮动文本）更稳健，优于纯序列 diff。

import Foundation
import CoreGraphics

enum CompareEngine {

    /// 位置容差（pt）与尺寸容差。
    static let positionTolerance: CGFloat = 2.0
    static let sizeTolerance: CGFloat = 1.5

    /// 对比两个文档，逐页返回差异（仅包含有差异的页）。
    static func compare(old: ArkoDocument, new: ArkoDocument) -> [PageDiff] {
        let pageCount = max(old.pageCount, new.pageCount)
        var results: [PageDiff] = []
        for p in 0..<pageCount {
            let oldChars = extractChars(document: old, pageIndex: p)
            let newChars = extractChars(document: new, pageIndex: p)
            let diff = diffPage(oldChars: oldChars, newChars: newChars, pageIndex: p)
            if !diff.isEmpty {
                results.append(diff)
            }
        }
        return results
    }

    /// 从某页提取有效字符（过滤控制字符与零尺寸字符）。
    static func extractChars(document: ArkoDocument, pageIndex: Int) -> [PageCharInfo] {
        guard let page = document.page(at: pageIndex) else { return [] }
        return page.charInfoList().compactMap { dict in
            guard let u = dict["u"] as? Int,
                  let x = dict["x"] as? Double,
                  let y = dict["y"] as? Double,
                  let w = dict["w"] as? Double,
                  let h = dict["h"] as? Double,
                  let fs = dict["fs"] as? Double else { return nil }
            let unicode = UInt32(u)
            if isControlChar(unicode) { return nil }
            if w < 0.5 || h < 0.5 { return nil }
            return PageCharInfo(unicode: unicode,
                                rect: CGRect(x: x, y: y, width: w, height: h),
                                fontSize: Float(fs))
        }
    }

    static func isControlChar(_ u: UInt32) -> Bool {
        // 空格（32）保留；其它 <32 的控制字符（换行/回车/制表）跳过。
        return u < 32
    }

    /// 用「朋友匹配」对比两页字符。
    static func diffPage(oldChars: [PageCharInfo], newChars: [PageCharInfo], pageIndex: Int) -> PageDiff {
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

    /// 按行合并相邻字符矩形，让高亮更干净（同 y 的矩形合并为一个行矩形）。
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
