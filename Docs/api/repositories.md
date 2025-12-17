# Repository 接口文档

> 返回 [文档中心](../INDEX.md)

## 概述

本文档描述观己应用的数据仓库层 (Repository Layer) 接口。Repository 负责数据的持久化、缓存管理和业务数据访问，遵循 Repository 模式，为上层 ViewModel 提供统一的数据访问接口。

**设计原则**:
- 单例模式 (Singleton Pattern)
- 内存缓存 + 异步持久化
- 通过 NotificationCenter 发送数据变更通知
- JSON 文件存储 (Documents 目录)

## Repository 列表

| Repository | 职责 | 文件路径 |
|-----------|------|---------|
| TimelineRepository | 时间轴数据管理 | `DataLayer/Repositories/TimelineRepository.swift` |
| LocationRepository | 地点映射和围栏管理 | `DataLayer/Repositories/LocationRepository.swift` |
| AddressRepository | 地址数据持久化 | `DataLayer/Repositories/AddressRepository.swift` |
| MindStateRepository | 心境记录管理 | `DataLayer/Repositories/MindStateRepository.swift` |
| QuestionRepository | 时间胶囊问题管理 | `DataLayer/Repositories/QuestionRepository.swift` |
| AIConversationRepository | AI 对话历史管理 | `DataLayer/Repositories/AIConversationRepository.swift` |
| AISettingsRepository | AI 设置管理 | `DataLayer/Repositories/AISettingsRepository.swift` |
| DailyTrackerRepository | 每日追踪数据管理 | `DataLayer/Repositories/DailyTrackerRepository.swift` |
| ActivityTagRepository | 活动标签管理 | `DataLayer/Repositories/ActivityTagRepository.swift` |
| NarrativeUserProfileRepository | 叙事用户画像管理 | `DataLayer/Repositories/NarrativeUserProfileRepository.swift` |
| NarrativeRelationshipRepository | 叙事关系管理 | `DataLayer/Repositories/NarrativeRelationshipRepository.swift` |
| UserPreferencesRepository | 用户偏好设置管理 | `DataLayer/Repositories/UserPreferencesRepository.swift` |

## TimelineRepository

**职责**: 管理每日时间轴数据，包括场景块 (SceneGroup) 和旅程块 (JourneyBlock)

### 核心方法

```swift
// 获取指定日期的时间轴，不存在则创建
public func getDailyTimeline(for date: String) -> DailyTimeline

// 保存或更新时间轴
public func save(timeline: DailyTimeline)

// 保存时间轴项目（兼容旧版）
public func saveItems(_ items: [TimelineItem], for date: String)

// 追加时间轴项目
public func appendItem(_ item: TimelineItem, for date: String)

// 更新日记条目
public func updateEntry(_ entry: JournalEntry)

// 更新场景地点名称
public func updateLocationName(itemId: String, newName: String, for date: String)

// 更新旅程起点名称
public func updateOriginName(itemId: String, newName: String, for date: String)

// 更新旅程目的地
public func updateJourneyDestination(itemId: String, newDestination: LocationVO, duration: String, for date: String)

// 获取所有时间轴（按日期降序）
public func getAllTimelines() -> [DailyTimeline]

// 根据 ID 获取日记条目
public func getEntry(id: String) -> JournalEntry?

// 获取问题的所有回复
public func getReplies(for questionId: String) -> [JournalEntry]
```

### 通知事件

- `gj_timeline_updated`: 时间轴数据更新时发送

### 数据模型

- **DailyTimeline**: 每日时间轴容器
- **TimelineItem**: 场景块或旅程块
- **JournalEntry**: 日记原子

## LocationRepository

**职责**: 管理地点映射 (AddressMapping) 和地理围栏 (AddressFence)

### 核心方法

```swift
// 更新地点映射
public func updateMapping(id: String, name: String? = nil, icon: String? = nil, color: String? = nil)

// 删除地点映射
public func deleteMapping(id: String)

// 更新围栏半径
public func updateFenceRadius(fenceId: String, radius: Double)

// 删除围栏
public func deleteFence(fenceId: String)

// 添加地点映射
public func addMapping(name: String, icon: String? = nil, color: String? = nil) -> AddressMapping

// 添加地点映射和围栏
public func addMappingAndFence(name: String, icon: String?, color: String?, lat: Double, lng: Double, rawName: String?, radius: Double = 150) -> AddressMapping

// 根据坐标建议地点映射
public func suggestMappings(lat: Double, lng: Double) -> [AddressMapping]

// 根据名称查找地点映射
public func findMapping(byName name: String) -> AddressMapping?

// 添加围栏
public func addFence(mappingId: String, lat: Double, lng: Double, rawName: String, radius: Double = 150) -> AddressFence

// 验证数据完整性
public func validate() -> [String]

// 获取操作边界
public func operationalBounds(marginDegrees: Double = 0.05) -> (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)?

// 检查坐标是否在操作边界内
public func isWithinOperationalBounds(lat: Double, lng: Double) -> Bool

// 重新加载数据
public func reload()
```

### 通知事件

- `gj_addresses_changed`: 地点数据变更时发送

### 数据模型

- **AddressMapping**: 地点映射（用户自定义地点名称）
- **AddressFence**: 地理围栏（坐标 + 半径）

## AddressRepository

**职责**: 地址数据的文件持久化

### 核心方法

```swift
// 加载地址数据
public func load() -> (mappings: [AddressMapping], fences: [AddressFence])?

// 保存地址数据
public func save(mappings: [AddressMapping], fences: [AddressFence])
```

## MindStateRepository

**职责**: 管理心境记录数据

### 核心方法

```swift
// 保存心境记录
public func save(_ record: MindStateRecord)

// 加载所有心境记录
public func loadAll() -> [MindStateRecord]

// 加载指定日期的心境记录
public func load(for date: String) -> [MindStateRecord]
```

### 数据模型

- **MindStateRecord**: 心境记录快照

## QuestionRepository

**职责**: 管理时间胶囊问题

### 核心方法

```swift
// 根据 ID 获取问题
public func get(id: String) -> QuestionEntry?

// 添加问题
public func add(_ question: QuestionEntry)

// 获取所有问题
public func getAll() -> [QuestionEntry]
```

### 数据模型

- **QuestionEntry**: 时间胶囊问题

## AIConversationRepository

**职责**: 管理 AI 对话历史

### 核心方法

```swift
// 获取所有对话
public func getAllConversations() -> [AIConversation]

// 获取指定对话
public func getConversation(id: String) -> AIConversation?

// 保存对话
public func saveConversation(_ conversation: AIConversation)

// 删除对话
public func deleteConversation(id: String)

// 添加消息到对话
public func appendMessage(_ message: ConversationMessage, to conversationId: String)

// 更新消息
public func updateMessage(_ message: ConversationMessage, in conversationId: String)
```

### 数据模型

- **AIConversation**: AI 对话会话
- **ConversationMessage**: 对话消息

## AISettingsRepository

**职责**: 管理 AI 设置

### 核心方法

```swift
// 加载 AI 设置
public func loadSettings() -> AISettings

// 保存 AI 设置
public func saveSettings(_ settings: AISettings)

// 更新模型配置
public func updateModel(_ model: String)

// 更新温度参数
public func updateTemperature(_ temperature: Double)

// 更新系统提示词
public func updateSystemPrompt(_ prompt: String)
```

### 数据模型

- **AISettings**: AI 配置参数

## DailyTrackerRepository

**职责**: 管理每日追踪数据

### 核心方法

```swift
// 获取指定日期的追踪数据
public func getTracker(for date: String) -> DailyTracker?

// 保存追踪数据
public func saveTracker(_ tracker: DailyTracker)

// 获取所有追踪数据
public func getAllTrackers() -> [DailyTracker]

// 删除追踪数据
public func deleteTracker(for date: String)
```

### 数据模型

- **DailyTracker**: 每日追踪数据容器

## ActivityTagRepository

**职责**: 管理用户创建的活动标签

### 核心方法

```swift
// 获取指定活动类型的标签（按使用次数降序）
public func getTags(for type: ActivityType) -> [ActivityTag]

// 获取所有标签（按使用次数降序）
public func getAllTags() -> [ActivityTag]

// 保存标签
public func saveTag(_ tag: ActivityTag)

// 创建并保存标签
public func createTag(text: String, for type: ActivityType) -> ActivityTag

// 增加标签使用次数
public func incrementUsage(tagId: String)

// 批量增加标签使用次数
public func incrementUsage(tagIds: [String])

// 删除标签
public func deleteTag(id: String)

// 检查标签是否存在
public func tagExists(text: String, for type: ActivityType) -> Bool

// 根据 ID 获取标签
public func getTag(id: String) -> ActivityTag?

// 强制重新加载
public func reload()
```

### 数据模型

- **ActivityTag**: 活动标签

## NarrativeUserProfileRepository

**职责**: 管理叙事用户画像

### 核心方法

```swift
// 加载用户画像
public func loadProfile() -> NarrativeUserProfile

// 保存用户画像
public func saveProfile(_ profile: NarrativeUserProfile)

// 更新画像字段
public func updateProfile(name: String?, bio: String?, traits: [String]?)
```

### 数据模型

- **NarrativeUserProfile**: 叙事用户画像

## NarrativeRelationshipRepository

**职责**: 管理叙事关系

### 核心方法

```swift
// 获取所有关系
public func getAllRelationships() -> [NarrativeRelationship]

// 获取指定关系
public func getRelationship(id: String) -> NarrativeRelationship?

// 保存关系
public func saveRelationship(_ relationship: NarrativeRelationship)

// 删除关系
public func deleteRelationship(id: String)

// 更新关系
public func updateRelationship(id: String, name: String?, type: String?, notes: String?)
```

### 数据模型

- **NarrativeRelationship**: 叙事关系

## UserPreferencesRepository

**职责**: 管理用户偏好设置

### 核心方法

```swift
// 默认应用模式（journal 或 ai）
public var defaultMode: AppMode { get set }

// 加载默认模式
public func loadDefaultMode() -> AppMode

// AI 思考模式是否启用
public var thinkingModeEnabled: Bool { get set }

// SiliconFlow API 密钥
public var apiKey: String { get set }

// 检查 API 密钥是否已配置
public var isAPIKeyConfigured: Bool { get }
```

### 数据模型

- **AppMode**: 应用模式枚举

## 持久化策略

### 文件存储

所有 Repository 使用 JSON 文件存储在 Documents 目录：

```
Documents/
├── TimelineData_v2/
│   └── daily_timelines.json
├── TimelineData/
│   └── questions.json
├── Addresses.json
├── activity_tags.json
└── [其他数据文件]
```

### 内存缓存

- TimelineRepository: 缓存所有 DailyTimeline
- LocationRepository: 缓存所有 AddressMapping 和 AddressFence
- ActivityTagRepository: 延迟加载缓存

### 异步写入

所有持久化操作在后台线程执行，避免阻塞主线程：

```swift
DispatchQueue.global(qos: .background).async {
    // 持久化逻辑
}
```

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| 文件不存在 | 返回 nil 或空数组，创建新数据 |
| JSON 解码失败 | 打印错误日志，使用空数据初始化 |
| 写入失败 | 打印错误日志，不影响内存缓存 |
| 数据验证失败 | 返回错误列表，不阻止操作 |

## 相关文档

- [数据模型概览](../data/models-overview.md)
- [系统架构](../architecture/system-architecture.md)
- [数据架构](../architecture/data-architecture.md)
- [Service 接口](./services.md)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
