//  SidebarView.swift
//  左侧栏：缩略图（大纲/书签/附件/图层延后）。

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("页面")
                    .font(.headline)
                Spacer()
            }
            .padding(10)
            Divider()
            ThumbnailView()
        }
        .frame(minWidth: 130, idealWidth: 170, maxWidth: 230)
    }
}
