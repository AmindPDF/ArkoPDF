//  SidebarView.swift
//  左侧栏：页面（缩略图）/ 标注（列表面板）两个标签页。

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var vm: PDFEditorViewModel
    @State private var tab: SidebarTab = .pages

    private enum SidebarTab: String, CaseIterable, Identifiable {
        case pages = "页面"
        case annotations = "标注"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(SidebarTab.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            if tab == .pages {
                ThumbnailView()
            } else {
                AnnotationListView()
            }
        }
        .frame(minWidth: 130, idealWidth: 170, maxWidth: 230)
    }
}
