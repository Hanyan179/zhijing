# MVVM 模式说明

> 返回 [文档中心](../INDEX.md)

## 概述

观己(Guanji)采用 MVVM (Model-View-ViewModel) 架构模式，实现关注点分离。View 负责 UI 展示，ViewModel 负责业务逻辑和状态管理，Model 负责数据定义。

## 架构图

```mermaid
graph LR
    subgraph "View Layer"
        V[SwiftUI View]
    end
    
    subgraph "ViewModel Layer"
        VM[ViewModel]
        AS[AppState]
    end
    
    subgraph "Model Layer"
        M[Models]
        R[Repositories]
    end
    
    V -->|用户操作| VM
    VM -->|@Published| V
    VM -->|读写数据| R
    R -->|返回| M
    V -.->|@EnvironmentObject| AS
    VM -.->|访问| AS
```

## 职责划分

### View (视图层)

**职责**: 仅负责 UI 布局和数据绑定

| 允许 | 禁止 |
|------|------|
| 使用 `@StateObject` / `@ObservedObject` 绑定 ViewModel | 包含业务逻辑判断 |
| 使用 `@EnvironmentObject` 访问全局状态 | 直接调用 Repository |
| 响应用户交互，调用 ViewModel 方法 | 进行数据转换或格式化 |
| 使用 SwiftUI 原生组件和动画 | 硬编码字符串或数字 |

```swift
// ✅ 正确示例
public struct TimelineScreen: View {
    @StateObject private var vm = TimelineViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ScrollView {
            ForEach(vm.displayItems, id: \.id) { item in
                // 仅负责渲染，不包含业务逻辑
                ItemView(item: item)
            }
        }
        .onAppear { vm.load() }
    }
}

// ❌ 错误示例
var body: some View {
    // 禁止在 View 中写业务逻辑
    if user.isPremium && date > expireDate {
        PremiumContent()
    }
}
```

### ViewModel (视图模型层)

**职责**: 业务逻辑、状态管理、数据转换

| 职责 | 说明 |
|------|------|
| 业务逻辑 | 处理用户操作，执行业务规则 |
| 状态管理 | 使用 `@Published` 发布状态变化 |
| 数据转换 | 将 Model 数据转换为 View 可用格式 |
| Repository 访问 | 通过 Repository 读写数据 |

```swift
// 文件路径: Features/Timeline/TimelineViewModel.swift
public final class TimelineViewModel: ObservableObject {
    // 发布状态供 View 绑定
    @Published public private(set) var items: [TimelineItem] = []
    @Published public private(set) var displayItems: [TimelineItem] = []
    @Published public var currentDate: String = DateUtilities.today
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // 使用 Combine 响应状态变化
        Publishers.CombineLatest($items, $todayQuestions)
            .receive(on: RunLoop.main)
            .sink { [weak self] (items, questions) in
                self?.updateDisplayItems(items: items, questions: questions)
            }
            .store(in: &cancellables)
        
        load(date: currentDate)
    }
    
    // 业务方法
    public func load(date: String? = nil) {
        let targetDate = date ?? DateUtilities.today
        self.currentDate = targetDate
        
        // 通过 Repository 访问数据
        let timeline = TimelineRepository.shared.getDailyTimeline(for: targetDate)
        self.items = timeline.items
    }
    
    public func addEntry(_ entry: JournalEntry) {
        // 业务逻辑处理
        // ...
        TimelineRepository.shared.saveItems(items, for: currentDate)
    }
}
```

### Model (模型层)

**职责**: 数据结构定义，不包含业务逻辑

```swift
// 文件路径: Core/Models/JournalEntry.swift
public struct JournalEntry: Codable, Identifiable {
    public let id: String
    public let type: EntryType
    public let content: String?
    public let timestamp: String
    // 纯数据结构，无业务方法
}
```

## 全局状态管理

### AppState

全局应用状态，通过 `@EnvironmentObject` 在整个应用中共享。

```swift
// 文件路径: App/AppState.swift
public final class AppState: ObservableObject {
    @Published public var selectedDate: String = DateUtilities.today
    @Published public var currentMode: AppMode = .journal
    @Published public var showMindState: Bool = false
    @Published public var editingEntryId: String? = nil
    // ...
}
```

### 使用方式

```swift
// 在 App 入口注入
struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationStack { TimelineScreen() }
            .environmentObject(appState)
    }
}

// 在子视图中使用
struct SomeChildView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Text(appState.selectedDate)
    }
}
```

## 跨模块通信

### NotificationCenter

用于模块间解耦通信。

```swift
// 发送通知
NotificationCenter.default.post(
    name: Notification.Name("gj_timeline_updated"),
    object: nil
)

// 接收通知
NotificationCenter.default.addObserver(
    self,
    selector: #selector(onTimelineUpdated),
    name: Notification.Name("gj_timeline_updated"),
    object: nil
)
```

### 关键事件

| 事件名 | 触发场景 | 响应方 |
|--------|----------|--------|
| `gj_submit_input` | 用户提交输入 | TimelineViewModel |
| `gj_timeline_updated` | 时间轴数据变更 | TimelineScreen |
| `gj_addresses_changed` | 地址映射变更 | TimelineViewModel |
| `gj_tracker_updated` | 追踪器数据更新 | TimelineViewModel |
| `gj_edit_entry` | 编辑日记条目 | TimelineViewModel |
| `gj_delete_entry` | 删除日记条目 | TimelineViewModel |

## 文件组织

每个功能模块遵循统一的文件结构：

```
Features/[ModuleName]/
├── [ModuleName]Screen.swift      # View
├── [ModuleName]ViewModel.swift   # ViewModel
└── Views/                        # 子视图 (可选)
    ├── SubView1.swift
    └── SubView2.swift
```

### 示例: Timeline 模块

```
Features/Timeline/
├── TimelineScreen.swift          # 主视图
├── TimelineViewModel.swift       # 视图模型
└── Views/
    ├── CapsuleDetailSheet.swift
    ├── TimeRippleSheet.swift
    ├── TimeRippleView.swift
    └── TimelineEditingOverlay.swift
```

## 最佳实践

### 1. ViewModel 初始化

```swift
// ✅ 使用 @StateObject 创建 ViewModel
struct MyScreen: View {
    @StateObject private var vm = MyViewModel()
}

// ❌ 避免在 body 中创建
var body: some View {
    let vm = MyViewModel() // 每次渲染都会创建新实例
}
```

### 2. 状态发布

```swift
// ✅ 使用 private(set) 保护状态
@Published public private(set) var items: [Item] = []

// 提供方法修改状态
public func addItem(_ item: Item) {
    items.append(item)
}
```

### 3. 异步操作

```swift
// ✅ 在 ViewModel 中处理异步
public func fetchData() {
    Task { @MainActor in
        let data = await repository.fetch()
        self.items = data
    }
}
```

### 4. 避免循环引用

```swift
// ✅ 使用 [weak self]
somePublisher
    .sink { [weak self] value in
        self?.handleValue(value)
    }
    .store(in: &cancellables)
```

## 相关文档

- [系统架构](system-architecture.md)
- [数据架构](data-architecture.md)
- [功能模块文档](../features/)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
