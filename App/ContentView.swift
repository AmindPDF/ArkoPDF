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

            // 移除密码：确认对话框
            if vm.removePasswordConfirmPresented {
                AlertOverlay {
                    AlertDialog(icon: "lock.open",
                                tone: .warning,
                                title: "移除文档安全设置？",
                                message: "是否要移除当前文档的密码？\n此更改在您保存文档后才会生效。",
                                buttons: [
                                    AlertDialogButton("取消") { vm.cancelRemovePassword() },
                                    AlertDialogButton("确定", role: .primary) { vm.confirmRemoveSecurity() },
                                ])
                }
            }

            // 移除密码：完成对话框
            if vm.removePasswordDonePresented {
                AlertOverlay {
                    AlertDialog(icon: "checkmark",
                                tone: .success,
                                title: "已成功移除文档安全设置",
                                message: "安全设置需要在您保存文档后生效。\n文档关闭前你可以继续修改安全设置。",
                                buttons: [
                                    AlertDialogButton("稍后") { vm.dismissRemovePasswordDone() },
                                    AlertDialogButton("保存", role: .primary) { vm.saveAfterRemovePassword() },
                                ])
                }
            }
        }
    }
}
