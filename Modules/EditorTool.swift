//  EditorTool.swift
//  工具层 + 工具上下文。工具 = 一个鼠标状态机（down/drag/up）。
//  ToolContext 把工具与具体视图/ViewModel 解耦。

import AppKit

/// 鼠标事件阶段。
enum ToolPhase {
    case down, drag, up
}

/// 一次鼠标事件的上下文：目标页 + PDF 用户坐标点（左下原点）。
struct ToolMouseEvent {
    let pageIndex: Int
    let point: CGPoint
    let modifiers: NSEvent.ModifierFlags
}

/// 当前文本选区（字符矩形为 PDF 用户坐标）。
struct TextSelection {
    let pageIndex: Int
    let startCaret: Int
    let endCaret: Int
    let charBoxes: [CGRect]
}

/// 工具依赖的宿主能力（由 PDFEditorViewModel 实现）。
/// 对应 Windows 的 pageview 上下文。
protocol ToolContext: AnyObject {
    var currentPageIndex: Int { get }
    var markupColor: MarkupColor { get }
    var markupOpacity: Float { get }

    func page(at index: Int) -> ArkoPage?
    func setSelection(_ selection: TextSelection?)
    /// 由某个 AnnotHandler 把选中矩形落成标注，并失效该页缓存触发重绘。
    func applyMarkup(_ handler: AnnotHandler, lineBoxes: [CGRect], pageIndex: Int)

    // 页面组织操作（PPO）
    func insertBlankPage(after index: Int)
    func deletePage(at index: Int)
    func rotatePageClockwise90(at index: Int)
    func movePage(at index: Int, by offset: Int)
}

/// 工具协议。对应 Windows 的 tool 层。
protocol EditorTool: AnyObject {
    var id: String { get }
    var displayName: String { get }
    /// SF Symbol 名。
    var icon: String { get }

    func mouseDown(_ event: ToolMouseEvent, context: ToolContext)
    func mouseDragged(_ event: ToolMouseEvent, context: ToolContext)
    func mouseUp(_ event: ToolMouseEvent, context: ToolContext)
    func reset()

    /// 工具被选中时触发（动作型工具，如页面管理，用它执行一次性操作）。
    func activated(context: ToolContext)
}

extension EditorTool {
    func activated(context: ToolContext) {}
}
