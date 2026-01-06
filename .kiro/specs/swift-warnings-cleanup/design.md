# Design Document: Swift Warnings Cleanup

## Overview

本设计文档描述了系统性清理 Xcode 编译警告的技术方案。主要涉及以下几类问题：

1. **UI 线程阻塞** - LocationService 中的授权检查
2. **弃用 API** - KnowledgeNodeModels 中的 extractedFrom 字段
3. **Swift 6 并发安全** - InsightViewModel、AIService、MessageBubble 中的 actor 隔离问题
4. **代码质量** - 未使用变量、不可达 catch 块

## Architecture

修复工作不涉及架构变更，仅对现有代码进行局部修改以消除编译警告。

```
┌─────────────────────────────────────────────────────────────┐
│                    Warning Categories                        │
├─────────────────────────────────────────────────────────────┤
│  1. LocationService        │  UI Thread Warning              │
│  2. KnowledgeNodeModels    │  Deprecated API Warning         │
│  3. InsightViewModel       │  Swift 6 Concurrency Warnings   │
│  4. AIService/Repository   │  Swift 6 Concurrency Warnings   │
│  5. MessageBubble          │  Swift 6 Concurrency Warnings   │
│  6. TimelineViewModel      │  Unused Variable Warnings       │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. LocationService 修复

**问题**: 第 48 行调用 `CLLocationManager.authorizationStatus` 类方法可能阻塞主线程。

**现状分析**: 查看代码发现 `currentStatus()` 方法已经使用了 `manager.authorizationStatus` 实例属性，但警告仍然存在。需要检查是否有其他地方调用了类方法。

**解决方案**: 确保所有授权状态检查都使用实例属性而非类方法。

```swift
// 修复前 (如果存在)
let status = CLLocationManager.authorizationStatus()

// 修复后
let status = manager.authorizationStatus
```

### 2. KnowledgeNodeModels 弃用 API 修复

**问题**: 第 210、211、441 行使用了已弃用的 `extractedFrom` 字段。

**现状分析**: 
- `extractedFrom` 已被标记为 `@available(*, deprecated)`
- 新的 `sourceLinks` 字段已经存在于 `KnowledgeNode` 级别
- 解码器中有自动迁移逻辑

**解决方案**: 
1. 在解码器中使用 `@_silenceDeprecationWarnings` 或重构迁移逻辑
2. 在初始化器中避免直接引用弃用字段

```swift
// 修复方案 1: 使用 @_silenceDeprecationWarnings (Swift 5.8+)
// 修复方案 2: 重构迁移逻辑，避免直接访问弃用字段

// 在 NodeSource 初始化时，不再传递 extractedFrom 参数
// 而是在 KnowledgeNode 级别处理 sourceLinks
```

### 3. InsightViewModel Swift 6 并发修复

**问题**: 大量 `Main actor-isolated` 警告，主要集中在：
- `computeOverview()`, `computeFeatureUsage()`, `computeDataInsight()` 等 nonisolated 方法中调用 MainActor 隔离的方法
- 不可达的 catch 块

**解决方案**:

#### 3.1 修复 nonisolated 方法中的 actor 隔离问题

```swift
// 修复前
nonisolated private func computeOverview() -> OverviewStats {
    do {
        let streak = try computeStreak()  // ❌ MainActor-isolated
        // ...
    }
}

// 修复后 - 方案 A: 移除 nonisolated 标记
private func computeOverview() -> OverviewStats {
    let streak = computeStreak()
    // ...
}

// 修复后 - 方案 B: 将计算方法也标记为 nonisolated
nonisolated private func computeStreak() -> Int {
    // 确保不访问 MainActor 隔离的状态
}
```

#### 3.2 移除不可达的 catch 块

```swift
// 修复前
private func computeStreak() throws -> Int {
    do {
        // 没有 throwing 表达式
        return streak
    } catch {  // ⚠️ 不可达
        print("[InsightViewModel] Error: \(error)")
        throw error
    }
}

// 修复后
private func computeStreak() -> Int {
    // 直接返回，不需要 try-catch
    return streak
}
```

### 4. AIService/AIConversationRepository 编码修复

**问题**: `AIConversation`, `APIErrorResponse`, `ChatCompletionResponse` 的 Codable 协议在 nonisolated 上下文中使用。

**解决方案**: 确保这些类型的 Codable 实现不依赖 MainActor 隔离。

```swift
// 修复方案: 将数据模型标记为 Sendable 并移除 MainActor 隔离
// 或者使用 nonisolated 的编码/解码方法

// 对于 AIConversation
public struct AIConversation: Codable, Sendable {
    // 确保所有属性都是 Sendable
}
```

### 5. MessageBubble MarkdownParser 修复

**问题**: 第 147 行在 `Task.detached` 中调用 MainActor-isolated 的 `MarkdownParser.parse`。

**现状分析**: `MarkdownParser` 是一个 enum，其静态方法默认不应该是 MainActor-isolated。需要检查是否有隐式的 actor 隔离。

**解决方案**:

```swift
// 修复方案 1: 确保 MarkdownParser 是 nonisolated
public enum MarkdownParser {
    nonisolated public static func parse(_ markdown: String) -> Document {
        return Document(parsing: markdown)
    }
}

// 修复方案 2: 在调用处使用 await MainActor.run
parsedDocument = await Task.detached(priority: .userInitiated) {
    await MainActor.run {
        MarkdownParser.parse(content)
    }
}.value
```

### 6. TimelineViewModel 未使用变量修复

**问题**: 
- 第 153 行: `let ts = entry.timestamp` 未使用
- 第 216 行: `let j` 未使用

**解决方案**:

```swift
// 修复前
let ts = entry.timestamp  // ⚠️ 未使用

// 修复后
_ = entry.timestamp  // 或直接删除这行
```

## Data Models

本次修复不涉及数据模型变更。

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

基于 prework 分析，大多数需求都是编译器级别的验证（警告消除），只有一个可测试的属性：

### Property 1: KnowledgeNode 向后兼容解码

*For any* 有效的旧格式 KnowledgeNode JSON（包含 `tracking.source.extractedFrom` 但不包含顶层 `sourceLinks`），解码后的 `KnowledgeNode` 对象的 `sourceLinks` 应该包含原 `extractedFrom` 中的所有数据。

**Validates: Requirements 2.2**

## Error Handling

本次修复主要涉及移除不必要的错误处理代码（不可达的 catch 块），不引入新的错误处理逻辑。

## Testing Strategy

### 编译验证

主要验证方式是确保修复后代码编译无警告：

1. 清理构建目录
2. 重新编译项目
3. 确认所有目标警告已消除

### 属性测试

对于 KnowledgeNode 向后兼容性，使用属性测试验证：

```swift
// Property Test: 向后兼容解码
func testBackwardCompatibleDecoding() {
    // 生成随机的旧格式 JSON
    let oldFormatJSON = generateOldFormatKnowledgeNodeJSON()
    
    // 解码
    let node = try JSONDecoder().decode(KnowledgeNode.self, from: oldFormatJSON)
    
    // 验证 sourceLinks 包含原 extractedFrom 数据
    XCTAssertEqual(node.sourceLinks.count, expectedExtractedFromCount)
}
```

### 单元测试

对于 LocationService 授权状态检查，添加单元测试验证回调机制正常工作。

## Notes

- Swift 6 并发警告目前只是警告，不影响编译。但建议修复以便未来升级。
- 部分修复可能需要根据实际代码情况调整方案。
- 建议分批次修复，每次修复后验证功能正常。
