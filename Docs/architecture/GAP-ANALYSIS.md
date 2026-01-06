# L4 Profile Redesign - 差异分析文档

> 返回 [文档中心](../INDEX.md) | [L4 扩展规划](L4-PROFILE-EXPANSION-PLAN.md)

## 📋 文档说明

本文档详细分析 L4 核心知识层重构设计与现有代码之间的差异，为后续代码重构提供清晰的指导。

**分析范围**：
- `KnowledgeNodeModels.swift` - 知识节点核心模型
- `KnowledgeAPIModels.swift` - API 交互模型
- `AIPreferencesModels.swift` - AI 偏好模型
- `NarrativeProfileModels.swift` - 用户画像模型
- `NarrativeRelationshipModels.swift` - 关系模型
- `DimensionHierarchyModels.swift` - 维度层级模型（新增）

**文档状态**: 📝 规划中

---

## ✅ 已完成项清单

以下是现有代码中已实现的功能，可直接复用或作为重构基础。

### 1. 核心数据结构

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `KnowledgeNode` 基础结构 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 包含 id, nodeType, nodeCategory, name, description, tags, attributes, tracking, relations |
| `AttributeValue` 多类型支持 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 支持 string, int, double, bool, array, date 六种类型 |
| `NodeTracking` 追踪信息 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 包含 source, timeline, verification, changeHistory |
| `SourceLink` 溯源链接 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 包含 sourceType, sourceId, dayId, snippet, relevanceScore, extractedAt |
| `NodeRelation` 节点关联 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 支持 requires, conflictsWith, supports, relatedTo, partOf 关系类型 |
| `NodeChange` 变化记录 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 记录节点修改历史 |

### 2. 辅助枚举类型

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `NodeCategory` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | common / personal 分类 |
| `SourceType` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | userInput / aiExtracted / aiInferred |
| `NodeChangeType` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | created / updated / confirmed / deleted |
| `NodeChangeReason` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | userEdit / aiUpdate / correction / decay / enhancement |
| `RelationType` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 节点间关系类型 |

### 3. AI 偏好模型

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `AIPreferences` | `guanji0.34/Core/Models/AIPreferencesModels.swift` | ✅ 完整 | 包含 style, response, topics, tracking |
| `AIStylePreference` | `guanji0.34/Core/Models/AIPreferencesModels.swift` | ✅ 完整 | tone, verbosity, personality, language |
| `AIResponsePreference` | `guanji0.34/Core/Models/AIPreferencesModels.swift` | ✅ 完整 | preferredLength, includeExamples, includeEmoji, structuredFormat |
| `AITopicPreference` | `guanji0.34/Core/Models/AIPreferencesModels.swift` | ✅ 完整 | favorites, avoid, expertise |
| `generatePromptSnippet()` | `guanji0.34/Core/Models/AIPreferencesModels.swift` | ✅ 完整 | 生成系统提示词片段 |

### 4. 用户画像模型

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `NarrativeUserProfile` | `guanji0.34/Core/Models/NarrativeProfileModels.swift` | ✅ 完整 | 已包含 knowledgeNodes, aiPreferences 字段 |
| `StaticCore` | `guanji0.34/Core/Models/NarrativeProfileModels.swift` | ✅ 完整 | 用户基础信息 |
| `RecentPortrait` | `guanji0.34/Core/Models/NarrativeProfileModels.swift` | ✅ 完整 | AI 生成的近期画像 |
| `ProfileUpdateRecord` | `guanji0.34/Core/Models/NarrativeProfileModels.swift` | ✅ 完整 | 字段更新历史 |

### 5. 关系模型

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `NarrativeRelationship` | `guanji0.34/Core/Models/NarrativeRelationshipModels.swift` | ✅ 完整 | 已包含 attributes 字段（KnowledgeNode 数组） |
| `RelationshipFactAnchors` | `guanji0.34/Core/Models/NarrativeRelationshipModels.swift` | ✅ 完整 | 事实锚点 |
| `RelationshipMention` | `guanji0.34/Core/Models/NarrativeRelationshipModels.swift` | ✅ 完整 | 提及记录 |
| `Anniversary` | `guanji0.34/Core/Models/NarrativeRelationshipModels.swift` | ✅ 完整 | 纪念日 |

### 6. API 模型

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `ExtractedSourceLink` | `guanji0.34/Core/Models/KnowledgeAPIModels.swift` | ✅ 完整 | API 返回的简化溯源链接 |
| `ExtractedResult` | `guanji0.34/Core/Models/KnowledgeAPIModels.swift` | ✅ 完整 | AI 提取结果 |
| `SanitizedContext` | `guanji0.34/Core/Models/KnowledgeAPIModels.swift` | ✅ 完整 | 脱敏上下文 |
| `KnowledgeNodeSummary` | `guanji0.34/Core/Models/KnowledgeAPIModels.swift` | ✅ 完整 | 节点摘要 |

### 7. 验证与工具

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `KnowledgeNodeValidator` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 节点结构验证 |
| `calculateDecayedConfidence()` | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | 置信度衰减计算 |
| 工厂方法 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | createUserInput, createAIExtracted, createPersonal |
| 便捷访问器 | `guanji0.34/Core/Models/KnowledgeNodeModels.swift` | ✅ 完整 | skills, values, goals, hobbies, traits 等 |

### 8. 三层维度架构（新增）

| 项目 | 文件位置 | 实现状态 | 说明 |
|------|----------|----------|------|
| `NodeContentType` | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | ai_tag, subsystem, entity_ref, nested_list |
| `DimensionHierarchy` | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | Level1 枚举、level2Dimensions、level3Presets |
| `DimensionHierarchy.Level1` | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | 7 个一级维度定义 |
| Level 2 显示名称映射 | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | level2DisplayNames |
| Level 3 显示名称映射 | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | level3DisplayNames |
| 辅助方法 | `guanji0.34/Core/Models/DimensionHierarchyModels.swift` | ✅ 完整 | getLevel2Dimensions, getLevel3Presets, isValidLevel2 等 |



---

## 🔄 需重构项清单

以下是需要修改的现有代码，以支持三层维度架构和新功能。

### 1. KnowledgeNode 结构重构

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| `nodeType` 格式 | 扁平字符串 (`skill`, `value`, `goal`...) | 层级路径格式 (`self.personality.trait`) | 采用 `level1.level2.level3` 命名规范 |
| 新增 `contentType` | 不存在 | `NodeContentType` 枚举 | 支持 ai_tag, subsystem, entity_ref, nested_list |
| 新增 `sourceLinks` | 在 `tracking.source.extractedFrom` 内 | 节点顶层字段 | 移出 tracking，支持多对多关联 |
| 新增 `relatedEntityIds` | 不存在 | `[String]` 数组 | 关联的人物实体 ID 列表 |
| 新增 `childNodeIds` | 不存在 | `[String]?` 可选数组 | 嵌套列表的子节点 ID |
| 新增 `parentNodeId` | 不存在 | `String?` 可选字符串 | 父节点 ID |

**具体修改内容**:

```swift
// 当前结构
public struct KnowledgeNode: Codable, Identifiable {
    public let id: String
    public let nodeType: String                   // 扁平字符串
    public let nodeCategory: NodeCategory
    public var name: String
    public var description: String?
    public var tags: [String]
    public var attributes: [String: AttributeValue]
    public var tracking: NodeTracking
    public var relations: [NodeRelation]
    public let createdAt: Date
    public var updatedAt: Date
}

// 目标结构
public struct KnowledgeNode: Codable, Identifiable {
    public let id: String
    public let nodeType: String                   // 层级路径: "self.personality.trait"
    public let contentType: NodeContentType       // 🆕 内容类型
    public let nodeCategory: NodeCategory
    public var name: String
    public var description: String?
    public var tags: [String]
    public var attributes: [String: AttributeValue]
    public var sourceLinks: [SourceLink]          // 🆕 从 tracking 移出
    public var relatedEntityIds: [String]         // 🆕 关联实体
    public var childNodeIds: [String]?            // 🆕 子节点
    public var parentNodeId: String?              // 🆕 父节点
    public var tracking: NodeTracking             // 简化版
    public var relations: [NodeRelation]
    public let createdAt: Date
    public var updatedAt: Date
}
```

### 2. NodeSource 结构简化

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| `extractedFrom` 字段 | 存在于 NodeSource 内 | 移除 | 已移到节点顶层 sourceLinks |

**具体修改内容**:

```swift
// 当前结构
public struct NodeSource: Codable {
    public var type: SourceType
    public var confidence: Double?
    public var extractedFrom: [SourceLink]        // 需移除
}

// 目标结构
public struct NodeSource: Codable {
    public var type: SourceType
    public var confidence: Double?
    // extractedFrom 已移到 KnowledgeNode.sourceLinks
}
```

### 3. SourceLink 结构扩展

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| 新增 `relatedEntityIds` | 不存在 | `[String]` 数组 | 记录中提及的人物实体 |

**具体修改内容**:

```swift
// 当前结构
public struct SourceLink: Codable, Identifiable {
    public let id: String
    public var sourceType: String
    public var sourceId: String
    public var dayId: String
    public var snippet: String?
    public var relevanceScore: Double?
    public var extractedAt: Date
}

// 目标结构
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

### 4. nodeType 常量更新

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| `userProfileNodeTypes` | 10 个扁平类型 | 层级路径格式 | 更新为三层维度路径 |
| `relationshipNodeTypes` | 6 个扁平类型 | 层级路径格式 | 更新为三层维度路径 |

**具体修改内容**:

```swift
// 当前定义
public static let userProfileNodeTypes: [String] = [
    "skill", "value", "hobby", "goal", "trait",
    "fear", "fact", "lifestyle", "belief", "preference"
]

// 目标定义
public static let userProfileNodeTypes: [String] = [
    "achievements.competencies.professional_skills",  // skill
    "spirit.ideology.values",                         // value
    "experiences.culture_entertainment",              // hobby
    "spirit.ideology.visions_dreams",                 // goal
    "self.personality.self_assessment",               // trait
    "spirit.mental_state.stressors",                  // fear
    "experiences.history.milestones",                 // fact
    "self.physical.dietary_habits",                   // lifestyle
    "spirit.ideology.values",                         // belief
    "self.personality.behavioral_preferences"         // preference
]
```

### 5. 工厂方法更新

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| `createUserInput()` | 无 contentType 参数 | 添加 contentType 参数 | 默认 .aiTag |
| `createAIExtracted()` | sourceLinks 在 tracking 内 | sourceLinks 在节点顶层 | 调整参数位置 |
| `createPersonal()` | 无 contentType 参数 | 添加 contentType 参数 | 默认 .aiTag |

### 6. 便捷访问器更新

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

| 修改项 | 当前状态 | 目标状态 | 修改说明 |
|--------|----------|----------|----------|
| `skills` 属性 | 过滤 `nodeType == "skill"` | 过滤前缀 `achievements.competencies` | 适配层级路径 |
| `values` 属性 | 过滤 `nodeType == "value"` | 过滤前缀 `spirit.ideology.values` | 适配层级路径 |
| 其他便捷属性 | 扁平类型过滤 | 层级路径前缀过滤 | 全部更新 |

### 7. 初始化方法更新

**文件**: `guanji0.34/Core/Models/KnowledgeNodeModels.swift`

需要更新 `KnowledgeNode.init()` 方法，添加新字段的默认值：

```swift
public init(
    id: String = UUID().uuidString,
    nodeType: String,
    contentType: NodeContentType = .aiTag,        // 🆕 默认 aiTag
    nodeCategory: NodeCategory = .common,
    name: String,
    description: String? = nil,
    tags: [String] = [],
    attributes: [String: AttributeValue] = [:],
    sourceLinks: [SourceLink] = [],               // 🆕 默认空数组
    relatedEntityIds: [String] = [],              // 🆕 默认空数组
    childNodeIds: [String]? = nil,                // 🆕 默认 nil
    parentNodeId: String? = nil,                  // 🆕 默认 nil
    tracking: NodeTracking = NodeTracking(),
    relations: [NodeRelation] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
)
```



---

## ➕ 需新增项清单

以下是需要新增的类型、方法和工具，按优先级排序。

### P0 - 核心必需（已完成）

| 项目 | 说明 | 文件位置 | 状态 |
|------|------|----------|------|
| `NodeContentType` | 节点内容类型枚举 | `DimensionHierarchyModels.swift` | ✅ 已完成 |
| `DimensionHierarchy` | 维度层级定义结构 | `DimensionHierarchyModels.swift` | ✅ 已完成 |
| `DimensionHierarchy.Level1` | 7 个一级维度枚举 | `DimensionHierarchyModels.swift` | ✅ 已完成 |
| `level2Dimensions` | 15 个二级维度映射 | `DimensionHierarchyModels.swift` | ✅ 已完成 |
| `level3Presets` | Level 3 预设维度 | `DimensionHierarchyModels.swift` | ✅ 已完成 |
| 显示名称映射 | 中文显示名称 | `DimensionHierarchyModels.swift` | ✅ 已完成 |

### P0 - 核心必需（待实现）

| 项目 | 说明 | 建议文件位置 | 优先级 |
|------|------|--------------|--------|
| `NodeTypePath` | nodeType 路径解析工具 | `DimensionHierarchyModels.swift` | P0 |
| `nodeTypeMigrationMap` | 旧类型到新路径的映射表 | `DimensionHierarchyModels.swift` | P0 |

**NodeTypePath 实现建议**:

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

**nodeTypeMigrationMap 实现建议**:

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
```

### P1 - 扩展功能

| 项目 | 说明 | 建议文件位置 | 优先级 |
|------|------|--------------|--------|
| `KnowledgeNode.typePath` | 解析 nodeType 路径的计算属性 | `KnowledgeNodeModels.swift` | P1 |
| `KnowledgeNode.level1Dimension` | 获取 Level 1 维度的计算属性 | `KnowledgeNodeModels.swift` | P1 |
| `KnowledgeNode.hasValidDimensionPath` | 验证路径有效性的计算属性 | `KnowledgeNodeModels.swift` | P1 |
| `migrateNodeType()` | 旧格式自动转换方法 | `KnowledgeNodeModels.swift` | P1 |
| 按层级查询方法 | 按 Level 1/2 前缀过滤节点 | `KnowledgeNodeModels.swift` | P1 |

**KnowledgeNode 扩展实现建议**:

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
    
    /// 迁移旧 nodeType 到新格式
    public static func migrateNodeType(_ oldType: String) -> String {
        nodeTypeMigrationMap[oldType] ?? oldType
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 维度
    public func matchesLevel1(_ level1: DimensionHierarchy.Level1) -> Bool {
        nodeType.hasPrefix(level1.rawValue + ".")
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 和 Level 2 维度
    public func matchesLevel2(_ level1: DimensionHierarchy.Level1, _ level2: String) -> Bool {
        nodeType.hasPrefix("\(level1.rawValue).\(level2).")
    }
}
```

### P1 - 预留接口

| 项目 | 说明 | 建议文件位置 | 优先级 |
|------|------|--------------|--------|
| `RelationshipSubsystemInterface` | 关系子系统接口协议 | `NarrativeRelationshipModels.swift` | P1 |
| `AIPreferencesSubsystemInterface` | AI偏好子系统接口协议 | `AIPreferencesModels.swift` | P1 |

**RelationshipSubsystemInterface 实现建议**:

```swift
/// 关系子系统接口（预留）
public protocol RelationshipSubsystemInterface {
    /// 获取所有关系
    func getAllRelationships() -> [NarrativeRelationship]
    
    /// 根据ID获取关系
    func getRelationship(byId id: String) -> NarrativeRelationship?
    
    /// 根据名称匹配关系
    func matchRelationship(name: String) -> NarrativeRelationship?
    
    /// 获取与某关系相关的所有数据
    func getRelatedData(relationshipId: String) -> [SourceLink]
}
```

**AIPreferencesSubsystemInterface 实现建议**:

```swift
/// AI偏好子系统接口（预留）
public protocol AIPreferencesSubsystemInterface {
    /// 获取AI偏好设置
    func getPreferences() -> AIPreferences?
    
    /// 更新AI偏好设置
    func updatePreferences(_ preferences: AIPreferences)
    
    /// 生成系统提示词片段
    func generatePromptSnippet() -> String?
}
```

### P2 - 高级功能

| 项目 | 说明 | 建议文件位置 | 优先级 |
|------|------|--------------|--------|
| 嵌套节点遍历方法 | 递归获取子节点 | `KnowledgeNodeModels.swift` | P2 |
| 实体引用解析方法 | 解析 `[REL_ID:name]` 格式 | `KnowledgeNodeModels.swift` | P2 |
| 批量迁移工具 | 批量转换旧数据 | 新建迁移工具文件 | P2 |
| 维度统计方法 | 按维度统计节点数量 | `KnowledgeNodeModels.swift` | P2 |



---

## ⚠️ 可废弃项清单

以下是可以废弃或需要重新评估的代码，提供处理建议。

### 1. 确定废弃项

| 项目 | 文件位置 | 废弃原因 | 处理建议 |
|------|----------|----------|----------|
| `NodeSource.extractedFrom` | `KnowledgeNodeModels.swift` | 已移到节点顶层 `sourceLinks` | Phase 5 移除，迁移时复制数据 |

**详细说明**:

`NodeSource.extractedFrom` 字段原本存储在 `tracking.source` 内部，现在设计将其移到 `KnowledgeNode` 顶层作为 `sourceLinks` 字段。这样做的好处是：
- 更直观的数据访问路径
- 支持多对多关联更清晰
- 简化 `NodeSource` 结构

**迁移步骤**:
1. Phase 2: 在 `KnowledgeNode` 添加 `sourceLinks` 字段
2. Phase 4: 读取时自动从 `tracking.source.extractedFrom` 迁移到 `sourceLinks`
3. Phase 5: 移除 `NodeSource.extractedFrom` 字段

### 2. 待评估项

| 项目 | 文件位置 | 评估原因 | 处理建议 |
|------|----------|----------|----------|
| `NodeCategory` | `KnowledgeNodeModels.swift` | 与 `contentType` 功能重叠 | 保留但调整含义 |
| 旧 `userProfileNodeTypes` | `KnowledgeNodeModels.swift` | 扁平类型已过时 | 更新为层级路径格式 |
| 旧 `relationshipNodeTypes` | `KnowledgeNodeModels.swift` | 扁平类型已过时 | 更新为层级路径格式 |

**NodeCategory 评估**:

当前 `NodeCategory` 有两个值：
- `common`: 系统预定义的共有维度
- `personal`: 用户或 AI 创建的个人独特维度

新设计中 `NodeContentType` 有四个值：
- `aiTag`: AI 生成的标签
- `subsystem`: 独立小系统
- `entityRef`: 实体引用
- `nestedList`: 嵌套列表

**建议处理方式**:
- **保留 `NodeCategory`**：两者描述的是不同维度
  - `NodeCategory` 描述节点的"归属"（系统预定义 vs 用户自定义）
  - `NodeContentType` 描述节点的"内容结构"（标签 vs 子系统 vs 引用 vs 列表）
- **调整含义**：
  - `common` → 系统预设的 Level 1/2 维度下的节点
  - `personal` → AI 动态创建的 Level 3 维度下的节点

### 3. 兼容性保留项

| 项目 | 文件位置 | 保留原因 | 处理建议 |
|------|----------|----------|----------|
| 旧 nodeType 格式支持 | `KnowledgeNodeModels.swift` | 向后兼容 | 读取时自动转换，写入时使用新格式 |
| `NodeSource.extractedFrom` | `KnowledgeNodeModels.swift` | 迁移期间兼容 | Phase 5 前保留，之后移除 |

**向后兼容策略**:

```swift
extension KnowledgeNode {
    /// 获取规范化的 nodeType（自动迁移旧格式）
    public var normalizedNodeType: String {
        // 如果是旧格式，自动转换
        if let newType = nodeTypeMigrationMap[nodeType] {
            return newType
        }
        return nodeType
    }
    
    /// 从 JSON 解码时自动迁移
    public init(from decoder: Decoder) throws {
        // ... 标准解码逻辑 ...
        
        // 自动迁移 sourceLinks
        if sourceLinks.isEmpty, let oldLinks = tracking.source.extractedFrom, !oldLinks.isEmpty {
            sourceLinks = oldLinks
        }
    }
}
```

### 4. 废弃时间线

| 阶段 | 时间点 | 废弃内容 | 说明 |
|------|--------|----------|------|
| Phase 2 | 重构 KnowledgeNode | 无 | 添加新字段，保留旧字段 |
| Phase 4 | 更新 nodeType | 旧 nodeType 常量 | 更新为新格式，保留迁移映射 |
| Phase 5 | 清理废弃代码 | `NodeSource.extractedFrom` | 确认数据迁移完成后移除 |
| 后续版本 | 稳定后 | 迁移映射表 | 确认无旧数据后可移除 |



---

## 📅 迁移计划时间线

### 5 阶段迁移计划详细说明

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           迁移计划总览                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4 ──► Phase 5                   │
│  新增类型     重构Node    重构Link    更新命名     清理代码                   │
│  (已完成)     (待实现)    (待实现)    (待实现)     (待实现)                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Phase 1: 新增类型定义 ✅ 已完成

**目标**: 添加新的类型定义，不影响现有功能

**状态**: ✅ 已完成

**完成内容**:

| 任务 | 文件 | 状态 |
|------|------|------|
| 创建 `NodeContentType` 枚举 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建 `DimensionHierarchy` 定义 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建 `DimensionHierarchy.Level1` 枚举 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建 `level2Dimensions` 映射 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建 `level3Presets` 映射 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建显示名称映射 | `DimensionHierarchyModels.swift` | ✅ 完成 |
| 创建辅助方法 | `DimensionHierarchyModels.swift` | ✅ 完成 |

**待完成内容**:

| 任务 | 文件 | 状态 |
|------|------|------|
| 创建 `NodeTypePath` 工具 | `DimensionHierarchyModels.swift` | 🔄 待实现 |
| 创建 `nodeTypeMigrationMap` | `DimensionHierarchyModels.swift` | 🔄 待实现 |

**验收标准**:
- [x] 新类型可以独立编译
- [x] 不影响现有代码运行
- [ ] 单元测试通过

---

### Phase 2: 重构 KnowledgeNode（向后兼容）

**目标**: 扩展 KnowledgeNode 结构，保持向后兼容

**状态**: 🔄 待实现

**任务清单**:

| 序号 | 任务 | 文件 | 说明 |
|------|------|------|------|
| 2.1 | 新增 `contentType` 字段 | `KnowledgeNodeModels.swift` | 默认值 `.aiTag` |
| 2.2 | 新增 `sourceLinks` 字段 | `KnowledgeNodeModels.swift` | 默认值 `[]` |
| 2.3 | 新增 `relatedEntityIds` 字段 | `KnowledgeNodeModels.swift` | 默认值 `[]` |
| 2.4 | 新增 `childNodeIds` 字段 | `KnowledgeNodeModels.swift` | 默认值 `nil` |
| 2.5 | 新增 `parentNodeId` 字段 | `KnowledgeNodeModels.swift` | 默认值 `nil` |
| 2.6 | 更新 `init()` 方法 | `KnowledgeNodeModels.swift` | 添加新参数 |
| 2.7 | 更新工厂方法 | `KnowledgeNodeModels.swift` | 支持新字段 |
| 2.8 | 添加 Codable 兼容逻辑 | `KnowledgeNodeModels.swift` | 旧数据读取兼容 |

**代码变更示例**:

```swift
// KnowledgeNode 新增字段
public struct KnowledgeNode: Codable, Identifiable {
    // ... 现有字段 ...
    
    // 🆕 新增字段
    public let contentType: NodeContentType
    public var sourceLinks: [SourceLink]
    public var relatedEntityIds: [String]
    public var childNodeIds: [String]?
    public var parentNodeId: String?
    
    // 自定义解码器（向后兼容）
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 解码现有字段...
        
        // 新字段使用默认值（向后兼容）
        contentType = try container.decodeIfPresent(NodeContentType.self, forKey: .contentType) ?? .aiTag
        sourceLinks = try container.decodeIfPresent([SourceLink].self, forKey: .sourceLinks) ?? []
        relatedEntityIds = try container.decodeIfPresent([String].self, forKey: .relatedEntityIds) ?? []
        childNodeIds = try container.decodeIfPresent([String].self, forKey: .childNodeIds)
        parentNodeId = try container.decodeIfPresent(String.self, forKey: .parentNodeId)
        
        // 自动迁移：从 tracking.source.extractedFrom 迁移到 sourceLinks
        if sourceLinks.isEmpty {
            sourceLinks = tracking.source.extractedFrom
        }
    }
}
```

**验收标准**:
- [ ] 新字段添加完成
- [ ] 旧数据可以正常读取（使用默认值）
- [ ] 新数据可以正常写入
- [ ] 单元测试通过

---

### Phase 3: 重构 SourceLink（向后兼容）

**目标**: 扩展 SourceLink 结构，支持实体关联

**状态**: 🔄 待实现

**任务清单**:

| 序号 | 任务 | 文件 | 说明 |
|------|------|------|------|
| 3.1 | 新增 `relatedEntityIds` 字段 | `KnowledgeNodeModels.swift` | 默认值 `[]` |
| 3.2 | 更新 `init()` 方法 | `KnowledgeNodeModels.swift` | 添加新参数 |
| 3.3 | 添加 Codable 兼容逻辑 | `KnowledgeNodeModels.swift` | 旧数据读取兼容 |

**代码变更示例**:

```swift
public struct SourceLink: Codable, Identifiable {
    // ... 现有字段 ...
    
    // 🆕 新增字段
    public var relatedEntityIds: [String]
    
    public init(
        id: String = UUID().uuidString,
        sourceType: String,
        sourceId: String,
        dayId: String,
        snippet: String? = nil,
        relevanceScore: Double? = nil,
        relatedEntityIds: [String] = [],  // 🆕 新参数
        extractedAt: Date = Date()
    ) {
        // ...
        self.relatedEntityIds = relatedEntityIds
    }
    
    // 自定义解码器（向后兼容）
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // ... 解码现有字段 ...
        relatedEntityIds = try container.decodeIfPresent([String].self, forKey: .relatedEntityIds) ?? []
    }
}
```

**验收标准**:
- [ ] 新字段添加完成
- [ ] 旧数据可以正常读取
- [ ] 单元测试通过

---

### Phase 4: 更新 nodeType 命名（向后兼容）

**目标**: 将扁平 nodeType 更新为层级路径格式

**状态**: 🔄 待实现

**任务清单**:

| 序号 | 任务 | 文件 | 说明 |
|------|------|------|------|
| 4.1 | 创建 `NodeTypePath` 工具 | `DimensionHierarchyModels.swift` | 路径解析 |
| 4.2 | 创建 `nodeTypeMigrationMap` | `DimensionHierarchyModels.swift` | 迁移映射 |
| 4.3 | 更新 `userProfileNodeTypes` | `KnowledgeNodeModels.swift` | 层级路径格式 |
| 4.4 | 更新 `relationshipNodeTypes` | `KnowledgeNodeModels.swift` | 层级路径格式 |
| 4.5 | 添加迁移逻辑 | `KnowledgeNodeModels.swift` | 读取时自动转换 |
| 4.6 | 更新便捷访问器 | `KnowledgeNodeModels.swift` | 适配新格式 |
| 4.7 | 添加 KnowledgeNode 扩展 | `KnowledgeNodeModels.swift` | typePath, level1Dimension 等 |

**代码变更示例**:

```swift
// 更新 userProfileNodeTypes
public static let userProfileNodeTypes: [String] = [
    "achievements.competencies.professional_skills",
    "spirit.ideology.values",
    "experiences.culture_entertainment",
    "spirit.ideology.visions_dreams",
    "self.personality.self_assessment",
    "spirit.mental_state.stressors",
    "experiences.history.milestones",
    "self.physical.dietary_habits",
    "self.personality.behavioral_preferences"
]

// 更新便捷访问器
extension NarrativeUserProfile {
    public var skills: [KnowledgeNode] {
        knowledgeNodes.filter { $0.nodeType.hasPrefix("achievements.competencies") }
    }
    
    public var values: [KnowledgeNode] {
        knowledgeNodes.filter { $0.nodeType.hasPrefix("spirit.ideology.values") }
    }
    
    // ... 其他访问器 ...
}
```

**验收标准**:
- [ ] NodeTypePath 工具实现完成
- [ ] 迁移映射表完整
- [ ] 旧格式自动转换正常
- [ ] 便捷访问器正常工作
- [ ] 单元测试通过

---

### Phase 5: 清理废弃代码

**目标**: 移除废弃代码，完成重构

**状态**: 🔄 待实现

**前置条件**:
- Phase 1-4 全部完成
- 数据迁移验证通过
- 无旧格式数据残留

**任务清单**:

| 序号 | 任务 | 文件 | 说明 |
|------|------|------|------|
| 5.1 | 移除 `NodeSource.extractedFrom` | `KnowledgeNodeModels.swift` | 确认数据已迁移 |
| 5.2 | 评估 `NodeCategory` | `KnowledgeNodeModels.swift` | 决定保留或调整 |
| 5.3 | 更新相关扩展方法 | `KnowledgeNodeModels.swift` | 移除废弃引用 |
| 5.4 | 更新文档 | 相关文档 | 反映最终结构 |
| 5.5 | 清理迁移代码 | `KnowledgeNodeModels.swift` | 移除临时兼容逻辑 |

**验收标准**:
- [ ] 废弃代码已移除
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] 代码审查通过

---

### 迁移风险与缓解措施

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据丢失 | 高 | 每个 Phase 前备份数据，提供回滚机制 |
| 兼容性问题 | 中 | 充分的向后兼容设计，渐进式迁移 |
| 性能下降 | 低 | 迁移逻辑仅在读取时执行一次 |
| 测试覆盖不足 | 中 | 每个 Phase 完成后进行完整测试 |

### 回滚策略

每个 Phase 都应该是可回滚的：

1. **Phase 1**: 删除新增的类型定义文件
2. **Phase 2**: 移除新增字段，恢复旧结构
3. **Phase 3**: 移除新增字段，恢复旧结构
4. **Phase 4**: 恢复旧的 nodeType 常量和访问器
5. **Phase 5**: 不可回滚（需要重新执行 Phase 1-4）

---

## 📊 总结

### 工作量估算

| 阶段 | 预估工时 | 复杂度 | 风险等级 |
|------|----------|--------|----------|
| Phase 1 | 2h | 低 | 低 |
| Phase 2 | 4h | 中 | 中 |
| Phase 3 | 1h | 低 | 低 |
| Phase 4 | 4h | 中 | 中 |
| Phase 5 | 2h | 低 | 低 |
| **总计** | **13h** | - | - |

### 依赖关系

```
Phase 1 (类型定义)
    │
    ▼
Phase 2 (KnowledgeNode 重构) ◄─── Phase 3 (SourceLink 重构)
    │
    ▼
Phase 4 (nodeType 更新)
    │
    ▼
Phase 5 (清理废弃代码)
```

### 下一步行动

1. ✅ 完成 Phase 1 剩余任务（NodeTypePath, nodeTypeMigrationMap）
2. 🔄 开始 Phase 2 实现
3. 📝 编写单元测试
4. 🔍 代码审查

---

**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**创建日期**: 2024-12-31  
**状态**: 规划中

