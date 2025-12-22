# 观己(Guanji) 文档中心

> 统一的产品与技术文档入口

**🚀 新手？** 查看 [快速入门指南](QUICK_START.md) 了解如何使用文档系统

## 快速导航

| 分类 | 描述 | 入口 |
|------|------|------|
| 📖 概述 | 产品概述、功能地图、用户旅程 | [overview/](overview/) |
| 🏗️ 架构 | 系统架构、数据架构、MVVM 模式 | [architecture/](architecture/) |
| ⚡ 功能 | 8 个功能模块的详细文档 | [features/](features/) |
| 🧩 组件 | UI 组件库 (Atoms/Molecules/Organisms) | [components/](components/) |
| 📊 数据 | 数据模型定义与关系 | [data/](data/) |
| 🔌 接口 | Repository 与 Service 接口 | [api/](api/) |

## 文档索引

### 概述文档 (Overview)
- [x] [产品概述](overview/product-overview.md) - 产品功能和技术栈
- [x] [功能地图](overview/feature-map.md) - 功能模块关系图
- [x] [用户旅程](overview/user-journey.md) - 核心用户场景

### 架构文档 (Architecture)
- [x] [系统架构](architecture/system-architecture.md) - MVVM 架构与分层结构
- [x] [数据架构](architecture/data-architecture.md) - 四层记忆系统设计
- [x] [MVVM 模式](architecture/mvvm-pattern.md) - ViewModel 与 View 职责
- [x] [L4 画像扩展规划](architecture/L4-PROFILE-EXPANSION-PLAN.md) - 🆕 通用知识节点设计 (规划中)

### 功能模块文档 (Features)
- [x] [时间轴](features/timeline.md) - Timeline 主页模块
- [x] [AI 对话](features/ai-conversation.md) - AI 对话模块
- [x] [每日追踪](features/daily-tracker.md) - 每日追踪模块
- [x] [历史记录](features/history.md) - 历史记录模块
- [x] [输入](features/input.md) - 输入模块
- [x] [数据洞察](features/insight.md) - 数据洞察模块
- [x] [心境记录](features/mind-state.md) - 心境记录模块
- [x] [个人中心](features/profile.md) - 个人中心模块

### UI 组件文档 (Components)
- [x] [原子组件](components/atoms.md) - 基础 UI 组件
- [x] [分子组件](components/molecules.md) - 复合 UI 组件
- [x] [有机体组件](components/organisms.md) - 复杂 UI 组件

### 数据模型文档 (Data)
- [x] [模型概览](data/models-overview.md) - 18 个模型文件概览
- [x] [时间轴模型](data/timeline-models.md) - 时间轴相关模型
- [x] [用户画像模型](data/user-profile-models.md) - 用户画像相关模型
- [x] [AI 模型](data/ai-models.md) - AI 相关模型
- [x] [追踪器模型](data/tracker-models.md) - 追踪器相关模型

### API 文档 (API)
- [x] [Repository 接口](api/repositories.md) - 12 个数据仓库接口
- [x] [Service 接口](api/services.md) - 系统服务接口

## 标签筛选

### 按功能模块
`timeline` `ai-conversation` `daily-tracker` `history` `input` `insight` `mind-state` `profile`

### 按技术领域
`swiftui` `mvvm` `repository` `service` `model` `ui-component`

## 文档规范

- 所有文档使用 Markdown 格式
- 文件命名使用 kebab-case 英文命名
- 每个文档包含返回文档中心的导航链接
- 每个文档底部包含版本、作者、更新日期、状态元数据

## 开发工作流程

### 📝 开发前：查找相关文档

在开始开发或修改功能前，请先查阅相关文档以了解：
- 现有架构和设计模式
- 数据模型定义和关系
- 相关功能模块的实现细节
- UI 组件的使用方法

**推荐流程**：
1. 从 [功能模块文档](features/) 了解功能概览
2. 查阅 [数据模型文档](data/) 了解数据结构
3. 参考 [架构文档](architecture/) 了解设计模式
4. 查看 [API 文档](api/) 了解接口定义

### ✅ 开发后：更新相关文档

完成功能开发或修改后，请及时更新对应文档：

| 修改类型 | 需要更新的文档 |
|---------|---------------|
| 新增/修改数据模型 | [data/](data/) 目录下对应的模型文档 |
| 新增/修改 Repository | [api/repositories.md](api/repositories.md) |
| 新增/修改 Service | [api/services.md](api/services.md) |
| 新增/修改功能模块 | [features/](features/) 目录下对应的功能文档 |
| 新增/修改 UI 组件 | [components/](components/) 目录下对应的组件文档 |
| 架构调整 | [architecture/](architecture/) 目录下对应的架构文档 |

### 🧪 文档验证

在提交文档更新前，请运行验证脚本确保文档格式正确：

```bash
# 快速验证（检查格式）
bash Docs/validate_docs.sh

# 完整测试（包括属性测试）
swift Docs/DocumentFormatTests.swift
```

所有文档必须通过以下验证：
- ✅ 包含导航链接
- ✅ 包含完整的元数据（版本、作者、日期、状态）
- ✅ 内部链接有效
- ✅ 代码覆盖完整（所有模型、Repository、功能都有对应文档）

## 实用指南

- [x] [数据格式标准](DATA_FORMAT_STANDARD.md) - 统一的日期格式规范
- [x] [每日数据导出指南](DAILY_EXPORT_GUIDE.md) - 导出每日数据为纯文本

## 变更日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解文档版本变更历史。

---
**版本**: v1.3.0  
**最后更新**: 2024-12-22  
**状态**: 已发布
