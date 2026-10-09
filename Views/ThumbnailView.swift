//  ThumbnailView.swift
//  缩略图侧栏：小尺寸渲染，点击跳页，当前页高亮。

import SwiftUI
import AppKit

struct ThumbnailView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<vm.pageCount, id: \.self) { i in
                    ThumbnailCell(pageIndex: i)
                        .onTapGesture { vm.currentPage = i }
                }
            }
            .padding(12)
        }
    }
}

private struct ThumbnailCell: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let pageIndex: Int

    private let thumbnailZoom: Double = 0.16

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let cg = vm.image(forPage: pageIndex, zoom: thumbnailZoom) {
                    Image(nsImage: NSImage(cgImage: cg, size: NSSize(width: CGFloat(cg.width), height: CGFloat(cg.height))))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .aspectRatio(0.7, contentMode: .fit)
                }
            }
            .frame(maxWidth: 150)

            Text("\(pageIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(vm.currentPage == pageIndex ? Color.accentColor.opacity(0.22) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(vm.currentPage == pageIndex ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button("插入空白页") { vm.insertBlankPage(after: pageIndex) }
            Button("删除此页") { vm.deletePage(at: pageIndex) }
                .disabled(vm.pageCount <= 1)
            Button("顺时针旋转 90°") { vm.rotatePageClockwise90(at: pageIndex) }
            Divider()
            Button("上移") { vm.movePage(at: pageIndex, by: -1) }
                .disabled(pageIndex == 0)
            Button("下移") { vm.movePage(at: pageIndex, by: 1) }
                .disabled(pageIndex == vm.pageCount - 1)
        }
    }
}
