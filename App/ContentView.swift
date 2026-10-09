//  ContentView.swift
//  主布局：工具栏 + 侧栏/文档 + 状态栏。

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
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
    }
}
