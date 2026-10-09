//  AnnotationListView.swift
//  标注面板：列出当前文档所有标注，支持跳转、改色、删除。

import SwiftUI

struct AnnotationListView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView {
            if vm.annotations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "highlighter")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("暂无标注")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(vm.annotations) { item in
                        AnnotationRow(item: item)
                    }
                }
                .padding(12)
            }
        }
    }
}

private struct AnnotationRow: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    let item: AnnotationItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.type.icon)
                .foregroundColor(swatch(item.color))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.type.displayName)
                    .font(.caption)
                Text(item.pageLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 改色
            Menu {
                ForEach(MarkupColor.allCases) { c in
                    Button(c.displayName) {
                        vm.changeAnnotationColor(item, to: c)
                    }
                }
            } label: {
                Circle()
                    .fill(swatch(item.color))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
            }
            .frame(width: 20)

            // 删除
            Button {
                vm.deleteAnnotation(item)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .help("删除标注")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.12))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.currentPage = item.pageIndex  // 点击跳转到该页
        }
    }

    private func swatch(_ c: MarkupColor) -> Color {
        Color(red: Double(c.rgb.r) / 255, green: Double(c.rgb.g) / 255, blue: Double(c.rgb.b) / 255)
    }
}
