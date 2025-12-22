# 分子组件 (Molecules)

> 返回 [文档中心](../INDEX.md) | [组件概览](./INDEX.md)

## 概述

分子组件是由多个原子组件组合而成的复合 UI 元素，遵循 Atomic Design 设计方法论。这些组件实现了特定的功能单元，可以在不同的有机体组件和页面中复用。

## 组件列表

| 组件名称 | 文件 | 用途 |
|---------|------|------|
| AchievementCard | `AchievementCard.swift` | 成就卡片 |
| ActivityGroupSection | `ActivityGroupSection.swift` | 活动分组区块 |
| CapsuleCard | `CapsuleCard.swift` | 时间胶囊卡片 |
| CategoryPillBar | `CategoryPillBar.swift` | 分类药丸栏 |
| CategoryRadialMenu | `CategoryRadialMenu.swift` | 分类径向菜单 |
| ContextCard | `ContextCard.swift` | 活动上下文卡片 |
| ContextDetailSheet | `ContextDetailSheet.swift` | 上下文详情弹窗 |
| DailyTrackerSummaryCard | `DailyTrackerSummaryCard.swift` | 每日追踪摘要卡片 |
| DateWeatherHeader | `DateWeatherHeader.swift` | 日期天气头部 |
| EditHeaderBar | `EditHeaderBar.swift` | 编辑头部栏 |
| InsightMolecules | `InsightMolecules.swift` | 数据洞察分子组件 |
| JournalRow | `JournalRow.swift` | 日记行项 |
| JourneyHeaderChip | `JourneyHeaderChip.swift` | 旅程头部标签 |
| RichTextRenderer | `RichTextRenderer.swift` | 富文本渲染器 |
| SceneHeader | `SceneHeader.swift` | 场景头部 |
| StatusSliderCard | `StatusSliderCard.swift` | 状态滑块卡片 |

## 详细说明

### AchievementCard

成就卡片组件，用于展示用户获得的成就。

**功能特性:**
- 支持三种稀有度：普通、稀有、传奇
- 显示成就标题、描述、进度
- 根据稀有度自动调整样式

```swift
// 文件路径: UI/Molecules/AchievementCard.swift
AchievementCard(achievement: userAchievement)
```

### ActivityGroupSection

活动分组区块，用于按类别展示活动选项。

**功能特性:**
- 按组显示活动类型
- 支持多选
- 自适应网格布局

**包含组件:**
- `ActivityGroupSection` - 单个活动组
- `ActivitySelectionView` - 完整活动选择视图

```swift
// 文件路径: UI/Molecules/ActivityGroupSection.swift
ActivityGroupSection(
    group: .competence,
    selectedActivities: selectedSet,
    onToggle: { activity in /* 切换选择 */ }
)
```

### CapsuleCard

时间胶囊卡片，用于展示和管理时间胶囊问题。

**功能特性:**
- 显示胶囊状态（待回复/已回复/超期）
- 支持查看详情和回复
- 自动计算剩余天数

```swift
// 文件路径: UI/Molecules/CapsuleCard.swift
CapsuleCard(
    question: questionEntry,
    sourceEntry: journalEntry,
    replies: replyEntries,
    onInitiateReply: { /* 开始回复 */ },
    lang: .zh
)
```

### CategoryPillBar

分类药丸栏，水平排列的分类选择按钮。

**功能特性:**
- 水平滚动布局
- 支持编辑模式
- 触觉反馈

```swift
// 文件路径: UI/Molecules/CategoryPillBar.swift
CategoryPillBar(
    categories: [.work, .life, .health],
    onSelect: { category in /* 选择分类 */ },
    onEdit: { /* 编辑模式 */ }
)
```

### CategoryRadialMenu

分类径向菜单，环形布局的分类选择器。

**功能特性:**
- 环形布局
- 中心编辑按钮
- 动画过渡效果

```swift
// 文件路径: UI/Molecules/CategoryRadialMenu.swift
CategoryRadialMenu(
    categories: [.work, .life, .health],
    onSelect: { category in /* 选择分类 */ },
    onEdit: { /* 编辑模式 */ }
)
```

### ContextCard

活动上下文卡片，显示活动摘要信息。

**功能特性:**
- 显示活动图标和名称
- 显示同伴类型标签
- 点击展开详情

**包含组件:**
- `ContextCard` - 单个上下文卡片
- `ContextCardList` - 上下文卡片列表

```swift
// 文件路径: UI/Molecules/ContextCard.swift
ContextCard(
    activity: .work,
    context: activityContext,
    onTap: { /* 打开详情 */ }
)
```

### ContextDetailSheet

上下文详情弹窗，用于编辑活动的详细上下文。

**功能特性:**
- 人员选择（自动关联类型）
- 标签管理
- 备注输入
- 快速添加新联系人

```swift
// 文件路径: UI/Molecules/ContextDetailSheet.swift
ContextDetailSheet(
    activity: .work,
    context: $activityContext,
    onDone: { /* 完成编辑 */ }
)
```

### DailyTrackerSummaryCard

每日追踪摘要卡片，在时间轴中展示当日追踪记录。

**功能特性:**
- 显示身体能量和心情天气
- 显示活动标签
- 完成状态指示

```swift
// 文件路径: UI/Molecules/DailyTrackerSummaryCard.swift
DailyTrackerSummaryCard(
    record: dailyTrackerRecord,
    onTap: { /* 查看详情 */ }
)
```

### DateWeatherHeader

日期天气头部，显示当前日期和天气信息。

**功能特性:**
- 显示日期文本
- 天气图标
- 返回今天按钮
- 支持手势交互

```swift
// 文件路径: UI/Molecules/DateWeatherHeader.swift
DateWeatherHeader(
    dateText: "2024年12月17日",
    onOpenMindState: { /* 打开心境 */ },
    showBackToToday: true,
    onBackToToday: { /* 返回今天 */ }
)
```

### EditHeaderBar

编辑头部栏，提供取消和完成操作。

```swift
// 文件路径: UI/Molecules/EditHeaderBar.swift
EditHeaderBar(
    onCancel: { /* 取消 */ },
    onDone: { /* 完成 */ }
)
```

### InsightMolecules

数据洞察相关的分子组件集合。

**包含组件:**
- `StateAnalysisCard` - 状态分析卡片（心情/能量环形图）
- `RankingItemView` - 排名项视图
- `RankingListView` - 排名列表视图（人物/地点）
- `KeywordsCloudView` - 关键词云视图

```swift
// 文件路径: UI/Molecules/InsightMolecules.swift
StateAnalysisCard(vm: insightViewModel)
RankingListView(vm: insightViewModel)
KeywordsCloudView(words: ["工作", "学习", "运动"])
```

### JournalRow

日记行项，根据日记类型渲染不同的展示形式。

**功能特性:**
- 支持多种日记类型（文本、图片、音频、视频等）
- 支持时间胶囊展示
- 支持回顾和回声消息
- 上下文菜单支持

```swift
// 文件路径: UI/Molecules/JournalRow.swift
JournalRow(
    entry: journalEntry,
    questionEntries: questions,
    currentDateLabel: "2024.12.17",
    todayDate: "2024.12.17",
    isHighlighted: false,
    lang: .zh
)
```

### JourneyHeaderChip

旅程头部标签，显示交通方式和目的地。

```swift
// 文件路径: UI/Molecules/JourneyHeaderChip.swift
JourneyHeaderChip(
    mode: .walking,
    destination: locationVO,
    onTapDestination: { /* 点击目的地 */ }
)
```

**显示格式**: `🚗 → 📍公司`

**注意**: `durationText` 参数已在 v0.34.1 中移除，不再显示时长信息。

### RichTextRenderer

富文本渲染器，将 Markdown 文档渲染为 SwiftUI 视图。

**功能特性:**
- 支持标题 (H1-H6)
- 支持段落和内联格式（粗体、斜体、代码、链接）
- 支持代码块（带语法高亮和复制功能）
- 支持有序/无序列表（支持嵌套）
- 支持引用块
- 支持表格（带对齐和滚动）
- 支持分隔线

**包含组件:**
- `RichTextRenderer` - 主渲染器
- `HeadingView` - 标题视图
- `ParagraphView` - 段落视图
- `CodeBlockView` - 代码块视图
- `UnorderedListView` / `OrderedListView` - 列表视图
- `BlockQuoteView` - 引用块视图
- `MarkdownTableView` - 表格视图

```swift
// 文件路径: UI/Molecules/RichTextRenderer.swift
import Markdown

let document = Document(parsing: markdownString)
RichTextRenderer(document: document, isUserMessage: false)
```

### SceneHeader

场景头部，显示场景的位置和时间范围。

```swift
// 文件路径: UI/Molecules/SceneHeader.swift
SceneHeader(
    scene: sceneGroup,
    isEditing: false,
    onEditLocation: { /* 编辑位置 */ }
)
```

### StatusSliderCard

状态滑块卡片，用于每日追踪的状态选择。

**功能特性:**
- 大图标显示当前状态
- 连续滑块 (0-100)
- 支持身体能量和心情天气两种类型

**包含组件:**
- `StatusSliderCard` - 通用状态滑块
- `BodyEnergySliderCard` - 身体能量滑块
- `MoodWeatherSliderCard` - 心情天气滑块

```swift
// 文件路径: UI/Molecules/StatusSliderCard.swift
BodyEnergySliderCard(value: $bodyEnergy)
MoodWeatherSliderCard(value: $moodWeather)
```

## 相关文档

- [原子组件](./atoms.md)
- [有机体组件](./organisms.md)
- [设计系统](../architecture/system-architecture.md)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
