//  EditorModule.swift
//  模块层：7 大模式（阅读/标注/编辑/页面/保护/转换/工具）。
//  一个模块 = 一组相关工具的容器，负责把鼠标事件分发给当前激活的工具。

import Foundation

/// 7 大模式，对应原型顶部 7 段式切换。
enum ModuleKind: String, CaseIterable, Identifiable {
    case reading  = "阅读"
    case annotate = "标注"
    case edit     = "编辑"
    case pages    = "页面"
    case protect  = "保护"
    case convert  = "转换"
    case tools    = "工具"

    var id: String { rawValue }
}

/// 模块协议。对应 Windows 的 module 层。
protocol EditorModule: AnyObject {
    var kind: ModuleKind { get }
    var displayName: String { get }
    var tools: [EditorTool] { get }
    var activeTool: EditorTool? { get set }

    func activate(context: ToolContext)
    func deactivate()
    /// 把一次鼠标事件分发给当前激活的工具。
    func route(_ phase: ToolPhase, _ event: ToolMouseEvent, context: ToolContext)
}

extension EditorModule {
    func activate(context: ToolContext) {}
    func deactivate() {}

    func route(_ phase: ToolPhase, _ event: ToolMouseEvent, context: ToolContext) {
        guard let tool = activeTool else { return }
        switch phase {
        case .down: tool.mouseDown(event, context: context)
        case .drag: tool.mouseDragged(event, context: context)
        case .up:   tool.mouseUp(event, context: context)
        }
    }
}
