//  UndoManager.swift
//  应用层撤销/重做（命令模式）：每个操作封装 Undo/Redo 闭包，栈管理。
//  SDK 仅支持文本编辑的 ParaUndo，标注/页面组织等撤销由这里实现。

import Foundation

/// 一个可撤销的操作。undo/redo 闭包接收 ViewModel 上下文，内部只做「原始」操作
/// （不注册新撤销项），由 ViewModel.performUndoRedo 统一刷新界面。
struct UndoItem {
    let description: String
    let undo: (PDFEditorViewModel) -> Void
    let redo: (PDFEditorViewModel) -> Void
    /// 丢弃时释放资源（如页面句柄克隆）。
    let dispose: (() -> Void)?

    init(description: String,
         undo: @escaping (PDFEditorViewModel) -> Void,
         redo: @escaping (PDFEditorViewModel) -> Void,
         dispose: (() -> Void)? = nil) {
        self.description = description
        self.undo = undo
        self.redo = redo
        self.dispose = dispose
    }
}

/// 撤销/重做栈。
final class ArkoUndoManager {
    private(set) var undoStack: [UndoItem] = []
    private(set) var redoStack: [UndoItem] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func register(_ item: UndoItem) {
        undoStack.append(item)
        // 清空重做栈并释放被丢弃项的资源
        for dropped in redoStack { dropped.dispose?() }
        redoStack.removeAll()
        // 限制深度：移除最旧的项并释放资源
        if undoStack.count > 100 {
            let dropped = undoStack.removeFirst()
            dropped.dispose?()
        }
    }

    func undo(context: PDFEditorViewModel) {
        guard let item = undoStack.popLast() else { return }
        item.undo(context)
        redoStack.append(item)
    }

    func redo(context: PDFEditorViewModel) {
        guard let item = redoStack.popLast() else { return }
        item.redo(context)
        undoStack.append(item)
    }

    func reset() {
        for item in undoStack { item.dispose?() }
        for item in redoStack { item.dispose?() }
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
