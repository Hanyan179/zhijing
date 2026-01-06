# Design Document

## Overview

本设计文档定义 L4 核心知识层代码重构的技术实现方案。基于已完成的架构设计，进行实际代码修改。

**参考文档**：
- #[[file:Docs/architecture/L4-PROFILE-EXPANSION-PLAN.md]] - 完整架构设计
- #[[file:Docs/architecture/GAP-ANALYSIS.md]] - 差异分析和迁移计划

---

## Architecture

### 重构范围

```
guanji0.34/Core/Models/
├── DimensionHierarchyModels.swift  # 新增 NodeTypePath、迁移映射
└── KnowledgeNodeModels.swift       # 重构 KnowledgeNode、SourceLink、NodeSource
```

### 依赖关系

```
DimensionHierarchyModels.swift
    │
    ▼
KnowledgeNodeModels.swift (imports DimensionHierarchy)
```

---

## Components and Interfaces

### 1. NodeTypePath 路径解析工具

```swift
/// nodeType 路径解析工具
public struct NodeTypePath {
    public let level1: String
    public let level2: String?
    public let level3: String?
    
    /// 完整路径字符串
    public var fullPath: String {
        [level1, level2, level3].compactMap { $0 }.joined(separator: ".")
    }
    
    /// 从 nodeType 字符串解析
    public init?(nodeType: String) {
        let components = nodeType.split(separator: ".").map(String.init)
        guard !components.isEmpty else { return nil }
        self.level1 = components[0]
        self.level2 = components.count > 1 ? components[1] : nil
        self.level3 = components.count > 2 ? components[2] : nil
    }
    
    /// 验证路径是否有效
    public func isValid() -> Bool {
        guard let l1 = DimensionHierarchy.Level1(rawValue: level1) else { return false }
        if let l2 = level2 {
            guard DimensionHierarchy.level2Dimensions[l1]?.contains(l2) == true else { return false }
        }
        return true
    }
    
    /// 获取 Level 1 维度
    public var level1Dimension: DimensionHierarchy.Level1? {
        DimensionHierarchy.Level1(rawValue: level1)
    }
}
```

### 2. nodeTypeMigrationMap 迁移映射

```swift
/// 旧 nodeType 到新路径的映射
public let nodeTypeMigrationMap: [String: String] = [
    // 用户画像维度
    "skill": "achievements.competencies.professional_skills",
    "value": "spirit.ideology.values",
    "hobby": "experiences.culture_entertainment",
    "goal": "spirit.ideology.visions_dreams",
    "trait": "self.personality.self_assessment",
    "fear": "spirit.mental_state.stressors",
    "fact": "experiences.history.milestones",
    "lifestyle": "self.physical.dietary_habits",
    "belief": "spirit.ideology.values",
    "preference": "self.personality.behavioral_preferences",
    
    // 关系画像维度
    "relationship_status": "relationships.status",
    "interaction_pattern": "relationships.interaction",
    "emotional_connection": "relationships.emotional",
    "shared_memory": "relationships.memories",
    "health_status": "relationships.health",
    "life_event": "relationships.events"
]

/// 迁移旧 nodeType 到新格式
public func migrateNodeType(_ oldType: String) -> String {
    nodeTypeMigrationMap[oldType] ?? oldType
}
```

### 3. KnowledgeNode 重构结构

```swift
public struct KnowledgeNode: Codable, Identifiable {
    // ===== 基础标识 =====
    public let id: String
    public let nodeType: String
    public let contentType: NodeContentType       // 🆕 内容类型
    public let nodeCategory: NodeCategory
    
    // ===== 核心内容 =====
    public var name: String
    public var description: String?
    public var tags: [String]
    public var attributes: [String: AttributeValue]
    
    // ===== 🆕 关联关系 =====
    public var sourceLinks: [SourceLink]          // 从 tracking.source 移出
    public var relatedEntityIds: [String]         // 关联实体 ID
    
    // ===== 🆕 嵌套结构 =====
    public var childNodeIds: [String]?            // 子节点 ID
    public var parentNodeId: String?              // 父节点 ID
    
    // ===== 追踪信息 =====
    public var tracking: NodeTracking
    public var relations: [NodeRelation]
    
    // ===== 时间戳 =====
    public let createdAt: Date
    public var updatedAt: Date
}
```

### 4. SourceLink 重构结构

```swift
public struct SourceLink: Codable, Identifiable {
    public let id: String
    public var sourceType: String
    public var sourceId: String
    public var dayId: String
    public var snippet: String?
    public var relevanceScore: Double?
    public var relatedEntityIds: [String]         // 🆕 关联实体
    public var extractedAt: Date
}
```

### 5. KnowledgeNode 扩展方法

```swift
extension KnowledgeNode {
    /// 解析 nodeType 路径
    public var typePath: NodeTypePath? {
        NodeTypePath(nodeType: nodeType)
    }
    
    /// 获取 Level 1 维度
    public var level1Dimension: DimensionHierarchy.Level1? {
        typePath?.level1Dimension
    }
    
    /// 检查是否为有效的维度路径
    public var hasValidDimensionPath: Bool {
        typePath?.isValid() ?? false
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 维度
    public func matchesLevel1(_ level1: DimensionHierarchy.Level1) -> Bool {
        nodeType.hasPrefix(level1.rawValue + ".") || nodeType == level1.rawValue
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 和 Level 2 维度
    public func matchesLevel2(_ level1: DimensionHierarchy.Level1, _ level2: String) -> Bool {
        nodeType.hasPrefix("\(level1.rawValue).\(level2).")
    }
}
```

---

## Data Models

### 新增字段默认值

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| contentType | NodeContentType | .aiTag | 节点内容类型 |
| sourceLinks | [SourceLink] | [] | 溯源链接 |
| relatedEntityIds | [String] | [] | 关联实体 ID |
| childNodeIds | [String]? | nil | 子节点 ID |
| parentNodeId | String? | nil | 父节点 ID |

### nodeType 更新映射

| 旧格式 | 新格式 |
|--------|--------|
| skill | achievements.competencies.professional_skills |
| value | spirit.ideology.values |
| hobby | experiences.culture_entertainment |
| goal | spirit.ideology.visions_dreams |
| trait | self.personality.self_assessment |
| fear | spirit.mental_state.stressors |
| fact | experiences.history.milestones |
| lifestyle | self.physical.dietary_habits |
| belief | spirit.ideology.values |
| preference | self.personality.behavioral_preferences |

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do.*

### Property 1: NodeTypePath Round-Trip

*For any* valid nodeType string in format "level1.level2.level3", parsing with NodeTypePath then accessing fullPath SHALL produce the original string.

**Validates: Requirements 1.6**

### Property 2: KnowledgeNode Serialization Round-Trip

*For any* valid KnowledgeNode instance with all new fields populated, serializing to JSON then deserializing SHALL produce an equivalent object with all fields preserved.

**Validates: Requirements 3.8**

### Property 3: Backward Compatibility

*For any* KnowledgeNode JSON without new fields (contentType, sourceLinks, relatedEntityIds, childNodeIds, parentNodeId), deserializing SHALL succeed with default values applied.

**Validates: Requirements 9.1, 9.2**

---

## Error Handling

### 解析错误

| 错误场景 | 处理方式 |
|----------|----------|
| 空 nodeType 字符串 | NodeTypePath 返回 nil |
| 无效 Level 1 维度 | isValid() 返回 false |
| 无效 Level 2 维度 | isValid() 返回 false |

### 迁移错误

| 错误场景 | 处理方式 |
|----------|----------|
| 未知旧 nodeType | migrateNodeType 返回原值 |
| 解码缺失新字段 | 使用默认值 |

---

## Testing Strategy

### 单元测试

1. **NodeTypePath 测试**
   - 有效路径解析
   - 无效路径处理
   - fullPath 重构
   - isValid 验证

2. **迁移映射测试**
   - 所有旧类型正确映射
   - 未知类型返回原值

3. **KnowledgeNode 测试**
   - 新字段初始化
   - 默认值正确
   - 扩展方法正确

4. **向后兼容测试**
   - 旧数据解码成功
   - 新字段使用默认值

### 属性测试

使用 Swift 的 swift-testing 框架：

1. **NodeTypePath Round-Trip** (Property 1)
   - 生成随机有效路径
   - 解析 → fullPath → 比较

2. **KnowledgeNode Serialization** (Property 2)
   - 生成随机 KnowledgeNode
   - 序列化 → 反序列化 → 比较

