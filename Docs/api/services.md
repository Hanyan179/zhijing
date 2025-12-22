# Service 接口文档

> 返回 [文档中心](../INDEX.md)

## 概述

本文档描述观己应用的系统服务层 (System Services) 接口。System Services 负责与 iOS 系统框架集成，提供定位、天气、权限管理、健康数据等系统级功能。

**设计原则**:
- 单例模式 (Singleton Pattern)
- 异步回调或 Combine Publisher
- 封装系统框架复杂性
- 提供统一的错误处理

## Service 列表

| Service | 职责 | 系统框架 | 文件路径 |
|---------|------|---------|---------|
| LocationService | GPS 定位和地理编码 | CoreLocation | `DataLayer/SystemServices/LocationService.swift` |
| WeatherService | 天气信息获取 | WeatherKit | `DataLayer/SystemServices/WeatherService.swift` |
| PermissionsService | 统一权限管理 | Photos, AVFoundation, CoreLocation | `DataLayer/SystemServices/PermissionsService.swift` |
| HealthKitService | 健康数据访问 | HealthKit | `DataLayer/SystemServices/HealthKitService.swift` |
| AIService | AI 对话服务 | URLSession | `DataLayer/SystemServices/AIService.swift` |
| ProfileMigrationService | 用户画像迁移 | - | `DataLayer/SystemServices/ProfileMigrationService.swift` |
| DailyExtractionService | 🆕 每日数据提取（AI 知识提取） | - | `DataLayer/SystemServices/DailyExtractionService.swift` |

## LocationService

**职责**: 提供 GPS 定位、地理编码、区域监控功能

### 核心属性

```swift
// 单例实例
public static let shared: LocationService

// 位置更新发布者
public let locationPublisher: PassthroughSubject<CLLocation, Never>

// 区域退出发布者
public let regionExitPublisher: PassthroughSubject<CLRegion, Never>

// 最后已知位置
public var lastKnownLocation: CLLocation?

// 授权状态变更回调
public var onAuthChange: ((LocationAuthStatus) -> Void)?
```

### 核心方法

```swift
// 开始持续定位监控
public func startMonitoring()

// 停止持续定位监控
public func stopMonitoring()

// 开始区域监控
public func startRegionMonitoring(region: CLRegion)

// 停止区域监控
public func stopRegionMonitoring(region: CLRegion)

// 获取当前授权状态
public func currentStatus() -> LocationAuthStatus

// 请求定位授权
public func requestAuthorization()

// 解析地址（逆地理编码）
public func resolveAddress(location: CLLocation, completion: @escaping (String?) -> Void)

// 请求当前位置快照
public func requestCurrentSnapshot(_ completion: @escaping (Double, Double, String?) -> Void)

// 根据坐标建议地点映射
public func suggestMappings(lat: Double, lng: Double) -> [AddressMapping]
```

### 配置

```swift
// 定位精度
manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

// 后台定位
manager.allowsBackgroundLocationUpdates = true
manager.pausesLocationUpdatesAutomatically = false
```

### 使用示例

```swift
// 文件路径: Features/Timeline/TimelineViewModel.swift
LocationService.shared.locationPublisher
    .sink { location in
        print("New location: \(location.coordinate)")
    }
    .store(in: &cancellables)

LocationService.shared.startMonitoring()
```

## WeatherService

**职责**: 获取当前天气信息（温度、天气符号）

### 核心方法

```swift
// 获取当前天气（带缓存）
// 返回: (SymbolName, TemperatureString)
public func fetchCurrentWeather(lat: Double, lng: Double, completion: @escaping (String, String) -> Void)
```

### 缓存策略

- 相同位置（误差 < 0.001°）且 10 分钟内的请求直接返回缓存
- 防止并发请求（isFetching 标志）

### 平台兼容性

- iOS 16.0+: 使用 WeatherKit
- iOS < 16.0: 返回模拟数据

### 使用示例

```swift
// 文件路径: UI/Molecules/DateWeatherHeader.swift
WeatherService.shared.fetchCurrentWeather(lat: 39.9, lng: 116.4) { symbol, temp in
    self.weatherSymbol = symbol
    self.temperature = temp
}
```

## PermissionsService

**职责**: 统一管理相册、相机、麦克风、定位权限

### 权限状态枚举

```swift
public enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
    case limited // 仅相册
}
```

### 核心属性

```swift
// 相册权限状态
public var photoStatus: PermissionStatus { get }

// 相机权限状态
public var cameraStatus: PermissionStatus { get }

// 麦克风权限状态
public var micStatus: PermissionStatus { get }

// 定位权限状态
public var locationStatus: PermissionStatus { get }

// 定位授权变更回调
public var onLocationAuthChange: ((PermissionStatus) -> Void)?
```

### 核心方法

```swift
// 请求相册访问权限
public func requestPhotoAccess(completion: @escaping (PermissionStatus) -> Void)

// 请求相机访问权限
public func requestCameraAccess(completion: @escaping (PermissionStatus) -> Void)

// 请求麦克风访问权限
public func requestMicAccess(completion: @escaping (PermissionStatus) -> Void)

// 请求定位访问权限
public func requestLocationAccess()
```

### 使用示例

```swift
// 文件路径: UI/Organisms/PermissionLocationSheet.swift
if PermissionsService.shared.locationStatus == .notDetermined {
    PermissionsService.shared.requestLocationAccess()
}
```

## HealthKitService

**职责**: 访问 HealthKit 健康数据

### 核心属性

```swift
// HealthKit 是否可用
public var isAvailable: Bool { get }
```

### 核心方法

```swift
// 请求 HealthKit 授权
public func requestAuthorization(completion: @escaping (Bool) -> Void)
```

### 平台兼容性

- iOS 18.0+: 支持 HealthKit
- iOS < 18.0: 返回不可用

### 使用示例

```swift
// 文件路径: Features/Profile/ProfileViewModel.swift
if HealthKitService().isAvailable {
    HealthKitService().requestAuthorization { granted in
        print("HealthKit authorized: \(granted)")
    }
}
```

## ~~TimelineRecorder~~ (已移除)

**注意**: `TimelineRecorder` 已在 v0.34.1 中移除，改为按需定位策略。

### 移除原因

- **电量优化**: 后台持续追踪消耗大量电量
- **简化架构**: 减少状态机复杂度
- **隐私友好**: 仅在用户主动输入时获取位置
- **鲁棒性提升**: 避免后台进程被杀死导致的状态不一致

### 新的定位策略

**按需定位 (On-Demand Location)**:
- 仅在用户提交输入时获取当前位置
- 使用 `LocationRepository.suggestMappings()` 进行围栏匹配
- 通过 `TimelineViewModel.addEntry()` 智能判断场景/旅程块

### 场景/旅程判断逻辑

```swift
// 文件路径: Features/Timeline/TimelineViewModel.swift

// 场景块逻辑
if lastBlock is Scene:
    if currentLocation in sameFence:
        append to current scene  // 同一围栏 → 追加
    else:
        create journey block     // 不同围栏/无围栏 → 创建旅程

// 旅程块逻辑
if lastBlock is Journey:
    if currentLocation in anyFence:
        create scene block       // 到达围栏 → 创建场景
    else:
        append to current journey // 无围栏 → 继续旅程
```

### Fallback 机制

当没有围栏定义时，使用距离阈值 (500m) 判断是否移动。

### 优势

- ✅ 省电：无后台追踪
- ✅ 简单：无状态机
- ✅ 鲁棒：不依赖后台进程
- ✅ 连续性：同一状态不重复创建块
- ✅ 支持长途旅程：用户可能一整天都在旅途中

## AIService

**职责**: 与 AI 服务端通信，处理对话请求

### 核心方法

```swift
// 发送对话消息（流式响应）
public func sendMessage(
    messages: [ConversationMessage],
    settings: AISettings,
    onChunk: @escaping (String) -> Void,
    onThinking: @escaping (String) -> Void,
    onComplete: @escaping () -> Void,
    onError: @escaping (Error) -> Void
)

// 发送对话消息（非流式）
public func sendMessageNonStreaming(
    messages: [ConversationMessage],
    settings: AISettings,
    completion: @escaping (Result<String, Error>) -> Void
)
```

### 数据模型

- **ConversationMessage**: 对话消息
- **AISettings**: AI 配置参数

### 使用示例

```swift
// 文件路径: Features/AIConversation/AIConversationViewModel.swift
AIService.shared.sendMessage(
    messages: conversation.messages,
    settings: settings,
    onChunk: { chunk in
        self.streamingContent += chunk
    },
    onComplete: {
        self.isStreaming = false
    },
    onError: { error in
        self.errorMessage = error.localizedDescription
    }
)
```

## ProfileMigrationService

**职责**: 处理用户画像数据迁移

### 核心方法

```swift
// 迁移旧版用户画像到新版叙事画像
public func migrateToNarrativeProfile()

// 检查是否需要迁移
public func needsMigration() -> Bool
```

### 使用示例

```swift
// 文件路径: Features/Profile/ProfileViewModel.swift
if ProfileMigrationService.shared.needsMigration() {
    ProfileMigrationService.shared.migrateToNarrativeProfile()
}
```

## DailyExtractionService 🆕

**职责**: 从 L1 原始数据生成脱敏后的每日数据包，用于 AI 知识提取

### 核心功能

- **自动脱敏**: 所有人物名称统一为 `[REL_ID:displayName]` 格式
- **敏感数字过滤**: 手机号、身份证、邮箱、银行卡自动脱敏
- **数据聚合**: 按日聚合所有数据源（日记、追踪、爱表、AI对话）
- **关系上下文**: 提供已知关系列表供 AI 匹配

### 核心方法

```swift
// 提取指定日期的数据包
public func extractDailyPackage(for dayId: String) async throws -> DailyExtractionPackage
```

### 数据结构

```swift
// 每日数据提取包
struct DailyExtractionPackage {
    let dayId: String                          // "2024.12.22"
    let extractedAt: Date
    
    // L1 数据（已脱敏）
    let journalEntries: [SanitizedJournalEntry]
    let trackerRecord: SanitizedTrackerRecord?
    let loveLogs: [SanitizedLoveLog]
    let aiConversations: [AIConversationSummary]
    
    // 上下文
    let knownRelationships: [RelationshipContext]
    
    // 统计
    let stats: ExtractionStats
}
```

### 脱敏规则

| 数据类型 | 脱敏方式 | 示例 |
|---------|---------|------|
| 已知关系名称 | `[REL_ID:displayName]` | 妈妈、张美丽 → `[REL_001:妈妈]` |
| 未知人物 | `[UNKNOWN_PERSON:原名]` | 李老师 → `[UNKNOWN_PERSON:李老师]` |
| 手机号 | `[PHONE]` | 13812345678 → `[PHONE]` |
| 身份证 | `[ID_CARD]` | 110101199001011234 → `[ID_CARD]` |
| 邮箱 | `[EMAIL]` | test@example.com → `[EMAIL]` |
| AI对话内容 | 无需脱敏 | 用户已发送给 AI |

### 使用示例

```swift
// 文件路径: Features/AIConversation/AIConversationViewModel.swift

// 1. 提取今天的数据
let today = DateUtilities.today
let package = try await DailyExtractionService.shared.extractDailyPackage(for: today)

// 2. 检查是否有数据
if package.stats.isEmpty {
    print("今天没有数据")
    return
}

// 3. 格式化为 AI 可读文本
var text = "# \(package.dayId) 数据\n\n"
for entry in package.journalEntries {
    text += "[\(entry.timestamp)] \(entry.content ?? "")\n"
}

// 4. 发送给 AI 进行知识提取
let response = try await AIService.shared.sendMessage(text)

// 5. 解析 AI 返回的人物引用
if let identifier = PersonIdentifier.parse("[REL_001:妈妈]") {
    print("关系ID: \(identifier.relationshipId)")  // "001"
    print("显示名: \(identifier.displayName)")      // "妈妈"
}
```

### 相关工具

- **TextSanitizer**: 文本脱敏工具 (`Core/Utilities/TextSanitizer.swift`)
- **PersonIdentifier**: 统一人物标识符解析 (`Core/Models/DailyExtractionModels.swift`)

### 相关文档

- [AI 知识提取流程规划](../architecture/AI-KNOWLEDGE-EXTRACTION-PLAN.md)
- [L4 画像数据扩展规划](../architecture/L4-PROFILE-EXPANSION-PLAN.md)

## 系统框架集成

### CoreLocation

- **LocationService**: GPS 定位、地理编码、区域监控
- **TimelineRecorder**: 自动轨迹记录
- **PermissionsService**: 定位权限管理

### WeatherKit

- **WeatherService**: 天气数据获取

### Photos & AVFoundation

- **PermissionsService**: 相册、相机、麦克风权限管理

### HealthKit

- **HealthKitService**: 健康数据访问

### Combine

- **LocationService**: 使用 PassthroughSubject 发布位置更新
- **TimelineRecorder**: 订阅位置更新流

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| 定位失败 | 返回 (0, 0, nil)，不阻塞流程 |
| 地理编码失败 | 返回 nil，使用默认地点名称 |
| 天气获取失败 | 返回模拟数据 ("cloud", "--") |
| 权限被拒绝 | 返回 .denied 状态，引导用户到设置 |
| HealthKit 不可用 | 返回 false，隐藏相关功能 |
| AI 请求失败 | 通过 onError 回调返回错误 |

## 后台运行

### LocationService

```swift
// 允许后台定位更新
manager.allowsBackgroundLocationUpdates = true
manager.pausesLocationUpdatesAutomatically = false
```

### ~~TimelineRecorder~~ (已移除)

后台追踪已移除，改为按需定位策略。详见上文 "TimelineRecorder (已移除)" 章节。

## 性能优化

### WeatherService 缓存

- 相同位置 10 分钟内复用缓存
- 防止并发请求

### LocationService 精度

- 使用 `kCLLocationAccuracyHundredMeters` 平衡精度和电量

### 场景/旅程判断

- 围栏匹配：使用 `LocationRepository.suggestMappings()` 判断是否在已知地点
- 距离阈值：无围栏时使用 500m 判断是否移动
- 连续性保证：同一状态不重复创建块

## 相关文档

- [Repository 接口](./repositories.md)
- [系统架构](../architecture/system-architecture.md)
- [数据架构](../architecture/data-architecture.md)
- [时间轴功能](../features/timeline.md)

---
**版本**: v1.2.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-19  
**状态**: 已发布  
**重大变更**: 移除 TimelineRecorder，改为按需定位策略
