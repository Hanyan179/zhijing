# Git 快速参考卡片

## 🎯 基地代码信息

- **当前版本**: v1.1-base (commit: 969c763)
- **分支**: main
- **状态**: 干净的工作区 ✅

## 🚀 日常开发快速命令

### 开始新功能

```bash
cd guanji/guanji0.34
git checkout -b feature/功能名称
```

### 提交更改

```bash
git add [文件]
git commit -m "feat: 描述"
```

### 完成功能

```bash
git checkout main
git merge feature/功能名称
git branch -d feature/功能名称
```

### 查看状态

```bash
git status              # 查看当前状态
git log --oneline -10   # 查看历史
git diff                # 查看更改
```

## 📝 提交类型

| 类型 | 用途 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | Bug 修复 |
| `refactor:` | 重构 |
| `docs:` | 文档 |
| `test:` | 测试 |
| `chore:` | 构建/工具 |

## 🔙 撤销操作

```bash
git restore <文件>              # 撤销工作区更改
git restore --staged <文件>    # 撤销暂存
git reset --soft HEAD~1        # 撤销最后一次提交（保留更改）
```

## 🏷️ 标签管理

```bash
git tag -l                     # 查看所有标签
git show v1.1-base            # 查看标签详情
git checkout v1.1-base        # 回到标签版本
```

## ⚠️ 提交前检查清单

- [ ] 代码能编译？
- [ ] 测试通过？(`swift run_unit_tests.swift`)
- [ ] 文档更新？
- [ ] 本地化字符串添加？
- [ ] 无调试代码？

## 📖 详细文档

查看 `GIT_WORKFLOW.md` 获取完整的 Git 工作流程说明。

---

**快速帮助**: 遇到问题？运行 `git status` 查看当前状态
