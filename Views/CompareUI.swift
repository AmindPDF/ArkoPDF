//  CompareUI.swift
//  文档对比：汇总结果对话框。

import SwiftUI

struct CompareSummarySheet: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("文档对比结果").font(.headline).padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if vm.compareDiffs.isEmpty {
                        Text("未发现差异。").foregroundColor(.secondary)
                    } else {
                        Text("共 \(vm.compareDiffs.count) 页有差异")
                            .font(.system(size: 12.5)).foregroundColor(.secondary)
                            .padding(.bottom, 4)

                        ForEach(vm.compareDiffs, id: \.pageIndex) { diff in
                            Button {
                                vm.currentPage = diff.pageIndex
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Text("第 \(diff.pageIndex + 1) 页")
                                    Spacer()
                                    Text("删除 \(diff.deletedCount) · 新增 \(diff.addedCount)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.system(size: 13))
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
                .padding(16)
            }

            Divider()
            HStack {
                Spacer()
                Button("结束对比") { vm.endCompare(); dismiss() }
                Button("关闭") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 440, height: 460)
    }
}
