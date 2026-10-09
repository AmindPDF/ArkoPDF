//  OutlineListView.swift
//  大纲面板：书签树（扁平缩进列表），点击跳页，右键菜单编辑（重命名/添加子项/删除）。

import SwiftUI

struct OutlineListView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    @State private var renameItem: OutlineItem?
    @State private var renameText = ""
    @State private var addUnderItem: OutlineItem?
    @State private var addUnderActive = false
    @State private var addText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 顶部：添加根级书签
            HStack {
                Spacer()
                Button {
                    addUnderItem = nil
                    addUnderActive = true
                    addText = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("添加根级书签")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                if vm.outline.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.indent")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("暂无大纲")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(vm.outline) { item in
                            OutlineRow(item: item,
                                       onRename: { renameItem = item; renameText = item.title },
                                       onAddChild: { addUnderItem = item; addUnderActive = true; addText = "" },
                                       onDelete: { vm.removeOutlineItem(item) })
                        }
                    }
                    .padding(8)
                }
            }
        }
        .alert("重命名", isPresented: Binding(get: { renameItem != nil }, set: { if !$0 { renameItem = nil } })) {
            TextField("标题", text: $renameText)
            Button("确定") { if let it = renameItem { vm.renameOutlineItem(it, title: renameText) } }
            Button("取消", role: .cancel) {}
        }
        .alert("添加子项", isPresented: $addUnderActive) {
            TextField("标题", text: $addText)
            Button("确定") { vm.addOutlineItem(title: addText, under: addUnderItem) }
            Button("取消", role: .cancel) {}
        }
    }
}

private struct OutlineRow: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let item: OutlineItem
    let onRename: () -> Void
    let onAddChild: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(item.title)
                .font(.caption)
                .lineLimit(1)
                .padding(.leading, CGFloat(item.level) * 14)
            Spacer()
            if item.page >= 0 {
                Text("\(item.page + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(vm.currentPage == item.page ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .onTapGesture {
            if item.page >= 0 { vm.currentPage = item.page }
        }
        .contextMenu {
            Button("重命名") { onRename() }
            Button("添加子项") { onAddChild() }
            Divider()
            Button("删除", role: .destructive) { onDelete() }
        }
    }
}
