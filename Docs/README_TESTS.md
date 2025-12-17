# 文档测试脚本说明

## 测试脚本文件

为了避免 Xcode 编译错误，所有 Swift 测试脚本都使用 `.swift.script` 扩展名：

- `DocumentFormatTests.swift.script` - 完整的属性测试套件
- `RunPropertyTests.swift.script` - 属性测试运行器
- `run_all_tests.swift.script` - 运行所有测试

## 运行测试

### 快速验证（Shell 脚本）

```bash
# 在 guanji/guanji0.34/guanji0.34 目录下运行
bash Docs/validate_docs.sh
```

### 完整属性测试（Swift 脚本）

```bash
# 在 guanji/guanji0.34/guanji0.34 目录下运行
swift Docs/DocumentFormatTests.swift.script
```

## 为什么使用 .swift.script 扩展名？

Xcode 项目使用 `PBXFileSystemSynchronizedRootGroup`，会自动包含所有 `.swift` 文件进行编译。测试脚本不应该被编译到 App 中，因此使用 `.swift.script` 扩展名来避免被 Xcode 自动包含。

这些脚本仍然可以通过 `swift` 命令直接运行，因为它们包含 shebang (`#!/usr/bin/env swift`)。

## 注意事项

- 不要将这些脚本重命名回 `.swift` 扩展名
- 如果需要修改测试脚本，请编辑 `.swift.script` 文件
- 所有测试脚本都应该保持可执行权限 (`chmod +x`)
