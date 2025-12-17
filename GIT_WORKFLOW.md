# 观己项目 Git 工作流程规范

## 🎯 核心原则

**这是我们的基地代码 (Base Code)** - 所有新功能开发都从这里开始。

## 📍 当前状态

- **主分支**: `main`
- **最新提交**: `e68bfcf - backup: pre-constitution v1.1 restructure`
- **架构**: Core/DataLayer/Features/UI (MVVM + Atomic Design)

## 🔄 标准工作流程

### 1️⃣ 开始新功能开发

```bash
cd guanji/guanji0.34

# 确保在最新的 main 分支
git checkout main
git status  # 确认工作区干净

# 创建功能分支（从当前基地代码分出）
git checkout -b feature/[功能名称]

# 示例：
git checkout -b feature/ai-conversation-enhancement
git checkout -b feature/timeline-optimization
git checkout -b feature/profile-insights
```

### 2️⃣ 开发过程中

```bash
# 频繁查看状态
git status

# 查看具体更改
git diff

# 添加文件（推荐逐个添加，保持提交清晰）
git add guanji0.34/Features/AIConversation/NewFeature.swift
git add guanji0.34/Core/Models/NewModel.swift

# 提交更改（使用语义化消息）
git commit -m "feat: 实现 AI 对话历史记录功能"

# 继续开发...
git add ...
git commit -m "test: 添加对话历史单元测试"
```

### 3️⃣ 功能完成后合并

```bash
# 确保功能分支所有更改已提交
git status  # 应该显示 "nothing to commit, working tree clean"

# 切换回 main
git checkout main

# 合并功能分支
git merge feature/ai-conversation-enhancement

# 删除已合并的功能分支（可选）
git branch -d feature/ai-conversation-enhancement

# 查看合并后的历史
git log --oneline -10
```

### 4️⃣ 紧急修复 (Hotfix)

```bash
# 从 main 创建修复分支
git checkout main
git checkout -b fix/critical-bug-name

# 修复问题
# ... 编辑文件 ...

# 提交修复
git add [修改的文件]
git commit -m "fix: 修复时间轴崩溃问题"

# 合并回 main
git checkout main
git merge fix/critical-bug-name
git branch -d fix/critical-bug-name
```

## 📝 提交消息规范

### 格式

```
<类型>: <简短描述>

[可选的详细说明]

[可选的关联信息]
```

### 类型标签

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 添加 Markdown 表格渲染支持` |
| `fix` | Bug 修复 | `fix: 修复消息气泡布局错位问题` |
| `refactor` | 重构 | `refactor: 优化 Profile 数据模型结构` |
| `docs` | 文档 | `docs: 更新 AI 对话模块文档` |
| `test` | 测试 | `test: 添加 DateUtilities 属性测试` |
| `style` | 代码格式 | `style: 统一代码缩进和命名` |
| `perf` | 性能优化 | `perf: 优化时间轴滚动性能` |
| `chore` | 构建/工具 | `chore: 更新 Xcode 项目配置` |
| `revert` | 回滚 | `revert: 回滚 AI 服务更改` |

### 示例

```bash
# 简单提交
git commit -m "feat: 实现代码语法高亮"

# 详细提交
git commit -m "feat: 实现代码语法高亮

- 添加 GuanjiSyntaxHighlighter 工具类
- 支持 Swift, Python, JavaScript 语法
- 集成到 RichTextRenderer 中
- 添加单元测试覆盖

关联: .kiro/specs/ai-rich-content-rendering/tasks.md"
```

## 🌿 分支命名规范

```
feature/[功能描述]     # 新功能
fix/[问题描述]         # Bug 修复
refactor/[重构内容]    # 代码重构
docs/[文档内容]        # 文档更新
test/[测试内容]        # 测试相关
```

### 示例

```
feature/ai-streaming-response
feature/profile-data-export
fix/timeline-memory-leak
fix/localization-missing-keys
refactor/repository-pattern
docs/api-documentation
test/property-based-tests
```

## 🔍 常用检查命令

```bash
# 查看当前状态
git status

# 查看提交历史
git log --oneline -10
git log --graph --oneline --all -20  # 图形化查看

# 查看具体文件的更改
git diff guanji0.34/Core/Models/AIConversationModels.swift

# 查看已暂存的更改
git diff --staged

# 查看某个提交的详情
git show <commit-hash>

# 查看文件的修改历史
git log --follow guanji0.34/Features/Timeline/TimelineScreen.swift

# 查看所有分支
git branch -a

# 查看当前分支
git branch --show-current
```

## ⚠️ 保护基地代码的规则

### ✅ 应该做的

1. **始终从 main 创建新分支**
2. **功能完成并测试通过后再合并**
3. **提交前运行测试**: `swift run_unit_tests.swift`
4. **提交前检查编译**: 在 Xcode 中确保无错误
5. **小步提交**: 每个逻辑单元单独提交
6. **有意义的提交消息**: 清晰描述做了什么
7. **更新文档**: 代码更改后同步更新 `Docs/` 目录

### ❌ 不应该做的

1. **不要直接在 main 上开发** - 始终使用功能分支
2. **不要提交未测试的代码** - 确保编译通过
3. **不要提交调试代码** - 移除 print 语句和临时代码
4. **不要提交大量无关更改** - 保持提交专注
5. **不要忘记 .gitignore** - 不提交用户特定文件
6. **不要强制推送** - 避免使用 `git push -f`

## 🛡️ 创建安全点 (Checkpoint)

在重大更改前创建标签：

```bash
# 创建带注释的标签
git tag -a v1.1-base -m "基地代码 v1.1 - 架构重组完成"

# 查看所有标签
git tag -l

# 查看标签详情
git show v1.1-base

# 如果需要回退到某个标签
git checkout v1.1-base
```

## 🔙 撤销操作

```bash
# 撤销工作区的更改（未 add）
git restore <文件>
git restore .  # 撤销所有

# 撤销暂存区的更改（已 add，未 commit）
git restore --staged <文件>

# 修改最后一次提交消息
git commit --amend -m "新的提交消息"

# 回退到上一个提交（保留更改）
git reset --soft HEAD~1

# 回退到上一个提交（丢弃更改，危险！）
git reset --hard HEAD~1

# 创建新提交来撤销某个提交
git revert <commit-hash>
```

## 📊 查看项目状态

```bash
# 查看简洁的状态
git status -s

# 查看分支和最后提交
git branch -v

# 查看未追踪的文件
git ls-files --others --exclude-standard

# 统计代码行数变化
git diff --stat

# 查看贡献者统计
git shortlog -sn
```

## 🔄 同步工作流程（如果有远程仓库）

```bash
# 查看远程仓库
git remote -v

# 添加远程仓库
git remote add origin <仓库地址>

# 推送到远程
git push origin main
git push origin feature/ai-conversation

# 从远程拉取
git pull origin main

# 获取远程更新（不合并）
git fetch origin
```

## 📋 每日工作流程示例

```bash
# 早上开始工作
cd guanji/guanji0.34
git status  # 检查状态
git checkout main  # 确保在 main 分支

# 开始新功能
git checkout -b feature/today-task

# 开发过程中（多次）
# ... 编辑代码 ...
git add [文件]
git commit -m "feat: 实现 XXX"

# ... 继续编辑 ...
git add [文件]
git commit -m "test: 添加 XXX 测试"

# 功能完成
swift run_unit_tests.swift  # 运行测试
# 在 Xcode 中编译确认无错误

# 合并到 main
git checkout main
git merge feature/today-task
git branch -d feature/today-task

# 查看今天的工作
git log --oneline --since="1 day ago"
```

## 🎯 最佳实践

1. **提交前三问**：
   - 代码能编译吗？
   - 测试通过了吗？
   - 文档更新了吗？

2. **提交粒度**：
   - 一个提交 = 一个逻辑单元
   - 不要混合多个不相关的更改

3. **分支生命周期**：
   - 功能分支应该短命（1-3天）
   - 完成后立即合并并删除

4. **代码审查**：
   - 合并前用 `git diff main..feature/xxx` 查看所有更改
   - 确保没有意外的文件被修改

5. **文档同步**：
   - 代码更改 → 更新 `Docs/` → 一起提交
   - 运行 `bash Docs/validate_docs.sh` 验证文档

## 🚨 紧急情况处理

### 误提交了敏感信息

```bash
# 修改最后一次提交
git commit --amend

# 如果已经推送，需要强制推送（谨慎！）
git push -f origin main
```

### 需要回到之前的状态

```bash
# 查看历史
git log --oneline

# 创建新分支保存当前状态
git branch backup-current

# 回退到指定提交
git reset --hard <commit-hash>
```

### 合并冲突

```bash
# 发生冲突时
git status  # 查看冲突文件

# 手动编辑冲突文件，解决冲突标记
# <<<<<<< HEAD
# =======
# >>>>>>> feature-branch

# 标记为已解决
git add <冲突文件>

# 完成合并
git commit
```

---

**版本**: v1.0  
**创建日期**: 2024-12-17  
**维护者**: 观己开发团队  
**状态**: 生效中

**记住**: Git 是你的时光机，善用它来保护我们的基地代码！
