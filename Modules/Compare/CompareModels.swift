//  CompareModels.swift
//  文档对比：数据模型。

import Foundation
import CoreGraphics

/// 一个页面字符（文档对比用）。
struct PageCharInfo {
    let unicode: UInt32
    let rect: CGRect      // x=left, y=bottom（PDF 用户坐标）
    let fontSize: Float
}

/// 一页的对比差异。
struct PageDiff {
    let pageIndex: Int
    let deletedRects: [CGRect]   // 旧页被删除的内容（红）
    let addedRects: [CGRect]     // 新页新增的内容（绿）

    var isEmpty: Bool { deletedRects.isEmpty && addedRects.isEmpty }
    var deletedCount: Int { deletedRects.count }
    var addedCount: Int { addedRects.count }
}
