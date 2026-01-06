# UI组件系统

<cite>
**本文档引用的文件**
- [Colors.swift](file://guanji0.34/Core/DesignSystem/Colors.swift)
- [Typography.swift](file://guanji0.34/Core/DesignSystem/Typography.swift)
- [Icons.swift](file://guanji0.34/Core/DesignSystem/Icons.swift)
- [CapsuleTextEditor.swift](file://guanji0.34/UI/Atoms/CapsuleTextEditor.swift)
- [GrowingTextEditor.swift](file://guanji0.34/UI/Atoms/GrowingTextEditor.swift)
- [RoundIconButton.swift](file://guanji0.34/UI/Atoms/RoundIconButton.swift)
- [InputAtoms.swift](file://guanji0.34/UI/Atoms/InputAtoms.swift)
- [JournalAtoms.swift](file://guanji0.34/UI/Atoms/JournalAtoms.swift)
- [JournalRow.swift](file://guanji0.34/UI/Molecules/JournalRow.swift)
- [CapsuleCard.swift](file://guanji0.34/UI/Molecules/CapsuleCard.swift)
- [ContextCard.swift](file://guanji0.34/UI/Molecules/ContextCard.swift)
- [InputDock.swift](file://guanji0.34/UI/Organisms/InputDock.swift)
- [ResonanceHub.swift](file://guanji0.34/UI/Organisms/ResonanceHub.swift)
- [MorningBriefing.swift](file://guanji0.34/UI/Organisms/MorningBriefing.swift)
- [InsightMolecules.swift](file://guanji0.34/UI/Molecules/InsightMolecules.swift)
- [ListAtoms.swift](file://guanji0.34/UI/Atoms/ListAtoms.swift)
- [ChartAtoms.swift](file://guanji0.34/UI/Atoms/ChartAtoms.swift)
- [MediaAtoms.swift](file://guanji0.34/UI/Atoms/MediaAtoms.swift)
</cite>

## 目录
1. [设计系统](#设计系统)
2. [原子组件 (Atoms)](#原子组件-atoms)
3. [分子组件 (Molecules)](#分子组件-molecules)
4. [有机体组件 (Organisms)](#有机体组件-organisms)

## 设计系统

本UI组件库的设计系统是应用视觉规范的“唯一真相源”，确保了跨功能和跨平台的UI一致性。它由三个核心部分构成：颜色、字体和图标，这些都在`Core/DesignSystem`目录下定义。

### 颜色规范

颜色系统通过`Colors.swift`文件定义，提供了一套全面且语义化的颜色集，以适应深色和浅色模式。主要颜色类别包括：

- **基础颜色**：`background`（背景）、`text`（文本）和`systemGray`（系统灰色）。
- **石板色系**：用于不同UI元素的`slateDark`、`slatePrimary`、`slateText`、`slate600`、`slate500`和`slateLight`，确保在不同模式下的可读性和层次感。
- **卡片背景**：`cardBackground`，根据用户界面样式动态调整，为卡片类组件提供合适的背景。
- **主题色**：一组鲜明的调色板，包括`indigo`（靛蓝）、`amber`（琥珀）、`rose`（玫瑰）、`emerald`（翡翠）、`sky`（天空）、`violet`（紫罗兰）、`teal`（水鸭色）、`orange`（橙色）、`pink`（粉色）、`blue`（蓝色）、`green`（绿色）和`red`（红色），用于按钮、状态指示和品牌元素。

**组件来源**
- [Colors.swift](file://guanji0.34/Core/DesignSystem/Colors.swift#L4-L30)

### 字体规范

字体系统在`Typography.swift`中定义，通过静态常量提供一致的文本样式。它使用系统字体以确保最佳的可读性和平台一致性。

- `fontEngraved`: 10pt 半粗体，用于雕刻风格的标签。
- `fontSerif`: 16pt 常规衬线体，用于特定的排版场景。
- `header`: 20pt 半粗体，用于标题。
- `body`: 15pt 常规体，用于正文内容。
- `caption`: 12pt 常规体，用于说明文字和小字。

**组件来源**
- [Typography.swift](file://guanji0.34/Core/DesignSystem/Typography.swift#L3-L9)

### 图标规范

图标系统由`Icons.swift`管理，它提供了一个将业务逻辑映射到系统图标的函数式接口。

- `categoryIconName(_:)`: 根据日记条目类别（如`.dream`、`.health`）返回对应的SF Symbols名称。
- `categoryLabelKey(_:)`: 返回与类别关联的本地化键。
- `categoryLabel(_:)`: 使用`NSLocalizedString`根据类别返回本地化的标签文本。
- `transportIconName(_:)`: 根据交通方式（如`.car`、`.walk`）返回对应的图标名称。

**组件来源**
- [Icons.swift](file://guanji0.34/Core/DesignSystem/Icons.swift#L3-L42)

## 原子组件 (Atoms)

原子是UI中最基础的不可再分的组件。它们是构建更复杂组件的基石。

### 输入控件

#### CapsuleTextEditor
一个胶囊形状的文本编辑器，专为输入区域设计。它在iOS上使用`UITextView`，并集成了一个工具栏，包含添加照片、文件和收起键盘的按钮。在其他平台上，它是一个简单的`TextEditor`。

- **属性**:
  - `text`: 绑定的字符串，用于获取和设置输入内容。
  - `onAddPhoto`: 添加照片时的回调。
  - `onAddFile`: 添加文件时的回调。
  - `onCollapse`: 收起键盘时的回调。
- **事件回调**: 通过`onAddPhoto`、`onAddFile`和`onCollapse`属性暴露。
- **使用约束**: 应作为输入区域的核心文本输入组件。

**组件来源**
- [CapsuleTextEditor.swift](file://guanji0.34/UI/Atoms/CapsuleTextEditor.swift#L8-L49)

#### GrowingTextEditor
一个可自动调整高度的文本编辑器，适用于需要根据内容动态扩展的输入框。

- **属性**:
  - `text`: 绑定的字符串，用于获取和设置输入内容。
  - `dynamicHeight`: 绑定的`CGFloat`，用于接收计算出的动态高度。
- **事件回调**: 内部通过`Coordinator`处理文本变化，并自动更新`dynamicHeight`。
- **使用约束**: 必须与一个可变高度的容器（如`VStack`）结合使用，以便根据`dynamicHeight`进行布局。

**组件来源**
- [GrowingTextEditor.swift](file://guanji0.34/UI/Atoms/GrowingTextEditor.swift#L18-L57)

### 按钮

#### RoundIconButton
一个圆形的图标按钮，提供视觉上的统一性。

- **属性**:
  - `systemName`: 要显示的SF Symbols名称。
  - `accent`: 可选的强调色，用于覆盖默认文本颜色。
  - `action`: 点击按钮时触发的回调。
- **事件回调**: 通过`action`属性暴露。
- **使用约束**: 适用于工具栏或操作面板中的图标按钮。

**组件来源**
- [RoundIconButton.swift](file://guanji0.34/UI/Atoms/RoundIconButton.swift#L26-L41)

### 其他原子组件

`InputAtoms.swift`和`JournalAtoms.swift`文件中定义了更多原子组件，用于构建更复杂的UI。

- **DockContainer**: 为输入区域提供一个带有圆角、阴影和边框的容器，其样式会根据焦点和回复模式动态变化。
- **SubmitButton**: 一个发送按钮，其背景为渐变色，当有文本输入时会变得突出，否则处于禁用状态。
- **RecordingBar**: 一个录音条，显示录音时长，并支持长按开始/结束录音和滑动取消。
- **ReplyContextBar**: 在回复模式下显示，展示正在回复的内容。
- **AttachmentsBar**: 显示已添加的附件（照片、文件）列表，并提供移除功能。
- **InputQuickActions**: 一个水平滚动的快速操作栏，包含相册、相机、录音、时间胶囊、心情、文件和更多操作的按钮。
- **AtomContainer**: 一个通用的容器，用于包裹日记条目，支持高亮显示。
- **AtomHeader**: 显示日记条目的类别图标和标签。
- **AtomTimestamp**: 显示条目的时间戳。
- **AtomContextReply**: 显示上下文回复的引用。

**组件来源**
- [InputAtoms.swift](file://guanji0.34/UI/Atoms/InputAtoms.swift#L3-L365)
- [JournalAtoms.swift](file://guanji0.34/UI/Atoms/JournalAtoms.swift#L5-L181)

## 分子组件 (Molecules)

分子是由多个原子组合而成的复合组件，它们代表了更具体的UI模式。

### JournalRow
`JournalRow`是日记视图中的核心分子组件，负责根据日记条目的类型和状态渲染不同的UI。

- **构成**:
  - 使用`AtomContainer`作为外层容器。
  - 使用`AtomHeader`显示类别。
  - 使用`SpecialContentRenderer`渲染内容（文本、图片、音频等）。
  - 使用`AtomTimestamp`显示时间。
  - 在特定条件下，会渲染`MoleculeEcho`、`MoleculeConnection`、`MoleculeReview`或`CapsuleCard`。
- **复用场景**: 用于`TimelineScreen`和`HistoryView`中，以列表形式展示所有日记条目。
- **属性**:
  - `entry`: 要显示的`JournalEntry`模型。
  - `questionEntries`: 关联的问题条目列表。
  - `currentDateLabel`: 当前视图的日期标签。
  - `todayDate`: 今天的日期。
  - 多个可选的回调函数，用于处理回复、提交、上下文菜单、删除和跳转等操作。
- **事件回调**: 通过`onInitiateReply`, `onSubmitReply`, `onContextMenu`, `onDelete`, `onJumpToDate`等属性暴露。
- **使用约束**: 必须在`ScrollView`或`List`中使用，并且需要传入完整的数据和回调。

**组件来源**
- [JournalRow.swift](file://guanji0.34/UI/Molecules/JournalRow.swift#L3-L119)

### CapsuleCard
`CapsuleCard`代表一个“时间胶囊”或“未来问题”，用户可以在未来某个日期打开并回复。

- **构成**:
  - 显示问题的状态（待回复、已回复、超期）。
  - 显示问题的提示文本（`system_prompt`）。
  - 包含一个“回复”或“查看”按钮。
  - 点击后会弹出`CapsuleDetailSheet`进行详细操作。
- **复用场景**: 在`JournalRow`中，当遇到一个未来问题时，会渲染为`CapsuleCard`。
- **属性**:
  - `question`: 关联的`QuestionEntry`。
  - `sourceEntry`: 源日记条目。
  - `replies`: 已有的回复列表。
  - `onInitiateReply`: 开始回复的回调。
  - `onReply`: 提交回复的回调。
  - `onJumpToDate`: 跳转到指定日期的回调。
- **事件回调**: 通过`onInitiateReply`和`onReply`属性暴露。
- **使用约束**: 通常由`JournalRow`内部逻辑决定何时渲染。

**组件来源**
- [CapsuleCard.swift](file://guanji0.34/UI/Molecules/CapsuleCard.swift#L3-L122)

### ContextCard
`ContextCard`用于显示一个活动的上下文摘要，如活动类型和同伴。

- **构成**:
  - 显示活动的图标和名称。
  - 显示最多两个同伴标签，超过两个则显示“+N”。
  - 包含一个向右的箭头，表示可以点击进入详情。
- **复用场景**: 在`DailyTracker`流程中，用于展示已选择的活动及其上下文。
- **属性**:
  - `activity`: 活动类型。
  - `context`: 活动的上下文数据。
  - `onTap`: 点击卡片时的回调。
- **事件回调**: 通过`onTap`属性暴露。
- **使用约束**: 通常与`ContextCardList`一起使用，形成一个列表。

**组件来源**
- [ContextCard.swift](file://guanji0.34/UI/Molecules/ContextCard.swift#L5-L67)

## 有机体组件 (Organisms)

有机体是最高层级的组件，由多个分子和原子组成，代表了完整的、独立的业务功能模块。

### InputDock
`InputDock`是应用的核心输入区域，集成了所有输入相关的功能。

- **内部结构**:
  - 顶部可选显示`ReplyContextBar`。
  - 中间可选显示`AttachmentsBar`。
  - 一个可展开的`InputQuickActions`工具栏。
  - 一个录音状态的`RecordingBar`。
  - 核心的`DockContainer`，内含`TextField`和`SubmitButton`。
- **外部接口**:
  - 使用`InputViewModel`作为数据源和业务逻辑的驱动。
  - 通过`@EnvironmentObject`与`AppState`交互，以切换应用模式（日记/AI）。
  - 通过`@State`管理内部状态，如`showPhotoPicker`、`showCamera`等，以控制模态视图的显示。
- **属性**: 无公开属性，主要通过内部状态和环境对象驱动。
- **事件回调**: 内部处理所有用户交互，如提交文本、添加附件、切换模式等。
- **使用约束**: 作为应用主界面的底部固定组件，应放置在`ZStack`的底层或`VStack`的末尾。

**组件来源**
- [InputDock.swift](file://guanji0.34/UI/Organisms/InputDock.swift#L8-L330)

### ResonanceHub
`ResonanceHub`是一个数据聚合视图，用于展示来自过去不同年份的“共鸣”记忆。

- **内部结构**:
  - 一个可折叠的头部，显示总记忆数。
  - 展开后，列出每个年份的统计数据，包括年份标签、标题和一个时间轴指示器。
- **外部接口**:
  - `stats`: 一个`[ResonanceDateStat]`数组，提供数据源。
  - 通过`@EnvironmentObject`与`AppState`交互，点击条目时会设置`selectedDate`。
- **属性**:
  - `stats`: 要显示的共鸣统计数据。
- **事件回调**: 无直接暴露的回调，但通过改变`AppState.selectedDate`来触发导航。
- **使用约束**: 用于“历史”或“洞察”功能中，作为探索过去记忆的入口。

**组件来源**
- [ResonanceHub.swift](file://guanji0.34/UI/Organisms/ResonanceHub.swift#L3-L55)

### MorningBriefing
`MorningBriefing`是一个晨间简报组件，用于汇总当天需要处理的待办事项。

- **内部结构**:
  - 一个可折叠的头部，显示“Inbox”标签。
  - 展开后，使用`JournalRow`组件列表来显示待办条目。
- **外部接口**:
  - `items`: 一个`[JournalEntry]`数组，提供待办事项列表。
- **属性**:
  - `items`: 要显示的待办条目。
- **事件回调**: 依赖于`JournalRow`内部的回调。
- **使用约束**: 通常作为主界面顶部的一个模块，用于提醒用户当天的任务。

**组件来源**
- [MorningBriefing.swift](file://guanji0.34/UI/Organisms/MorningBriefing.swift#L3-L30)