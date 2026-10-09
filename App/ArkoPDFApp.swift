//  ArkoPDFApp.swift
//  App 入口：启动加载 PDSDK，菜单「打开 / 保存」。

import SwiftUI
import UniformTypeIdentifiers

@main
struct ArkoPDFApp: App {
    @StateObject private var vm = PDFEditorViewModel()

    init() {
        // 启动即加载 PDSDK。license 见 App/LicenseKey.swift（三个待补输入之一）。
        do {
            _ = try ArkoSDK.load(withLicense: LicenseKey.value)
        } catch {
            NSLog("ArkoPDF: SDK 加载失败 — \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .newItem) {
                Button("打开…") { open() }
                    .keyboardShortcut("o", modifiers: .command)

                Button("保存") { save() }
                    .keyboardShortcut("s", modifiers: .command)
            }

            // 撤销/重做（自定义 ArkoUndoManager，替换默认的 Cocoa undo/redo）
            CommandGroup(replacing: .undoRedo) {
                Button("撤销") { vm.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!vm.undoManager.canUndo)
                Button("重做") { vm.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!vm.undoManager.canRedo)
            }
        }
    }

    private func open() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            vm.open(url: url)
        }
    }

    private func save() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        if panel.runModal() == .OK, let url = panel.url {
            vm.save(to: url)
        }
    }
}
