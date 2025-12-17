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
| TimelineRecorder | 自动时间轴记录 | CoreLocation, Combine | `DataLayer/SystemServices/TimelineRecorder.swift` |
| AIService | AI 对话服务 | URLSession | `DataLayer/SystemServices/AIService.swift` |
| ProfileMigrationService | 用户画像迁移 | - | `DataLayer/SystemServices/ProfileMigrationService.swift` |

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

## TimelineRecorder

**职责**: 自动记录用户移动轨迹，生成场景块和旅程块

### 状态机设计

```swift
private enum RecorderState {
    case unknown
    case stationary(center: CLLocation, startTime: Date)  // 静止状态
    case moving(startTime: Date)                          // 移动状态
}
```

### 核心参数

```swift
// 静止半径（米）
private let stationaryRadius: Double = 100.0

// 移动持续时间阈值（秒）
private let movingDurationThreshold: TimeInterval = 120  // 2 分钟

// 静止持续时间阈值（秒）
private let stationaryDurationThreshold: TimeInterval = 300  // 5 分钟
```

### 核心方法

```swift
// 开始自动记录
public func startRecording()

// 停止自动记录
public func stopRecording()
```

### 工作原理

1. **初始化**: 从 TimelineRepository 恢复最后状态
2. **场景 → 旅程**: 离开静止半径 > 2 分钟 → 创建 JourneyBlock
3. **旅程 → 场景**: 在新位置停留 > 5 分钟 → 创建 SceneGroup
4. **区域监控**: 使用 CLCircularRegion 在后台唤醒应用

### 数据操作

```swift
// 创建新场景
private func createNewScene(at location: CLLocation?)

// 创建新旅程
private func createNewJourney(from: CLLocation?, to: CLLocation?)
```

### 使用示例

```swift
// 文件路径: App/AppState.swift
TimelineRecorder.shared.startRecording()
```

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

### TimelineRecorder

```swift
// 使用区域监控在后台唤醒应用
let region = CLCircularRegion(center: center.coordinate, radius: stationaryRadius, identifier: "current_stay")
region.notifyOnExit = true
LocationService.shared.startRegionMonitoring(region: region)
```

## 性能优化

### WeatherService 缓存

- 相同位置 10 分钟内复用缓存
- 防止并发请求

### LocationService 精度

- 使用 `kCLLocationAccuracyHundredMeters` 平衡精度和电量

### TimelineRecorder 阈值

- 移动阈值 2 分钟：避免短暂移动误判
- 静止阈值 5 分钟：确保真正停留

## 相关文档

- [Repository 接口](./repositories.md)
- [系统架构](../architecture/system-architecture.md)
- [数据架构](../architecture/data-architecture.md)
- [时间轴功能](../features/timeline.md)

---
**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
