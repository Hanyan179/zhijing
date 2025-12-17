# 原子组件 (Atoms)

> 返回 [文档中心](../INDEX.md) | [组件概览](./INDEX.md)

## 概述

原子组件是观己应用 UI 系统中最基础的构建单元，遵循 Atomic Design 设计方法论。这些组件是不可再分的最小 UI 元素，用于构建更复杂的分子组件和有机体组件。

## 组件列表

| 组件名称 | 文件 | 用途 |
|---------|------|------|
| CapsuleTextEditor | `CapsuleTextEditor.swift` | 胶囊样式文本编辑器 |
| ChartAtoms | `ChartAtoms.swift` | 图表相关原子组件 |
| GrowingTextEditor | `GrowingTextEditor.swift` | 自动增长文本编辑器 |
| InputAtoms | `InputAtoms.swift` | 输入相关原子组件 |
| JournalAtoms | `JournalAtoms.swift` | 日记相关原子组件 |
| ListAtoms | `ListAtoms.swift` | 列表相关原子组件 |
| LocationBadge | `LocationBadge.swift` | 地点徽章组件 |
| MediaAtoms | `MediaAtoms.swift` | 媒体相关原子组件 |
| RoundIconButton | `RoundIconButton.swift` | 圆形图标按钮 |
| SelectableChip | `SelectableChip.swift` | 可选择标签组件 |
| TagInputChip | `TagInputChip.swift` | 标签输入组件 |
| ThickSlider | `ThickSlider.swift` | 粗滑块组件 |
| SwiftGrowingTextEditor | `SwiftGrowingTextEditor.swift` | Swift 原生自动增长编辑器 |

## 详细说明

### CapsuleTextEditor

胶囊样式的多行文本编辑器，支持 iOS 和 macOS 平台。

**功能特性:**
- 自动调整高度
- 内置工具栏支持添加照片和文件
- 键盘收起按钮

```swift
// 文件路径: UI/Atoms/CapsuleTextEditor.swift
CapsuleTextEditor(
    text: $text,
    onAddPhoto: { /* 添加照片 */ },
    onAddFile: { /* 添加文件 */ },
    onCollapse: { /* 收起键盘 */ }
)
```

### ChartAtoms

图表相关的原子组件集合，用于数据可视化展示。

**包含组件:**
- `OverviewCard` - 概览卡片，显示连续天数、总天数、总条目数
- `RingChart` - 环形图表，显示分类占比
- `HeatmapGrid` - 热力图网格，显示 24 小时活动密度

```swift
// 文件路径: UI/Atoms/ChartAtoms.swift
OverviewCard(streak: 7, totalDays: 30, totalEntries: 150)

RingChart(items: [
    RingChartItem(value: 0.4, color: .blue),
    RingChartItem(value: 0.3, color: .green)
], dominantLabel: "工作")

HeatmapGrid(hourCounts: Array(repeating: 5, count: 24))
```

### GrowingTextEditor

自动根据内容调整高度的文本编辑器，基于 UIKit 实现。

**功能特性:**
- 动态高度调整
- 支持绑定高度值
- 跨平台兼容 (iOS/macOS)

```swift
// 文件路径: UI/Atoms/GrowingTextEditor.swift
@State private var text = ""
@State private var height: CGFloat = 36

GrowingTextEditor(text: $text, dynamicHeight: $height)
```

### InputAtoms

输入相关的原子组件集合，用于构建输入界面。

**包含组件:**
- `DockContainer` - 输入栏容器，支持焦点状态和回复模式
- `DockRoundButton` - 圆形功能按钮
- `SubmitButton` - 发送按钮，根据文本状态显示/隐藏
- `RecordingBar` - 录音条，支持长按录音
- `ReplyContextBar` - 回复上下文栏
- `AttachmentsBar` - 附件栏
- `InputQuickActions` - 快捷操作栏

```swift
// 文件路径: UI/Atoms/InputAtoms.swift
DockContainer(isMenuOpen: false, isReplyMode: false, isFocused: true) {
    // 输入内容
}

SubmitButton(hasText: !text.isEmpty) {
    // 发送操作
}

InputQuickActions(
    onGallery: { },
    onCamera: { },
    onRecord: { },
    onTimeCapsule: { },
    onMood: { },
    onFile: { },
    onMore: { }
)
```

### JournalAtoms

日记相关的原子组件集合，用于日记条目展示。

**包含组件:**
- `AtomContainer` - 原子容器，支持高亮显示
- `AtomHeader` - 原子头部，显示分类和混合标签
- `AtomTimestamp` - 时间戳显示
- `AtomContextReply` - 上下文回复显示
- `MoleculeSealed` - 封存记忆显示
- `MoleculeConnection` - 连接消息显示
- `MoleculeEcho` - 回声消息显示
- `MoleculeReview` - 回顾消息显示

```swift
// 文件路径: UI/Atoms/JournalAtoms.swift
AtomContainer(isHighlighted: true) {
    AtomHeader(category: .work, isMixed: false, lang: .zh)
    Text("日记内容")
    AtomTimestamp(timestamp: "14:30")
}
```

### ListAtoms

列表相关的原子组件集合，用于设置和列表界面。

**包含组件:**
- `GroupLabel` - 分组标签
- `ListGroup` - 列表分组容器
- `ListRow` - 列表行项
- `ToggleSwitch` - 开关组件

```swift
// 文件路径: UI/Atoms/ListAtoms.swift
ListGroup {
    ListRow(iconName: "gear", label: "设置", onClick: { })
    ListRow(iconName: "bell", label: "通知", value: "开启")
}
```

### LocationBadge

地点徽章组件，显示位置信息并支持交互。

**功能特性:**
- 显示地点名称和图标
- 支持原始坐标和已映射地点两种状态
- 点击和长按手势支持

```swift
// 文件路径: UI/Atoms/LocationBadge.swift
LocationBadge(
    location: locationVO,
    onClick: { /* 点击处理 */ },
    onLongPress: { /* 长按处理 */ }
)
```

### MediaAtoms

媒体相关的原子组件集合，用于展示图片、视频、音频等媒体内容。

**包含组件:**
- `ImageEntry` - 图片条目，支持全屏查看
- `VideoEntry` - 视频条目，支持全屏播放
- `AudioEntry` - 音频条目，带波形可视化
- `FileEntry` - 文件条目，支持分享
- `SpecialContentRenderer` - 特殊内容渲染器
- `FullScreenImageView` - 全屏图片查看器
- `FullScreenVideoPlayer` - 全屏视频播放器

```swift
// 文件路径: UI/Atoms/MediaAtoms.swift
ImageEntry(src: "photo.jpg")
VideoEntry(src: "video.mp4")
AudioEntry(duration: "01:30", content: "语音备注", url: "audio.m4a")
FileEntry(url: "document.pdf", name: "文档.pdf")
```

### RoundIconButton

圆形图标按钮，带材质背景效果。

```swift
// 文件路径: UI/Atoms/RoundIconButton.swift
RoundIconButton(systemName: "plus", accent: .blue) {
    // 点击操作
}

// 仅显示图标（无按钮功能）
RoundIconView(systemName: "star", accent: .yellow)
```

### SelectableChip

可选择的胶囊形标签按钮。

**包含组件:**
- `SelectableChip` - 通用可选标签
- `CompactActivityChip` - 紧凑活动标签
- `CompanionChip` - 同伴类型标签

```swift
// 文件路径: UI/Atoms/SelectableChip.swift
SelectableChip(
    text: "工作",
    icon: "briefcase",
    isSelected: true,
    accent: .blue
) {
    // 选择操作
}
```

### TagInputChip

标签输入组件，用于用户自定义标签。

**包含组件:**
- `TagInputChip` - 活动标签组件
- `SimpleTagChip` - 简单文本标签
- `AddTagButton` - 添加标签按钮

```swift
// 文件路径: UI/Atoms/TagInputChip.swift
TagInputChip(tag: activityTag, isSelected: true) {
    // 选择操作
}

AddTagButton {
    // 添加新标签
}
```

### ThickSlider

粗滑块组件，用于数值选择。

**功能特性:**
- 自定义范围和步进值
- 左右文本标签
- 自定义强调色

```swift
// 文件路径: UI/Atoms/ThickSlider.swift
ThickSlider(
    value: $sliderValue,
    range: 0...100,
    step: 1,
    leftText: "低",
    rightText: "高",
    accent: .blue
)
```

### SwiftGrowingTextEditor

纯 SwiftUI 实现的自动增长文本编辑器。

```swift
// 文件路径: UI/Atoms/SwiftGrowingTextEditor.swift
SwiftGrowingTextEditor(text: $text)
```

## 相关文档

- [分子组件](./molecules.md)
- [有机体组件](./organisms.md)
- [设计系统](../architecture/system-architecture.md)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
