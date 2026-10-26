//  ContentView.swift
//  主布局：工具栏 + 侧栏/文档 + 状态栏。

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ToolbarView()
                Divider()
                HSplitView {
                    SidebarView()
                    PDFDocumentView()
                }
                Divider()
                StatusBarView()
            }
            .frame(minWidth: 960, minHeight: 640)

            // 保存进度覆盖层
            if vm.isSaving {
                SaveProgressOverlay(title: vm.saveTitle,
                                    progress: vm.saveProgress,
                                    isCancelable: true) { vm.cancelSave() }
            }
        }
    }
}
