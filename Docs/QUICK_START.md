# 文档系统快速入门

> 返回 [文档中心](./INDEX.md)

## 🎯 核心原则

**开发前查文档，开发后更文档**

这个简单的原则能帮助团队：
- 避免重复造轮子
- 保持代码一致性
- 提高开发效率
- 降低维护成本

## 📖 开发前：如何查找文档

### 场景 1: 我要开发一个新功能

1. **查看功能地图** → [overview/feature-map.md](overview/feature-map.md)
   - 了解现有功能模块
   - 确定新功能的位置

2. **查看相关功能文档** → [features/](features/)
   - 了解类似功能的实现方式
   - 学习现有的设计模式

3. **查看架构文档** → [architecture/](architecture/)
   - 了解 MVVM 架构规范
   - 了解数据流和分层结构

### 场景 2: 我要修改现有功能

1. **找到功能文档** → [features/](features/)
   - 了解功能的当前实现
   - 查看相关的数据模型和接口

2. **查看数据模型** → [data/](data/)
   - 了解数据结构定义
   - 了解模型之间的关系

3. **查看 API 文档** → [api/](api/)
   - 了解 Repository 接口
   - 了解 Service 接口

### 场景 3: 我要使用 UI 组件

1. **查看组件文档** → [components/](components/)
   - Atoms: 基础组件（按钮、输入框等）
   - Molecules: 复合组件（卡片、列表项等）
   - Organisms: 复杂组件（输入面板、共鸣中心等）

2. **查看代码示例**
   - 每个组件文档都包含使用示例
   - 参考现有功能的使用方式

## ✏️ 开发后：如何更新文档

### 更新流程

```
代码修改 → 更新文档 → 运行验证 → 提交代码
```

### 具体步骤

#### 1. 确定需要更新的文档

| 你修改了... | 需要更新... |
|-----------|-----------|
| 数据模型 (Core/Models/*.swift) | [data/](data/) 目录下对应的文档 |
| Repository (DataLayer/Repositories/*.swift) | [api/repositories.md](api/repositories.md) |
| Service (DataLayer/SystemServices/*.swift) | [api/services.md](api/services.md) |
| 功能模块 (Features/*/) | [features/](features/) 目录下对应的文档 |
| UI 组件 (UI/*/) | [components/](components/) 目录下对应的文档 |
| 架构调整 | [architecture/](architecture/) 目录下对应的文档 |

#### 2. 更新文档内容

确保文档包含：
- ✅ 顶部导航链接（根据文档位置调整路径）
- ✅ 清晰的章节结构
- ✅ 代码示例（如果适用）
- ✅ 底部元数据：

```markdown
---
**版本**: v1.x.x  
**作者**: [你的名字]  
**更新日期**: YYYY-MM-DD  
**状态**: 已发布
```

#### 3. 运行验证测试

```bash
# 在 guanji/guanji0.34/guanji0.34 目录下运行

# 快速验证（推荐）
bash Docs/validate_docs.sh

# 完整测试（包括属性测试）
swift Docs/DocumentFormatTests.swift
```

#### 4. 更新变更日志

在 [CHANGELOG.md](CHANGELOG.md) 中记录你的更新：

```markdown
## [版本号] - YYYY-MM-DD

### 新增 (Added)
- 新增的内容

### 变更 (Changed)
- 修改的内容
```

## 🧪 验证测试说明

### 快速验证脚本

```bash
bash Docs/validate_docs.sh
```

检查项：
- 文档格式是否正确
- 是否包含必要的元数据
- 是否包含导航链接

### 完整属性测试

```bash
swift Docs/DocumentFormatTests.swift
```

测试内容：
- **Property 1**: 文档格式一致性
  - 所有文档都有导航链接
  - 所有文档都有完整元数据
  
- **Property 4**: 代码覆盖完整性
  - 所有模型都有对应文档
  - 所有 Repository 都有对应文档
  - 所有功能模块都有对应文档
  
- **Property 5**: 链接完整性
  - 所有内部链接都指向存在的文件

## 💡 最佳实践

### DO ✅

- 在开始编码前先查阅相关文档
- 完成功能后立即更新文档
- 使用清晰的标题和章节结构
- 提供代码示例和使用说明
- 运行验证测试确保文档格式正确

### DON'T ❌

- 不要等到项目结束才写文档
- 不要复制粘贴过时的文档
- 不要忽略文档验证错误
- 不要使用模糊的描述
- 不要忘记更新元数据（版本、日期）

## 🔍 常见问题

### Q: 我不确定某个功能应该放在哪个文档里？

A: 参考 [功能地图](overview/feature-map.md) 和现有的文档结构。如果还不确定，可以在团队中讨论。

### Q: 文档验证失败怎么办？

A: 查看错误信息，通常是缺少导航链接或元数据。参考其他文档的格式进行修正。

### Q: 我需要创建新的文档分类吗？

A: 尽量使用现有的 6 个分类（overview/architecture/features/components/data/api）。如果确实需要新分类，请先与团队讨论。

### Q: 代码示例应该放在文档里还是代码注释里？

A: 两者都需要。代码注释解释具体实现，文档提供使用示例和整体说明。

## 📚 相关资源

- [文档中心](INDEX.md) - 所有文档的入口
- [变更日志](CHANGELOG.md) - 文档版本历史
- [产品概述](overview/product-overview.md) - 了解产品整体
- [系统架构](architecture/system-architecture.md) - 了解技术架构

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
