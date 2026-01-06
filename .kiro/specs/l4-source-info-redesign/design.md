# Design Document

## Overview

本设计文档定义人生回顾功能中"来源信息"区块的重构方案，核心目标是：
1. 将"置信度"改为"关联原始次数"，更直观地展示数据支撑
2. 将来源类型从 AI 分类改为数据表类型分布（日记 X 条、AI对话 X 条）
3. 移除验证状态相关 UI
4. 修复详情页编辑交互问题（sheet over sheet）

---

## Architecture

### 当前架构问题

```
┌─────────────────────────────────────────────────────────────┐
│                    NodeSourceSection (当前)                  │
├─────────────────────────────────────────────────────────────┤
│  ❌ 置信度进度条 (0.0~1.0)                                   │
│  ❌ 来源类型: userInput | aiExtracted | aiInferred          │
│  ❌ 验证状态: 已确认 | 待审核 | 未确认                       │
│  ✅ 时间信息: 创建时间、更新时间、确认时间                    │
└─────────────────────────────────────────────────────────────┘
```

### 重构后架构

```
┌─────────────────────────────────────────────────────────────┐
│                    NodeSourceSection (重构后)                │
├─────────────────────────────────────────────────────────────┤
│  ✅ 关联原始次数: sourceLinks.count                          │
│  ✅ 来源类型分布: 日记 X 条、AI对话 X 条、追踪器 X 条...      │
│  ✅ 时间信息: 创建时间、更新时间                             │
│  ❌ 移除: 置信度、验证状态、确认时间                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Components and Interfaces

### 1. NodeSourceSection 重构

```swift
/// 节点来源信息区块 - 重构版
///
/// 显示内容：
/// - 关联原始次数（基于 sourceLinks 数量）
/// - 来源类型分布（按数据表类型分组统计）
/// - 时间信息（创建时间、更新时间）
public struct NodeSourceSection: View {
    let node: KnowledgeNode
    let color: Color
    
    // MARK: - Computed Properties
    
    /// 关联原始次数
    private var mentionCount: Int {
        node.sourceLinks.count
    }
    
    /// 来源类型分布
    private var sourceTypeDistribution: [String: Int] {
        Dictionary(grouping: node.sourceLinks, by: { $0.sourceType })
            .mapValues { $0.count }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            mentionCountView      // 新增：关联原始次数
            sourceTypeView        // 重构：来源类型分布
            timelineView          // 保留：时间信息（移除确认时间）
            // 移除: confidenceView
            // 移除: verificationStatusView
        }
    }
}
```

### 2. 来源类型图标映射

```swift
/// 数据表来源类型图标和显示名称
public struct DataSourceTypeIcons {
    
    /// 获取来源类型图标
    public static func icon(for sourceType: String) -> String {
        switch sourceType {
        case "diary":
            return "book.fill"
        case "conversation":
            return "bubble.left.and.bubble.right.fill"
        case "tracker":
            return "checklist"
        case "mindState":
            return "heart.fill"
        default:
            return "doc.fill"
        }
    }
    
    /// 获取来源类型显示名称
    public static func displayName(for sourceType: String) -> String {
        switch sourceType {
        case "diary":
            return "日记"
        case "conversation":
            return "AI对话"
        case "tracker":
            return "追踪器"
        case "mindState":
            return "心情记录"
        default:
            return "其他"
        }
    }
}
```

### 3. KnowledgeNodeDetailSheet 编辑交互修复

```swift
/// 知识节点详情 Sheet - 修复编辑交互
public struct KnowledgeNodeDetailSheet: View {
    
    // MARK: - State
    
    /// 是否显示编辑 Sheet
    @State private var showEditSheet: Bool = false
    
    /// 当前编辑的节点（用于 sheet 绑定）
    @State private var editingNode: KnowledgeNode?
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            // ... 内容
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                actionMenu  // 移除"确认"按钮
            }
        }
        // 🆕 编辑 Sheet（在详情 Sheet 上方弹出）
        .sheet(isPresented: $showEditSheet) {
            KnowledgeNodeEditSheet(
                originalNode: node,
                viewModel: viewModel,
                onSave: { updatedNode in
                    // 更新详情页显示
                    // viewModel 会自动更新
                }
            )
        }
    }
    
    /// 操作菜单 - 移除确认按钮
    private var actionMenu: some View {
        Menu {
            Button {
                showEditSheet = true  // 直接显示编辑 Sheet
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            
            // 🆕 移除确认按钮
            // if canConfirm { ... }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

---

## Data Models

### 1. 保持现有数据模型（向后兼容）

数据模型层面不做修改，只是 UI 层面不再显示某些字段：

```swift
// 保持不变 - 向后兼容
public struct NodeSource: Codable {
    public var type: SourceType               // 保留但 UI 不显示
    public var confidence: Double?            // 保留但 UI 不显示
    public var extractedFrom: [SourceLink]    // 保留（已废弃，使用节点级 sourceLinks）
}

// 保持不变 - 向后兼容
public struct NodeVerification: Codable {
    public var confirmedByUser: Bool          // 保留但 UI 不显示
    public var needsReview: Bool              // 保留但 UI 不显示
}

// 保持不变 - 向后兼容
public struct SourceLink: Codable, Identifiable {
    public var sourceType: String             // diary | conversation | tracker | mindState
    public var sourceId: String
    public var dayId: String
    public var snippet: String?
    public var relevanceScore: Double?
    public var relatedEntityIds: [String]
    public var extractedAt: Date
}
```

### 2. 新增辅助计算属性

```swift
extension KnowledgeNode {
    
    /// 关联原始次数
    public var mentionCount: Int {
        sourceLinks.count
    }
    
    /// 来源类型分布
    public var sourceTypeDistribution: [String: Int] {
        Dictionary(grouping: sourceLinks, by: { $0.sourceType })
            .mapValues { $0.count }
    }
    
    /// 是否有来源数据
    public var hasSourceData: Bool {
        !sourceLinks.isEmpty
    }
}
```

---

## UI Design

### 1. 关联原始次数视图

```
┌─────────────────────────────────────────────────────────────┐
│  📊 关联原始次数                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  关联 5 条原始数据                                       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 2. 来源类型分布视图

**单条来源时：**
```
┌─────────────────────────────────────────────────────────────┐
│  📖 来源：日记 1 条                                          │
└─────────────────────────────────────────────────────────────┘
```

**多条来源时：**
```
┌─────────────────────────────────────────────────────────────┐
│  📖 日记 3 条                                                │
│  💬 AI对话 2 条                                              │
│  ✅ 追踪器 1 条                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3. 时间信息视图（简化）

```
┌─────────────────────────────────────────────────────────────┐
│  ➕ 创建时间    2024-12-15 10:30                             │
│  🔄 更新时间    2025-01-02 14:20                             │
│  // 移除: ✅ 确认时间                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Mention Count Equals SourceLinks Count

*For any* KnowledgeNode instance, the mentionCount property SHALL equal the count of sourceLinks array.

**Validates: Requirements 1.2**

### Property 2: Source Type Distribution Accuracy

*For any* KnowledgeNode with sourceLinks, grouping by sourceType and summing counts SHALL equal the total sourceLinks count.

**Validates: Requirements 2.1**

### Property 3: Data Model Serialization Round-Trip

*For any* valid KnowledgeNode instance (including NodeSource and NodeVerification), serializing to JSON then deserializing SHALL produce an equivalent object with all fields preserved.

**Validates: Requirements 3.4, 5.2**

---

## Error Handling

### 1. 空来源数据处理

| 场景 | 处理方式 |
|------|----------|
| sourceLinks 为空 | 显示"暂无来源数据" |
| sourceType 未知 | 显示"其他"类型 |

### 2. 编辑交互错误处理

| 场景 | 处理方式 |
|------|----------|
| 编辑 Sheet 打开失败 | 显示错误提示 |
| 保存失败 | 显示错误提示，保留编辑内容 |

---

## Testing Strategy

### 单元测试

1. **关联原始次数计算测试**
   - 验证 mentionCount 等于 sourceLinks.count
   - 验证空 sourceLinks 返回 0

2. **来源类型分布计算测试**
   - 验证分组统计正确
   - 验证各类型计数之和等于总数

3. **数据模型向后兼容测试**
   - 验证旧格式 JSON 能正确解析
   - 验证新格式 JSON 能正确序列化

### 属性测试

使用 Swift 的 swift-testing 框架进行属性测试：

1. **关联次数一致性测试** (Property 1)
   - 生成随机 KnowledgeNode
   - 验证 mentionCount == sourceLinks.count

2. **来源分布完整性测试** (Property 2)
   - 生成随机 sourceLinks
   - 验证分组计数之和 == 总数

3. **序列化往返测试** (Property 3)
   - 生成随机 KnowledgeNode
   - 序列化 → 反序列化 → 比较

---

## Migration Notes

### UI 层面修改

1. **NodeSourceSection.swift**
   - 移除 confidenceView
   - 移除 verificationStatusView
   - 新增 mentionCountView
   - 重构 sourceTypeView

2. **KnowledgeNodeDetailSheet.swift**
   - 移除 canConfirm 逻辑
   - 移除确认按钮
   - 修复编辑 Sheet 交互（sheet over sheet）

3. **ConfidenceColors.swift / SourceTypeIcons.swift**
   - 可保留但不再使用置信度相关方法
   - 新增 DataSourceTypeIcons 辅助类

### 数据层面不变

- 所有数据模型保持不变
- 只是 UI 不再显示某些字段
- 确保向后兼容
