# Xcode 编译问题修复说明

## 问题描述

Xcode 报错：
```
Multiple commands produce '/Users/hansen/.../guanji0.34.app/README.md'
Multiple commands produce '/Users/hansen/.../guanji0.34.app/.gitkeep'
```

## 根本原因

Xcode 项目使用了 `PBXFileSystemSynchronizedRootGroup`，会自动将 `guanji0.34` 目录下的所有文件包含到编译中，包括：
- 文档文件（`.md`）
- 测试脚本（`.swift`）
- 占位文件（`.gitkeep`）

这些文件不应该被编译到 App 中。

## 解决方案

### 1. 删除 `.gitkeep` 文件
删除了所有 `Docs/` 子目录下的 `.gitkeep` 占位文件，因为这些目录已经有实际内容。

### 2. 重命名测试脚本
将所有 Swift 测试脚本重命名为 `.swift.script` 扩展名：
- `DocumentFormatTests.swift` → `DocumentFormatTests.swift.script`
- `RunPropertyTests.swift` → `RunPropertyTests.swift.script`
- `run_all_tests.swift` → `run_all_tests.swift.script`

这些脚本仍然可以通过 `swift` 命令运行：
```bash
swift Docs/DocumentFormatTests.swift.script
```

### 3. 重命名 README.md 文件
将文档目录中的 `README.md` 重命名为 `INDEX.md`：
- `Docs/README.md` → `Docs/INDEX.md`
- `Docs/components/README.md` → `Docs/components/INDEX.md`

同时批量更新了所有文档中的链接引用。

## 验证修复

在 Xcode 中重新编译项目，应该不再出现 "Multiple commands produce" 错误。

## 注意事项

1. **不要将测试脚本改回 `.swift` 扩展名**
2. **不要创建新的 `README.md` 文件在 Docs 目录下**
3. **如果需要添加新的文档索引，使用 `INDEX.md` 命名**

## 相关文件

- `README_TESTS.md` - 测试脚本使用说明
- `INDEX.md` - 文档中心入口
- `components/INDEX.md` - 组件文档索引

---
**修复日期**: 2024-12-17  
**修复人**: Kiro AI Assistant
