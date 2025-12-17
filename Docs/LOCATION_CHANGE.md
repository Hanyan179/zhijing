# 文档位置变更说明

## 变更内容

文档目录已从 `guanji0.34/guanji0.34/Docs/` 移动到 `guanji0.34/Docs/`

## 变更原因

Xcode 项目使用 `PBXFileSystemSynchronizedRootGroup`，会自动将 `guanji0.34/guanji0.34/` 目录下的所有文件包含到编译中，导致：
- 所有 `.md` 文档文件被复制到 App bundle
- 产生 "Multiple commands produce" 编译错误

将文档移到项目外部（`guanji0.34/Docs/`）可以彻底避免这个问题。

## 新的文档路径

```
guanji/
└── guanji0.34/
    ├── Docs/              ← 文档在这里（项目外部）
    │   ├── INDEX.md
    │   ├── QUICK_START.md
    │   ├── features/
    │   ├── architecture/
    │   └── ...
    ├── guanji0.34/        ← App 源代码在这里
    │   ├── Features/
    │   ├── Core/
    │   └── ...
    └── guanji0.34.xcodeproj/
```

## 如何访问文档

### 在终端中
```bash
# 进入项目根目录
cd guanji/guanji0.34

# 查看文档
open Docs/INDEX.md

# 运行验证脚本
bash Docs/validate_docs.sh

# 运行测试
swift Docs/DocumentFormatTests.swift.script
```

### 在 Finder 中
直接打开 `guanji/guanji0.34/Docs/` 文件夹

## 优点

1. ✅ 不会被 Xcode 编译到 App 中
2. ✅ 不会产生文件冲突错误
3. ✅ 文档仍然在项目仓库中（可以 git 管理）
4. ✅ 更清晰的项目结构分离

## 注意事项

- 文档仍然是项目的一部分，会被 git 跟踪
- 所有文档链接已更新为相对路径，无需修改
- Steering 文件已更新新路径

---
**变更日期**: 2024-12-17  
**变更人**: Kiro AI Assistant
