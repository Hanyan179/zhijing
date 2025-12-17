# 测试文件移动说明

## 问题

项目中的测试文件（`*Tests.swift`）导入了 `XCTest` 框架，但它们被包含在 App target 中编译，导致错误：
```
Compilation search paths unable to resolve module dependency: 'XCTest'
```

## 原因

- 项目使用 `PBXFileSystemSynchronizedRootGroup`，自动包含所有 `.swift` 文件
- 项目没有配置单独的 Test target
- `XCTest` 框架只在 Test target 中可用，App target 无法访问

## 解决方案

将所有测试文件移动到 `Tests/` 目录（项目外部），避免被 Xcode 自动包含到 App target。

### 已移动的测试文件

所有测试文件已移动到 `Tests/` 目录（项目外部）：

```
Tests/RichTextRendererTests.swift
Tests/InputAtomsTests.swift
Tests/AIConversationModelsTests.swift
Tests/AISettingsTests.swift
Tests/ProfileInsightModelsTests.swift
Tests/DateUtilitiesTests.swift
Tests/MarkdownParserTests.swift
Tests/SyntaxHighlighterTests.swift
Tests/MessageBubbleTests.swift
Tests/InsightRepositoryTests.swift
```

## 如何重新启用测试

### 方案 1：创建 Test Target（推荐）

1. 在 Xcode 中创建新的 Unit Test target
2. 将 `.swift.disabled` 文件重命名回 `.swift`
3. 将这些测试文件添加到 Test target（不要添加到 App target）

### 方案 2：使用 Swift Package Manager

创建一个独立的测试包，在包中运行测试。

### 方案 3：临时启用单个测试

```bash
# 重命名单个测试文件
mv Core/Models/AISettingsTests.swift.disabled Core/Models/AISettingsTests.swift

# 使用 swift test 运行（需要配置 Package.swift）
swift test

# 运行后重新禁用
mv Core/Models/AISettingsTests.swift Core/Models/AISettingsTests.swift.disabled
```

## 注意事项

- 这些测试文件仍然在项目中，只是不会被编译
- 代码仍然可以被 git 跟踪
- 如果需要运行测试，必须先配置 Test target

## 未来改进

建议为项目添加正式的 Test target，这样可以：
- 正常运行单元测试
- 使用 Xcode 的测试导航器
- 集成 CI/CD 测试流程
- 查看测试覆盖率

---
**禁用日期**: 2024-12-17  
**原因**: 避免 XCTest 导入错误
