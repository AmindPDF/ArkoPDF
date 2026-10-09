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
}

/// 撤销/重做栈。
final class ArkoUndoManager {
    private(set) var undoStack: [UndoItem] = []
    private(set) var redoStack: [UndoItem] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func register(_ item: UndoItem) {
        undoStack.append(item)
        redoStack.removeAll()
        if undoStack.count > 100 { undoStack.removeFirst() }
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
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
