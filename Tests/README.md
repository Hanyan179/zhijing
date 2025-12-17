# 测试文件目录

这个目录包含从 App 源代码中移出的单元测试文件。

## 为什么测试文件在这里？

项目使用 Xcode 的 `PBXFileSystemSynchronizedRootGroup` 特性，会自动将 `guanji0.34/` 目录下的所有 `.swift` 文件包含到 App target 中。

测试文件需要 `XCTest` 框架，但该框架只在 Test target 中可用。为了避免编译错误，测试文件被移到项目外部。

## 测试文件列表

- `AIConversationModelsTests.swift` - AI 对话模型测试
- `AISettingsTests.swift` - AI 设置测试
- `DateUtilitiesTests.swift` - 日期工具测试
- `InputAtomsTests.swift` - 输入原子组件测试
- `InsightRepositoryTests.swift` - 洞察仓库测试
- `MarkdownParserTests.swift` - Markdown 解析器测试
- `MessageBubbleTests.swift` - 消息气泡测试
- `ProfileInsightModelsTests.swift` - 用户画像洞察模型测试
- `RichTextRendererTests.swift` - 富文本渲染器测试
- `SyntaxHighlighterTests.swift` - 语法高亮测试

## 如何运行测试？

### 方案 1：创建 Test Target（推荐）

1. 在 Xcode 中：File → New → Target → Unit Testing Bundle
2. 将这些测试文件添加到新的 Test target
3. 使用 Cmd+U 运行测试

### 方案 2：使用 Swift Package Manager

创建 `Package.swift` 并配置测试：

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "guanji0.34",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "GuanjiCore", targets: ["GuanjiCore"])
    ],
    targets: [
        .target(name: "GuanjiCore", path: "guanji0.34"),
        .testTarget(
            name: "GuanjiTests",
            dependencies: ["GuanjiCore"],
            path: "Tests"
        )
    ]
)
```

然后运行：
```bash
swift test
```

### 方案 3：临时运行单个测试

```bash
# 使用 swift 命令直接运行（需要配置依赖）
swift Tests/AISettingsTests.swift
```

## 未来改进

建议为项目添加正式的 Test target，这样可以：
- 在 Xcode 中正常运行测试
- 使用测试导航器查看测试结果
- 集成 CI/CD 测试流程
- 查看代码覆盖率报告

---
**创建日期**: 2024-12-17  
**原因**: 避免 App target 编译测试文件导致的 XCTest 错误
