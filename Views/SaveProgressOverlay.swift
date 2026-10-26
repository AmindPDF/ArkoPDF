//  SaveProgressOverlay.swift
//  保存进度公共组件：进度条 + 取消按钮。所有保存操作（文档保存 / 相册保存等）共用。

import SwiftUI

/// 线程安全的取消标志（保存线程读、主线程写）。
final class SaveCancelFlag {
    private let lock = NSLock()
    private var _cancelled = false
    var isCancelled: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _cancelled }
        set { lock.lock(); _cancelled = newValue; lock.unlock() }
    }
}

/// 保存进度覆盖层：浮在内容上方，显示标题 + 进度条 + 取消。
struct SaveProgressOverlay: View {
    let title: String
    let progress: Double          // 0.0 ~ 1.0
    let isCancelable: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(title).font(.headline)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            if isCancelable {
                Button("取消") { onCancel() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(22)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.22), radius: 16, y: 5)
        )
    }
}
