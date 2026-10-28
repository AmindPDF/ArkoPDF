//  StatusBarView.swift
//  底部状态栏。

import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        HStack {
            if let a = vm.hoveredAnnotation {
                HStack(spacing: 4) {
                    Image(systemName: a.typeIcon)
                    Text("标注：\(a.typeName) · \(a.color.displayName)")
                }
            } else {
                Text("就绪")
            }
            Spacer()
            Text("\(Int(vm.zoom * 100))%")
                .monospacedDigit()
            Spacer()
            Text("第 \(vm.currentPage + 1) / \(vm.pageCount) 页")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.bar)
    }
}
