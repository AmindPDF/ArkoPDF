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
    let clickCount: Int
}

/// 当前文本选区（字符矩形为 PDF 用户坐标）。
struct TextSelection {
    let pageIndex: Int
    let startCaret: Int
    let endCaret: Int
    let charBoxes: [CGRect]
}

/// 图形标注的拖拽草稿（用于画布预览）。
struct DraftShape {
    let pageIndex: Int
    let type: ShapeType
    let points: [CGPoint]
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

    // 图形 / 便签标注
    func addShapeAnnot(_ type: ShapeType, points: [CGPoint], pageIndex: Int)
    func addNoteAnnot(at point: CGPoint, pageIndex: Int)
    func setDraft(_ draft: DraftShape?)
    // 测量 / FreeText 变体 / 图章 / 附件 / 音视频（经 GraphicAnnotHandler）
    func addGraphicShapeAnnot(_ handler: GraphicAnnotHandler, points: [CGPoint], pageIndex: Int)
    func addGraphicRectAnnot(_ handler: GraphicAnnotHandler, rect: CGRect, target: CGPoint?, pageIndex: Int)

    // 页面组织操作（PPO）
    func insertBlankPage(after index: Int)
    func deletePage(at index: Int)
    func rotatePageClockwise90(at index: Int)
    func movePage(at index: Int, by offset: Int)
    /// 弹出页面组织高级操作（提取/插入/替换）。
    func showPageSheet(_ kind: PageSheetKind)
    /// 弹出相册排版（PhotoBook）。
    func showPhotoBook()
    /// 弹出添加密码下拉菜单。
    func showPasswordMenu()
    /// 移除文档安全设置。
    func removeSecurity()
    /// 弹出签名对话框（创建签名后点击页面放置）。
    func showSignSheet()
    /// 密文：拖拽框选实时预览矩形（nil 清除）。
    func setRedactionDraft(_ rect: CGRect?, pageIndex: Int)
    /// 添加密文标记（rects 为 PDF 用户坐标）。
    func markRedaction(rects: [CGRect], pageIndex: Int)
    /// 弹出数字签名对话框（选证书 → 签名文档）。
    func showSignDoc()
    /// 弹出压缩（优化）对话框。
    func showCompress()
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
