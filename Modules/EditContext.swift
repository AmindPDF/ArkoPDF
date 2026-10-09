//  EditContext.swift
//  编辑模块（段落/文字/图片/链接）的类型与宿主能力协议。
//  对应 Windows 版 editcontent 模块对 IPDF_Paragraph / IPDF_PageObject / 链接标注的封装。

import AppKit

// MARK: - 类型

/// 段落排版样式操作（格式栏按钮 → 应用到当前选区）。
/// 加粗/斜体/下划线/删除线是「切换」语义（SDK SetBold 等按当前状态翻转）。
enum ParagraphStyle {
    case toggleBold
    case toggleItalic
    case toggleUnderline
    case toggleStrikeout
    case fontSize(Float)
    case textColor(UInt32)      // ARGB（0xAARRGGBB）
}

/// 段落编辑选区（画布高亮 + 格式栏状态；boxes 为 PDF 用户坐标）。
struct ParagraphSelection {
    let pageIndex: Int
    var startCaret: Int
    var endCaret: Int          // == startCaret 时为插入光标（无选区）
    var fontSize: Float
    var textColor: UInt32      // ARGB
    var isBold: Bool
    var isItalic: Bool
    var isUnderline: Bool
    var isStrikeout: Bool
    var boxes: [CGRect]
}

/// 图片对象选区。
struct ImageSelection {
    let pageIndex: Int
    let objectIndex: Int
    var bbox: CGRect           // 用户坐标（拖动/缩放时实时更新）
}

/// 链接目标。
enum LinkTarget {
    case url(String)
    case page(Int)             // 0-based 页
}

/// 待确认的链接拖拽结果（触发链接设置弹窗）。
struct LinkDraft: Identifiable {
    let pageIndex: Int
    let rect: CGRect
    var id: String {
        "\(pageIndex)-\(Int(rect.origin.x))-\(Int(rect.origin.y))-\(Int(rect.width))-\(Int(rect.height))"
    }
}

/// 图片编辑操作（EditBar / 右键菜单按钮）。
enum ImageOperation {
    case rotateLeft, rotateRight
    case flipHorizontal, flipVertical
    case delete
    case replace
    case export
    case sendToBack
    case bringToFront
}

/// ARGB 颜色工具（段落文字色用 0xAARRGGBB）。
enum ARGBColor {
    static func make(_ r: Int, _ g: Int, _ b: Int) -> UInt32 {
        0xFF000000 | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
    }
    static func rgb(_ argb: UInt32) -> (r: Int, g: Int, b: Int) {
        (Int((argb >> 16) & 0xFF), Int((argb >> 8) & 0xFF), Int(argb & 0xFF))
    }
}

// MARK: - 宿主能力协议

/// 编辑模块工具依赖的宿主能力（由 PDFEditorViewModel 实现）。
protocol EditContext: ToolContext {
    // ---- 段落 / 文字 ----
    /// 命中段落并进入编辑（点击处为插入光标）。返回 nil 表示该点无段落。
    @discardableResult
    func beginParagraphEdit(pageIndex: Int, point: CGPoint) -> ParagraphSelection?
    /// 在空白处新建段落（添加文字），返回新建后的编辑状态。
    @discardableResult
    func createParagraph(pageIndex: Int, point: CGPoint) -> ParagraphSelection?
    /// 拖拽选区：把 endCaret 更新到某点。
    func updateParagraphCaret(pageIndex: Int, point: CGPoint)
    /// 在当前光标/选区处插入文字（含撤销）。
    func insertText(_ text: String, pageIndex: Int)
    /// 删除当前选区（无选区则退格）。
    func deleteSelectionText(pageIndex: Int)
    /// 应用排版样式到当前选区（含撤销）。
    func applyParagraphStyle(_ style: ParagraphStyle, pageIndex: Int)
    /// 删除当前整个段落。
    func deleteWholeParagraph(pageIndex: Int)

    // ---- 图片 ----
    /// 命中图片对象并选中。返回 nil 表示该点无图片。
    @discardableResult
    func beginImageEdit(pageIndex: Int, point: CGPoint) -> ImageSelection?
    /// 拖动图片：实时更新预览矩形（不落盘，mouseUp 提交）。
    func updateImageDrag(pageIndex: Int, bbox: CGRect)
    /// 提交图片移动/缩放（含撤销）。
    func commitImageChange(pageIndex: Int, oldBBox: CGRect, newBBox: CGRect)
    /// 图片编辑操作（旋转/翻转/删除/替换/导出/置顶置底）。
    func applyImageOperation(_ op: ImageOperation, pageIndex: Int, objectIndex: Int)
    /// 添加图片（AddImageTool 选好文件后点击放置）。
    func addImage(path: String, pageIndex: Int, point: CGPoint)

    // ---- 链接 ----
    /// 链接拖拽草稿预览。
    func setLinkDraft(_ rect: CGRect?, pageIndex: Int)
    /// 拖拽结束后弹窗让用户填链接目标（URL / 页内跳转）。
    func promptLinkTarget(pageIndex: Int, rect: CGRect)
    /// 新建链接标注（含撤销）。
    func addLink(pageIndex: Int, rect: CGRect, target: LinkTarget)
}
