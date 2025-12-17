# UI 组件文档

> 返回 [文档中心](../INDEX.md)

## 概述

观己应用采用 Atomic Design 设计方法论构建 UI 组件体系。该方法论将 UI 组件分为三个层级：原子 (Atoms)、分子 (Molecules) 和有机体 (Organisms)，从简单到复杂逐层组合。

## 设计原则

### Atomic Design 层级

```
┌─────────────────────────────────────────────────────────┐
│                    有机体 (Organisms)                    │
│  完整的功能区块，如 InputDock、SceneBlock               │
├─────────────────────────────────────────────────────────┤
│                    分子 (Molecules)                      │
│  复合组件，如 JournalRow、StatusSliderCard              │
├─────────────────────────────────────────────────────────┤
│                    原子 (Atoms)                          │
│  基础组件，如 Button、Slider、Badge                     │
└─────────────────────────────────────────────────────────┘
```

### Native First 原则

优先使用 SwiftUI 原生组件，避免过度自定义：

```swift
// ✅ 推荐
List { }
NavigationStack { }
Button { }
TextField { }

// ❌ 避免
自定义阴影、固定尺寸、手动布局计算
```

## 组件目录

### [原子组件 (Atoms)](./atoms.md)

最基础的 UI 构建单元，不可再分。

| 组件 | 用途 |
|------|------|
| CapsuleTextEditor | 胶囊样式文本编辑器 |
| ChartAtoms | 图表组件（环形图、热力图等） |
| GrowingTextEditor | 自动增长文本编辑器 |
| InputAtoms | 输入相关组件（按钮、录音条等） |
| JournalAtoms | 日记相关组件（容器、头部、时间戳等） |
| ListAtoms | 列表相关组件（行项、开关等） |
| LocationBadge | 地点徽章 |
| MediaAtoms | 媒体组件（图片、视频、音频等） |
| RoundIconButton | 圆形图标按钮 |
| SelectableChip | 可选择标签 |
| TagInputChip | 标签输入组件 |
| ThickSlider | 粗滑块 |

### [分子组件 (Molecules)](./molecules.md)

由多个原子组件组合而成的复合组件。

| 组件 | 用途 |
|------|------|
| AchievementCard | 成就卡片 |
| ActivityGroupSection | 活动分组区块 |
| CapsuleCard | 时间胶囊卡片 |
| CategoryPillBar | 分类药丸栏 |
| CategoryRadialMenu | 分类径向菜单 |
| ContextCard | 活动上下文卡片 |
| ContextDetailSheet | 上下文详情弹窗 |
| DailyTrackerSummaryCard | 每日追踪摘要卡片 |
| DateWeatherHeader | 日期天气头部 |
| EditHeaderBar | 编辑头部栏 |
| InsightMolecules | 数据洞察组件 |
| JournalRow | 日记行项 |
| JourneyHeaderChip | 旅程头部标签 |
| RichTextRenderer | 富文本渲染器 |
| SceneHeader | 场景头部 |
| StatusSliderCard | 状态滑块卡片 |

### [有机体组件 (Organisms)](./organisms.md)

由分子和原子组件组合而成的完整功能区块。

| 组件 | 用途 |
|------|------|
| DocumentPicker | 文档选择器 |
| ExpandedInputView | 展开输入视图 |
| InputDock | 输入停靠栏 |
| InputMenuPanel | 输入菜单面板 |
| JourneyBlock | 旅程区块 |
| MorningBriefing | 晨间简报 |
| PermissionLocationSheet | 位置权限弹窗 |
| PlaceNamingSheet | 地点命名弹窗 |
| PlaceResolveSheet | 地点解析弹窗 |
| ResonanceHub | 共鸣中心 |
| SceneBlock | 场景区块 |

## 组件统计

| 层级 | 数量 | 目录 |
|------|------|------|
| 原子 (Atoms) | 13 个文件 | `UI/Atoms/` |
| 分子 (Molecules) | 15 个文件 | `UI/Molecules/` |
| 有机体 (Organisms) | 11 个文件 | `UI/Organisms/` |
| **总计** | **39 个文件** | |

## 设计系统引用

组件使用统一的设计系统，定义在 `Core/DesignSystem/` 目录：

- **Colors** - 语义化颜色定义
- **Typography** - 字体样式
- **Icons** - 图标映射
- **Materials** - 材质效果

```swift
// 颜色使用
Colors.background
Colors.primary
Colors.slateText

// 字体使用
Typography.body
Typography.header
Typography.caption

// 材质使用
.modifier(Materials.glass())
.modifier(Materials.card())
```

## 相关文档

- [系统架构](../architecture/system-architecture.md)
- [MVVM 模式](../architecture/mvvm-pattern.md)
- [功能模块文档](../features/)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
