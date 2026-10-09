# ArkoPDF — 原生 macOS PDF 编辑器（第一版 / MVP）

基于贵方 **PDSDK**（PDFium 系 C++ SDK）的原生 macOS SwiftUI 实现。本仓库交付 **Swift + Objective-C++ 源码 + 构建说明**，需在 Mac（Xcode）上构建。

## 架构分层

```
SwiftUI（纯 UI / 状态）
   │  ArkoPDF-Bridging-Header.h 暴露 Bridge/*.h
   ▼
Swift 模块化层：
   EditorModule（7 大模式：阅读/标注/编辑/页面/保护/转换/工具）
   └── EditorTool（鼠标状态机：选择/高亮/下划线/删除线 …）
       └── AnnotHandler（真正落标注：高亮/下划线/删除线处理器）
   ToolContext（由 PDFEditorViewModel 实现，解耦工具与视图）
   │
   ▼
Objective-C++ 桥接层（Bridge/*.mm，封装 C++ SDK，含 DIBitmap→CGImage）
   │  #include "ipdf_*.h"（来自 ArkoPDFCore/sdk/include）
   ▼
PDSDK 静态库（libPDSDK.a + libPDFium.a）
```

- `EditorModule` = 一个模式，持有一组工具，把鼠标事件分发给激活工具（`Modules/`）。
- `EditorTool` = 一个鼠标状态机（down/drag/up），如 `SelectTextTool`、`HighlightTool`、`UnderlineTool`、`StrikeoutTool`（`Modules/Tools/`）。
- `AnnotHandler` = 底层落标注的处理器，标注模块各注释工具复用「选文本→按行合并→落标注」流程，仅绑定不同 Handler（`Modules/AnnotHandler.swift`）。
- `ToolContext` = 工具依赖的宿主能力，由 `PDFEditorViewModel` 实现，把工具与具体视图解耦。

> 编辑模块的「段落编辑 / 添加段落 / 图片修改」等工具已按此分层**占位**（`StubTool`），待接入 SDK 对应能力时逐个填充，无需改架构。

## 目录结构

```
ArkoPDF/
├── README.md
├── project.yml                     # 可选：XcodeGen 配置
├── ArkoPDF-Bridging-Header.h       # 把 Bridge/*.h 暴露给 Swift
├── （SDK 头文件与静态库在上级 ArkoPDFCore/、ArkoPDFCore-macOS/，见「SDK 依赖」一节）
├── App/                            # ArkoPDFApp / ContentView / LicenseKey
├── ViewModel/                      # PDFEditorViewModel（单一状态源，实现 ToolContext）
├── Views/                          # 文档视图 / 缩略图 / 侧栏 / 工具栏 / 状态栏
├── Modules/                        # 模块化层（协议 + 7 模块 + 工具 + 处理器）
│   ├── EditorModule.swift
│   ├── EditorTool.swift
│   ├── AnnotHandler.swift
│   ├── TextSelectionTool.swift
│   ├── StubTool.swift
│   ├── Tools/                      # SelectTextTool / MarkupTools
│   └── Modules/                    # Reading/Annotate/Edit/Pages/Protect/Convert/Tools
└── Bridge/                         # Objective-C++ 桥接层
    ├── ArkoSDK.h/.mm               # PDF_LoadSDK / PDF_UnLoadSDK
    ├── ArkoDocument.h/.mm          # 打开/关闭/页数/取页/保存
    ├── ArkoPage.h/.mm              # 渲染 + 文本选择 + 标注（每页适配器）
    └── ArkoBitmap.h/.mm            # IPDF_DIBitmap → CGImage
```

## SDK 依赖（已内置，无需再补）

PDSDK 的编译产物已直接放进本仓库的 `SDK/` 目录，App **自包含**：

```
ArkoPDF/
├── SDK/
│   ├── include/                    #   ipdf_*.h 头文件
│   └── lib/
│       ├── libPDSDK.a              #   PDSDK 业务层（universal）
│       └── libPDFium.a             #   PDFium 核心引擎（universal）
├── App/  ViewModel/  Views/  Modules/  Bridge/   # 应用源码
└── ...
```

> 两个 `.a` 是 universal（arm64 + x86_64）。**链接顺序**：`libPDSDK.a` 在前、`libPDFium.a` 在后（PDSDK 依赖 PDFium）。

license key 已在 `App/LicenseKey.swift` 填好（与 Windows 版复用同一 key）。

---

## 方式 A：手动建工程（无需额外工具）

1. 把整个 `ArkoPDF/` 目录拷到 Mac。
2. Xcode → **New Project → macOS ▸ App**，名 **ArkoPDF**，Interface **SwiftUI**，Language **Swift**，**把工程建在 `ArkoPDF/` 目录内**（这样 `$(SRCROOT)` 就是 `ArkoPDF/`，`Bridge/`、`App/` 等子目录都在它下面）。
3. 把下面这些**文件夹**拖进工程（右侧 Target 勾选 ArkoPDF，**勾选「Copy items if needed」**）：
   - `App/`、`ViewModel/`、`Views/`、`Modules/`、`Bridge/`（源码）
   - 根目录的 `ArkoPDF-Bridging-Header.h`
   - `SDK/`（头文件 + `.a`，只需引用，无需参与编译）
4. **Bridging header**：Target ▸ Build Settings ▸ `Objective-C Bridging Header` = `ArkoPDF-Bridging-Header.h`。
5. **头文件搜索**：`Header Search Paths` 加两行：
   - `$(SRCROOT)`（让 bridging header 的 `#import "Bridge/..."` 能找到）
   - `$(SRCROOT)/SDK/include`（让 `.mm` 的 `#include "ipdf_*.h"` 能找到）
6. **链接静态库**（两个都要，顺序 `libPDSDK.a` 在前、`libPDFium.a` 在后）：
   - Target ▸ Build Phases ▸ **Link Binary With Libraries** → `Add Other…` → 依次选 `SDK/lib/libPDSDK.a` 和 `SDK/lib/libPDFium.a`
   - 或 `Other Linker Flags` 加两行：`$(SRCROOT)/SDK/lib/libPDSDK.a`、`$(SRCROOT)/SDK/lib/libPDFium.a`
   - `Library Search Paths` 加 `$(SRCROOT)/SDK/lib`
7. **C++ 设置**：`C++ Language Dialect` = `GNU++17`；`C++ Standard Library` = `libc++`；`Enable C++ Exceptions` = Yes（`.mm` 文件 Xcode 自动按 Objective-C++ 编译，无需改）。
8. **系统框架**（Link Binary With Libraries 加）：`AppKit`、`Foundation`、`CoreGraphics`、`CoreText`、`Carbon`、`Security`（SDK 头引 `<Carbon/Carbon.h>`，数字签名用 Security）。若链接报缺 `ImageIO` 等，按报错补。
9. `Enable Bitcode` = **No**。
10. （可选）App Sandbox：若开启，勾选 **User Selected File: Read/Write**；本 MVP 建议先**不开** Sandbox，便于直接读写文件。
11. ⌘R 运行。

## 方式 B：XcodeGen 一键生成（可选）

```bash
brew install xcodegen
cd ArkoPDF
# SDK 头文件与两个静态库已内置在 SDK/ 目录，直接生成即可
xcodegen generate
open ArkoPDF.xcodeproj
```

`project.yml` 已固化上述所有设置。

## 验证清单（Mac 上）

1. ⌘R 编译通过（首次可能有少量 Xcode 版本 / SDK 头文件差异，报错贴回我来修）。
2. ⌘O 打开 PDF，页面正常渲染。
3. 翻页、缩放、适合宽度、单页/连续切换、缩略图点击跳页正常。
4. 「标注」模块 → 选「高亮」工具，拖选文字出现选区，松手落黄色高亮；切「下划线」「删除线」及颜色生效。
5. ⌘S 保存后重新打开，标注仍在。

## 已知说明

- **渲染为同步**：`IPDF_RenderContext` 按需渲染并 `NSCache` 缓存；大文件可后续接 `IPDF_ProgressiveRenderer` + 后台队列异步化。
- **保存链**：`GetPage→GenerateContent()` → `IPDF_Creator::Init(doc, PDF_CREATE_NO_ORIGINAL)` → `Create(utf8 路径, NULL, NULL)`。当前对所有页 `GenerateContent()`，可后续优化为仅脏页。
- **对象所有权**：桥接层严格按 SDK「Getter/工厂返回对象由调用方 Release」规则配对（`IPDF_Page`/`IPDF_PageText`/`IPDF_AnnotList` 缓存后各 Release 一次；`IPDF_Document` 经 `PDSDK_ReleaseDocument`）。
- SDK 头文件在 macOS 引了已废弃的 Carbon/OSAtomic，会出 **deprecation 警告**，属正常，勿开 `-Werror`。
