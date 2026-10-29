//  ToolbarView.swift
//  顶部工具栏：模块段、工具、颜色、缩放、显示模式、翻页。

import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        HStack(spacing: 12) {
            // 模块段（阅读/标注/编辑/页面/保护/转换/工具）
            Picker("", selection: $vm.activeModuleKind) {
                ForEach(ModuleKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)
            .onChange(of: vm.activeModuleKind) { kind in vm.selectModule(kind) }

            Divider().frame(height: 20)

            // 当前模块的工具
            ToolPicker()

            // 标注颜色（仅标注模块显示）
            if vm.activeModuleKind == .annotate {
                Divider().frame(height: 20)
                MarkupColorPicker()
            }

            Spacer()

            // 撤销 / 重做
            Button(action: vm.undo) { Image(systemName: "arrow.uturn.backward") }
                .disabled(!vm.undoManager.canUndo)
                .help("撤销")
            Button(action: vm.redo) { Image(systemName: "arrow.uturn.forward") }
                .disabled(!vm.undoManager.canRedo)
                .help("重做")

            Divider().frame(height: 20)

            // 翻页
            Button(action: vm.goToPreviousPage) { Image(systemName: "chevron.up") }
            Button(action: vm.goToNextPage) { Image(systemName: "chevron.down") }

            Divider().frame(height: 20)

            // 缩放
            Button(action: vm.zoomOut) { Image(systemName: "minus.magnifyingglass") }
            Text("\(Int(vm.zoom * 100))%")
                .monospacedDigit()
                .frame(minWidth: 44)
            Button(action: vm.zoomIn) { Image(systemName: "plus.magnifyingglass") }
            Button("适合宽度") { vm.fitWidth() }

            Divider().frame(height: 20)

            // 显示模式
            Picker("", selection: $vm.displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct ToolPicker: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.activeModule?.tools ?? [], id: \.id) { tool in
                    Button {
                        vm.selectTool(tool)
                    } label: {
                        Image(systemName: tool.icon)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(vm.activeToolID == tool.id ? Color.accentColor.opacity(0.3) : Color.clear)
                    )
                    .help(tool.displayName)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MarkupColorPicker: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MarkupColor.allCases) { c in
                Button {
                    vm.markupColor = c
                } label: {
                    Circle()
                        .fill(color(c))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(vm.markupColor == c ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .help(c.displayName)
            }
        }
    }

    private func color(_ c: MarkupColor) -> Color {
        let (r, g, b) = c.rgb
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
