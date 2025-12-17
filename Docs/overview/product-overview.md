# 产品概述

> 返回 [文档中心](../INDEX.md)

## 功能概述

观己(Guanji)是一款原生 iOS 日记与生活追踪应用，秉承"流畅原生体验"(Fluid Native Experience)设计理念。应用利用 SwiftUI 框架，为用户提供流畅、动画丰富、响应迅速的界面，用于记录日常时刻、追踪心境状态、回顾个人历史。

### 核心价值

- **时间轴记录**: 以时间为主线，记录生活中的每一个瞬间
- **心境追踪**: 量化情绪状态，分析影响因素
- **AI 对话**: 智能对话助手，提供个性化洞察
- **数据洞察**: 可视化分析个人数据，发现生活规律

## 技术栈

| 项目 | 值 |
|------|-----|
| 平台 | iOS 16.1+ |
| 语言 | Swift 5.0 |
| 框架 | SwiftUI |
| 架构 | MVVM + Atomic Design |
| Bundle ID | `hansen.guanji0-34` |

## 项目结构

```
guanji/guanji0.34/guanji0.34/
├── Features/          # 业务模块 (Screen + ViewModel)
├── UI/                # 可复用组件 (Atomic Design)
├── Core/              # 核心模块 (Models, DesignSystem, Utilities)
├── DataLayer/         # 数据层 (Repositories, SystemServices)
├── Shared/            # 扩展共享代码
└── Resources/         # 本地化字符串、Assets
```

## 功能模块

### 1. 时间轴 (Timeline)
应用主页，展示日记条目、天气信息和"共鸣"(过去的记忆)。区分静止时刻(场景块)和移动时刻(旅程块)。

### 2. AI 对话 (AIConversation)
智能对话界面，支持流式响应、思考过程展示、富文本渲染(Markdown、代码高亮)。

### 3. 每日追踪 (DailyTracker)
快速记录每日状态，包括睡眠、运动、饮食等维度的追踪。

### 4. 历史记录 (History)
浏览历史数据，支持按日期、对话、时间轴等维度查看。

### 5. 输入 (Input)
数据录入界面，支持文本、图片、语音等多媒体输入，以及时间胶囊功能。

### 6. 数据洞察 (Insight)
数据分析与可视化，展示个人数据趋势和规律。

### 7. 心境记录 (MindState)
情绪追踪专用界面，记录情绪状态和影响因素。

### 8. 个人中心 (Profile)
用户设置与个人信息管理，包含 25 个子页面。

## 核心数据模型

| 模型 | 用途 |
|------|------|
| JournalEntry | 日记原子 (最小记录单元) |
| DailyTimeline | 每日时间轴 |
| TimelineItem | 场景块/旅程块 |
| MindStateRecord | 心境记录 |
| LocationVO | 地点视图对象 |

## 设计原则

### Native First
优先使用原生 SwiftUI 组件，确保最佳性能和用户体验。

### 本地化优先
所有 UI 文本必须本地化，支持中文、英文等多语言。

### MVVM 架构
- **View**: 仅负责布局和绑定
- **ViewModel**: 处理业务逻辑和数据转换
- **Model**: 数据结构定义

## 相关文档

- [功能地图](feature-map.md) - 功能模块关系图
- [用户旅程](user-journey.md) - 核心用户场景
- [系统架构](../architecture/system-architecture.md) - 详细架构说明

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
