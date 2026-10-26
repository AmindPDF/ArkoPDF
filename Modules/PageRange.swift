//  PageRange.swift
//  页面范围选择模型：全部 / 范围 / 奇数 / 偶数 / 自定义页码组合（如 "1,3-5,7-21,24"）。
//  用于提取 / 插入 / 替换页面的页面选择器。

import Foundation

enum PageRange {
    case all
    case range(start: Int, end: Int)   // 1-based 闭区间
    case odd
    case even
    case custom(String)                // "1,3-5,7-21,24"

    /// 解析成 0-based 页号数组（升序、去重）。
    func resolve(pageCount: Int) -> [Int] {
        guard pageCount > 0 else { return [] }
        switch self {
        case .all:
            return Array(0..<pageCount)
        case .range(let s, let e):
            let lo = max(1, min(s, e))
            let hi = min(pageCount, max(s, e))
            guard lo <= hi else { return [] }
            return (lo...hi).map { $0 - 1 }
        case .odd:
            return (1...pageCount).filter { $0 % 2 == 1 }.map { $0 - 1 }
        case .even:
            return (1...pageCount).filter { $0 % 2 == 0 }.map { $0 - 1 }
        case .custom(let text):
            return Self.parseCustom(text, pageCount: pageCount)
        }
    }

    /// 解析 "1,3-5,7-21,24" → 0-based 页号数组（升序、去重）。
    static func parseCustom(_ text: String, pageCount: Int) -> [Int] {
        var result: [Int] = []
        for rawPart in text.split(separator: ",") {
            let part = rawPart.trimmingCharacters(in: .whitespaces)
            guard !part.isEmpty else { continue }
            if part.contains("-") {
                let bounds = part.split(separator: "-", maxSplits: 1)
                if bounds.count == 2,
                   let a = Int(bounds[0].trimmingCharacters(in: .whitespaces)),
                   let b = Int(bounds[1].trimmingCharacters(in: .whitespaces)) {
                    let lo = max(1, min(a, b))
                    let hi = min(pageCount, max(a, b))
                    if lo <= hi { result.append(contentsOf: (lo...hi).map { $0 - 1 }) }
                }
            } else if let n = Int(part), n >= 1, n <= pageCount {
                result.append(n - 1)
            }
        }
        return Array(Set(result)).sorted()
    }

    /// 解析出的页数（用于预览「共 N 页」）。
    func resolvedCount(pageCount: Int) -> Int {
        resolve(pageCount: pageCount).count
    }
}
