# Design Document

## Overview

本设计文档定义 L4 核心知识层的重构方案，核心目标是：
1. 分析对比"三层维度架构"与"原内核状态设计"的优劣
2. 验证前两层维度是否完整覆盖人生各方面
3. 输出重构后的 L4-PROFILE-EXPANSION-PLAN.md
4. 输出规划与实际代码的差异分析文档

---

## Architecture

### 1. 架构方案对比分析

#### 方案A：三层维度架构（新设计）

```
┌─────────────────────────────────────────────────────────────┐
│                    Life OS 维度体系                          │
├─────────────────────────────────────────────────────────────┤
│  Level 1 (固定): 7大一级维度                                 │
│  ├── 本体 (Self)                                            │
│  ├── 物质 (Material)                                        │
│  ├── 成就 (Achievements)                                    │
│  ├── 阅历 (Experiences)                                     │
│  ├── 精神 (Spirit)                                          │
│  ├── 关系 (Relationships) [预留]                            │
│  └── AI偏好 (AI_Preferences) [预留]                         │
├─────────────────────────────────────────────────────────────┤
│  Level 2 (固定): 15个二级维度                                │
│  ├── 身份认同、身体状态、性格特质                            │
│  ├── 经济状况、物品与环境、生活保障                          │
│  ├── 事业发展、个人能力、成果展示                            │
│  ├── 文化娱乐、探索足迹、人生历程                            │
│  └── 意识形态、心理状态、思考感悟                            │
├─────────────────────────────────────────────────────────────┤
│  Level 3 (动态): AI维护的细分领域                            │
│  └── 由AI根据用户数据动态创建和维护                          │
└─────────────────────────────────────────────────────────────┘
```

#### 方案B：原内核状态设计（现有设计）

```
┌─────────────────────────────────────────────────────────────┐
│                    KnowledgeNode 通用结构                    │
├─────────────────────────────────────────────────────────────┤
│  nodeCategory: common | personal                             │
│  nodeType: 可扩展字符串 (skill, value, goal, trait...)       │
│  + StaticCore (固定字段)                                     │
│  + RecentPortrait (AI生成)                                   │
└─────────────────────────────────────────────────────────────┘
```

#### 对比分析

| 维度 | 方案A: 三层维度架构 | 方案B: 原内核状态设计 |
|------|---------------------|----------------------|
| **数据组织** | 层级清晰，有明确的分类体系 | 扁平化，依赖 nodeType 字符串 |
| **扩展性** | Level 3 由 AI 动态扩展 | nodeType 可自由扩展 |
| **AI维护难度** | 低：AI 只需在已知框架内填充 | 高：AI 需要理解整个 nodeType 体系 |
| **用户理解成本** | 低：符合人类认知的分类方式 | 中：需要理解 nodeType 含义 |
| **实现复杂度** | 中：需要维护维度层级关系 | 低：通用结构，无层级 |
| **数据一致性** | 高：有明确的归属路径 | 中：可能出现 nodeType 冲突 |
| **查询效率** | 高：可按层级索引 | 中：需要遍历 nodeType |
| **向后兼容** | 需要迁移映射 | 天然兼容 |

#### 设计决策

**推荐方案：混合架构**

结合两种方案的优点：
1. **保留 KnowledgeNode 通用结构**：作为底层数据存储
2. **引入维度层级体系**：作为 nodeType 的组织框架
3. **nodeType 命名规范**：采用层级路径格式 `level1.level2.level3`

```swift
// 示例：nodeType 命名规范
"self.identity.social_roles"      // 本体 > 身份认同 > 社会角色
"material.economy.asset_status"   // 物质 > 经济状况 > 资产概况
"spirit.wisdom.reflections"       // 精神 > 思考感悟 > 反思复盘
```

**优势**：
- 保持现有 KnowledgeNode 结构不变，向后兼容
- 通过 nodeType 命名规范实现层级组织
- AI 可以在已知框架内动态创建 Level 3 维度
- 查询时可按前缀过滤实现层级查询

---

### 2. 维度完整性验证

#### 2.1 人生领域覆盖检查

| 人生领域 | 覆盖维度 | 完整性 |
|----------|----------|--------|
| 个人身份 | 本体 > 身份认同 | ✅ 完整 |
| 身体健康 | 本体 > 身体状态 | ✅ 完整 |
| 性格心理 | 本体 > 性格特质 | ✅ 完整 |
| 财务经济 | 物质 > 经济状况 | ✅ 完整 |
| 生活环境 | 物质 > 物品与环境 | ✅ 完整 |
| 安全保障 | 物质 > 生活保障 | ✅ 完整 |
| 职业发展 | 成就 > 事业发展 | ✅ 完整 |
| 能力技能 | 成就 > 个人能力 | ✅ 完整 |
| 成果荣誉 | 成就 > 成果展示 | ✅ 完整 |
| 文化娱乐 | 阅历 > 文化娱乐 | ✅ 完整 |
| 旅行探索 | 阅历 > 探索足迹 | ✅ 完整 |
| 人生经历 | 阅历 > 人生历程 | ✅ 完整 |
| 价值信仰 | 精神 > 意识形态 | ✅ 完整 |
| 情绪心理 | 精神 > 心理状态 | ✅ 完整 |
| 思考反思 | 精神 > 思考感悟 | ✅ 完整 |
| 人际关系 | 关系 (预留) | ⏳ 预留 |
| AI交互 | AI偏好 (预留) | ⏳ 预留 |

#### 2.2 维度归属合理性检查

| 检查项 | 当前归属 | 合理性 | 说明 |
|--------|----------|--------|------|
| 性格特质 | 本体 | ✅ 合理 | 性格是"我是谁"的核心部分 |
| 情绪感受 | 精神 > 心理状态 | ✅ 合理 | 情绪是精神层面的表现 |
| 价值观 | 精神 > 意识形态 | ✅ 合理 | 价值观是精神信仰的核心 |
| 技能 | 成就 > 个人能力 | ✅ 合理 | 技能是能力的具体表现 |
| 负债压力 | 物质 > 经济状况 | ✅ 合理 | 负债是经济状况的一部分 |
| 纪念日 | 阅历 > 人生历程 > 重要节点 | ✅ 合理 | 纪念日是人生重要节点 |

#### 2.3 潜在遗漏检查

| 可能遗漏领域 | 建议归属 | 处理方式 |
|--------------|----------|----------|
| 时间管理 | 本体 > 性格特质 > 行为偏好 | Level 3 动态创建 |
| 社交网络 | 关系 (预留子系统) | 后续实现 |
| 宠物/家庭成员 | 关系 (预留子系统) | 后续实现 |
| 宗教信仰 | 精神 > 意识形态 > 价值观 | Level 3 动态创建 |
| 政治倾向 | 精神 > 意识形态 | Level 3 动态创建 |

**结论**：前两层维度已完整覆盖人生主要方面，遗漏项可通过 Level 3 动态创建或预留子系统解决。

---

## Components and Interfaces

### 1. 维度层级注册表

```swift
/// 维度层级定义
public struct DimensionHierarchy {
    /// Level 1 维度枚举
    public enum Level1: String, CaseIterable {
        case self_ = "self"           // 本体
        case material = "material"     // 物质
        case achievements = "achievements" // 成就
        case experiences = "experiences"   // 阅历
        case spirit = "spirit"         // 精神
        case relationships = "relationships" // 关系 [预留]
        case aiPreferences = "ai_preferences" // AI偏好 [预留]
        
        public var isReserved: Bool {
            self == .relationships || self == .aiPreferences
        }
        
        public var displayName: String {
            switch self {
            case .self_: return "本体"
            case .material: return "物质"
            case .achievements: return "成就"
            case .experiences: return "阅历"
            case .spirit: return "精神"
            case .relationships: return "关系"
            case .aiPreferences: return "AI偏好"
            }
        }
    }
    
    /// Level 2 维度定义
    public static let level2Dimensions: [Level1: [String]] = [
        .self_: ["identity", "physical", "personality"],
        .material: ["economy", "objects_space", "security"],
        .achievements: ["career", "competencies", "outcomes"],
        .experiences: ["culture_entertainment", "exploration", "history"],
        .spirit: ["ideology", "mental_state", "wisdom"]
    ]
    
    /// Level 3 预设维度（可由AI动态扩展）
    public static let level3Presets: [String: [String]] = [
        "self.identity": ["social_roles", "professional_identity", "appearance_style"],
        "self.physical": ["health_condition", "sleep_quality", "dietary_habits"],
        "self.personality": ["self_assessment", "behavioral_preferences"],
        "material.economy": ["asset_status", "consumption", "debt_pressure"],
        "material.objects_space": ["possessions", "living_environment", "collections"],
        "material.security": ["insurance_safety"],
        "achievements.career": ["work_experience", "business_activities"],
        "achievements.competencies": ["professional_skills", "education_learning", "life_talents"],
        "achievements.outcomes": ["personal_creations", "recognition_awards"],
        "experiences.culture_entertainment": ["reading", "movies_music", "gaming"],
        "experiences.exploration": ["travel_stories", "lifestyle_exploration"],
        "experiences.history": ["milestones", "memories"],
        "spirit.ideology": ["values", "visions_dreams"],
        "spirit.mental_state": ["emotions", "stressors"],
        "spirit.wisdom": ["opinions", "reflections"]
    ]
}
```

### 2. nodeType 路径工具

```swift
/// nodeType 路径解析工具
public struct NodeTypePath {
    public let level1: String
    public let level2: String?
    public let level3: String?
    
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
}
```

### 3. KnowledgeNode 扩展

```swift
extension KnowledgeNode {
    /// 解析 nodeType 路径
    public var typePath: NodeTypePath? {
        NodeTypePath(nodeType: nodeType)
    }
    
    /// 获取 Level 1 维度
    public var level1Dimension: DimensionHierarchy.Level1? {
        typePath.flatMap { DimensionHierarchy.Level1(rawValue: $0.level1) }
    }
    
    /// 检查是否为有效的维度路径
    public var hasValidDimensionPath: Bool {
        typePath?.isValid() ?? false
    }
}
```

### 4. 关系子系统接口预留

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

### 5. AI偏好子系统接口预留

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

---

## Data Models

### 1. 核心设计：L3 的特异性与无限扩展

L3 层需要支持多种不同类型的内容，每种类型有不同的数据结构需求：

| L3 内容类型 | 说明 | 数据特点 |
|------------|------|----------|
| `ai_tag` | AI生成的标签 | 只有 name + description + sourceLinks |
| `subsystem` | 独立小系统 | 有固定 schema（如个人信息：血型、姓名等） |
| `entity_ref` | 实体引用 | 指向关系表中的人物 |
| `nested_list` | 嵌套列表 | 下面还有子节点列表 |

### 2. 重构后的 KnowledgeNode 结构

```swift
/// 通用知识节点 - L4 层的核心数据结构（重构版）
public struct KnowledgeNode: Codable, Identifiable {
    // ===== 基础标识 =====
    public let id: String
    public let nodeType: String               // 层级路径: "achievements.competencies.professional_skills"
    
    // ===== 🆕 内容类型（L3特异性支持） =====
    public let contentType: NodeContentType   // ai_tag | subsystem | entity_ref | nested_list
    
    // ===== 核心内容 =====
    public var name: String                   // 节点名称
    public var description: String?           // 描述（AI生成的解释）
    public var tags: [String]                 // 用户自定义标签
    
    // ===== 动态属性（subsystem类型用） =====
    public var attributes: [String: AttributeValue]
    
    // ===== 🆕 关联关系（多对多支持） =====
    public var sourceLinks: [SourceLink]      // 变化历史/关联原文（从tracking移出）
    public var relatedEntityIds: [String]     // 关联的人物实体ID
    
    // ===== 🆕 嵌套结构支持 =====
    public var childNodeIds: [String]?        // 子节点ID列表（nested_list用）
    public var parentNodeId: String?          // 父节点ID
    
    // ===== 追踪信息（简化） =====
    public var tracking: NodeTracking         // 来源、置信度、验证状态
    
    // ===== 时间戳 =====
    public let createdAt: Date
    public var updatedAt: Date
}

/// 🆕 节点内容类型
public enum NodeContentType: String, Codable {
    case aiTag = "ai_tag"           // AI生成的标签（只有解释+关联原文）
    case subsystem = "subsystem"     // 独立小系统（有固定schema）
    case entityRef = "entity_ref"    // 实体引用（指向关系表）
    case nestedList = "nested_list"  // 嵌套列表（有子节点）
}
```

### 3. SourceLink 重构（支持多对多）

```swift
/// 溯源链接 - 连接 L4 知识节点与 L1 原始数据（重构版）
public struct SourceLink: Codable, Identifiable {
    public let id: String
    
    // ===== L1 来源定位 =====
    public var sourceType: String             // diary | conversation | tracker | mindState
    public var sourceId: String               // 具体记录 ID
    public var dayId: String                  // 所属日期 (YYYY-MM-DD)
    
    // ===== 内容片段 =====
    public var snippet: String?               // 相关文本片段
    public var relevanceScore: Double?        // 相关性评分 0.0 ~ 1.0
    
    // ===== 🆕 关联实体 =====
    public var relatedEntityIds: [String]     // 这条记录中提及的人物实体
    
    // ===== 时间戳 =====
    public var extractedAt: Date
}
```

### 4. NodeTracking 简化

```swift
/// 节点追踪信息（简化版，sourceLinks已移出）
public struct NodeTracking: Codable {
    public var source: NodeSource             // 来源类型 + 置信度
    public var timeline: NodeTimeline         // 时间线
    public var verification: NodeVerification // 验证状态
    public var changeHistory: [NodeChange]    // 变化历史
}

/// 节点来源（简化，extractedFrom已移到节点级别）
public struct NodeSource: Codable {
    public var type: SourceType               // user_input | ai_extracted | ai_inferred
    public var confidence: Double?            // 0.0 ~ 1.0
}
```

### 5. 维度层级定义

```swift
/// 维度层级定义
public struct DimensionHierarchy {
    /// Level 1 维度枚举
    public enum Level1: String, CaseIterable {
        case self_ = "self"
        case material = "material"
        case achievements = "achievements"
        case experiences = "experiences"
        case spirit = "spirit"
        case relationships = "relationships"      // 预留
        case aiPreferences = "ai_preferences"     // 预留
    }
    
    /// Level 2 维度定义
    public static let level2Dimensions: [Level1: [String]] = [
        .self_: ["identity", "physical", "personality"],
        .material: ["economy", "objects_space", "security"],
        .achievements: ["career", "competencies", "outcomes"],
        .experiences: ["culture_entertainment", "exploration", "history"],
        .spirit: ["ideology", "mental_state", "wisdom"]
    ]
    
    /// Level 3 预设维度
    public static let level3Presets: [String: [String]] = [
        "self.identity": ["social_roles", "professional_identity", "appearance_style", "personal_info"],
        "self.physical": ["health_condition", "sleep_quality", "dietary_habits"],
        "self.personality": ["self_assessment", "behavioral_preferences"],
        // ... 其他预设
    ]
}
```

### 6. nodeType 迁移映射

```swift
/// 旧 nodeType 到新路径的映射
public let nodeTypeMigrationMap: [String: String] = [
    "skill": "achievements.competencies.professional_skills",
    "value": "spirit.ideology.values",
    "hobby": "experiences.culture_entertainment",
    "goal": "spirit.ideology.visions_dreams",
    "trait": "self.personality.self_assessment",
    "fear": "spirit.mental_state.stressors",
    "fact": "experiences.history.milestones",
    "lifestyle": "self.physical.dietary_habits",
    "belief": "spirit.ideology.values",
    "preference": "self.personality.behavioral_preferences"
]
```

### 7. 使用示例

**示例1：AI生成的技能标签**
```json
{
    "id": "node_001",
    "nodeType": "achievements.competencies.professional_skills",
    "contentType": "ai_tag",
    "name": "Swift编程",
    "description": "iOS开发主力语言，熟练程度高",
    "sourceLinks": [
        {"dayId": "2024-01-15", "snippet": "开始学习Swift...", "relatedEntityIds": []},
        {"dayId": "2024-06-10", "snippet": "和小明讨论Swift...", "relatedEntityIds": ["REL_xxx"]}
    ],
    "relatedEntityIds": ["REL_xxx"]
}
```

**示例2：独立小系统（个人信息）**
```json
{
    "id": "node_002",
    "nodeType": "self.identity.personal_info",
    "contentType": "subsystem",
    "name": "个人基础信息",
    "attributes": {
        "blood_type": "A",
        "zodiac": "狮子座",
        "mbti": "INTJ",
        "height": 175
    },
    "sourceLinks": []
}
```

**示例3：嵌套列表**
```json
{
    "id": "node_003",
    "nodeType": "experiences.culture_entertainment.reading",
    "contentType": "nested_list",
    "name": "阅读",
    "childNodeIds": ["node_003_1", "node_003_2"]
}
```

---


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: KnowledgeNode Serialization Round-Trip

*For any* valid KnowledgeNode instance, serializing to JSON then deserializing SHALL produce an equivalent object with all fields preserved, including AttributeValue types and optional fields.

**Validates: Requirements 13.1, 13.3, 13.4**

### Property 2: NodeTypePath Parsing Consistency

*For any* valid nodeType string in the format "level1.level2.level3", parsing then reconstructing the fullPath SHALL produce the original string.

**Validates: Requirements 3.1, 4.1-8.4**

### Property 3: Dimension Hierarchy Completeness

*For any* Level 1 dimension that is not reserved, there SHALL exist at least one Level 2 dimension defined in level2Dimensions.

**Validates: Requirements 3.4, 4.1, 5.1, 6.1, 7.1, 8.1**

---

## Error Handling

### 1. nodeType 路径验证错误

| 错误场景 | 处理方式 |
|----------|----------|
| 无效的 Level 1 维度 | 返回验证错误，拒绝创建 |
| 无效的 Level 2 维度 | 返回验证错误，拒绝创建 |
| Level 3 不在预设中 | 允许创建（AI动态扩展） |
| 空 nodeType | 返回验证错误 |

### 2. 数据迁移错误

| 错误场景 | 处理方式 |
|----------|----------|
| 旧 nodeType 无法映射 | 放入 "legacy" 分类，标记待人工审核 |
| 数据格式不兼容 | 保留原数据，记录迁移失败日志 |

### 3. 序列化错误

| 错误场景 | 处理方式 |
|----------|----------|
| AttributeValue 类型未知 | 抛出 DecodingError |
| 必填字段缺失 | 抛出 DecodingError |
| 可选字段缺失 | 使用默认值 |

---

## Testing Strategy

### 单元测试

1. **维度层级结构测试**
   - 验证 Level 1 有 7 个维度
   - 验证 5 个核心维度的 Level 2 结构
   - 验证 Level 3 预设完整性

2. **nodeType 路径解析测试**
   - 有效路径解析
   - 无效路径拒绝
   - 边界情况处理

3. **迁移映射测试**
   - 旧 nodeType 正确映射到新路径
   - 未知 nodeType 处理

### 属性测试

使用 Swift 的 swift-testing 框架进行属性测试：

1. **序列化往返测试** (Property 1)
   - 生成随机 KnowledgeNode
   - 序列化 → 反序列化 → 比较

2. **路径解析一致性测试** (Property 2)
   - 生成随机有效路径
   - 解析 → 重构 → 比较

---

## Gap Analysis: 规划与实际代码差异

### 1. 已完成项 ✅

| 项目 | 文件位置 | 状态 |
|------|----------|------|
| KnowledgeNode 基础结构 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| AttributeValue 多类型支持 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| NodeTracking 追踪信息 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| SourceLink 溯源链接 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| NodeRelation 节点关联 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| AIPreferences 基础结构 | `AIPreferencesModels.swift` | ✅ 完整实现 |
| NarrativeUserProfile 扩展 | `NarrativeProfileModels.swift` | ✅ 已添加 knowledgeNodes, aiPreferences |
| NarrativeRelationship 扩展 | `NarrativeRelationshipModels.swift` | ✅ 已添加 attributes |
| KnowledgeNodeValidator | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| ExtractedSourceLink (API) | `KnowledgeAPIModels.swift` | ✅ 完整实现 |

### 2. 需重构项 🔄

| 项目 | 当前状态 | 需要修改 |
|------|----------|----------|
| KnowledgeNode.nodeType | 扁平字符串 (skill, value...) | 改为层级路径 (self.personality.trait) |
| KnowledgeNode 结构 | 无 contentType | 新增 contentType 字段 |
| KnowledgeNode 结构 | sourceLinks 在 tracking.source 内 | 移到节点顶层 |
| KnowledgeNode 结构 | 无嵌套支持 | 新增 childNodeIds, parentNodeId |
| KnowledgeNode 结构 | 无实体关联 | 新增 relatedEntityIds |
| SourceLink 结构 | 无实体关联 | 新增 relatedEntityIds |
| NodeSource 结构 | 包含 extractedFrom | 移除（已移到节点级别） |
| NodeCategory | common/personal | 考虑是否废弃或调整含义 |
| userProfileNodeTypes | 10个扁平类型 | 更新为层级路径格式 |
| relationshipNodeTypes | 6个扁平类型 | 更新为层级路径格式 |

### 3. 需新增项 ➕

| 项目 | 说明 | 优先级 |
|------|------|--------|
| NodeContentType | 节点内容类型枚举 (ai_tag, subsystem, entity_ref, nested_list) | P0 |
| DimensionHierarchy | 维度层级定义枚举和静态数据 | P0 |
| NodeTypePath | nodeType 路径解析工具 | P0 |
| nodeTypeMigrationMap | 旧类型到新路径的映射表 | P1 |
| KnowledgeNode 扩展方法 | 按层级查询、嵌套遍历等 | P1 |

### 4. 可废弃项 ⚠️

| 项目 | 说明 | 处理建议 |
|------|------|----------|
| NodeCategory | common/personal 区分 | 可保留但调整含义，或用 contentType 替代 |
| NodeSource.extractedFrom | 已移到节点级别 | 废弃，使用节点级 sourceLinks |

### 5. 迁移计划

```
Phase 1: 新增类型定义（不影响现有功能）
├── 创建 NodeContentType 枚举
├── 创建 DimensionHierarchy 定义
├── 创建 NodeTypePath 工具
└── 创建 nodeTypeMigrationMap

Phase 2: 重构 KnowledgeNode（向后兼容）
├── 新增 contentType 字段（默认 .aiTag）
├── 新增 sourceLinks 字段（从 tracking.source.extractedFrom 迁移）
├── 新增 relatedEntityIds 字段
├── 新增 childNodeIds, parentNodeId 字段
└── 更新初始化方法和工厂方法

Phase 3: 重构 SourceLink（向后兼容）
├── 新增 relatedEntityIds 字段
└── 更新初始化方法

Phase 4: 更新 nodeType 命名（向后兼容）
├── 更新 userProfileNodeTypes 为层级路径
├── 更新 relationshipNodeTypes 为层级路径
├── 添加迁移逻辑：读取时自动转换旧格式
└── 写入时使用新格式

Phase 5: 清理废弃代码
├── 移除 NodeSource.extractedFrom
├── 评估 NodeCategory 是否保留
└── 更新相关扩展方法
```

---

## 输出文档规划

### 1. 重构后的 L4-PROFILE-EXPANSION-PLAN.md

更新内容：
- 替换"通用节点 + 共有/个人维度"为"三层维度架构 + L3特异性"
- 添加完整的 Life OS 维度体系定义
- 添加 NodeContentType 和 L3 类型说明
- 更新 KnowledgeNode 结构定义
- 更新 SourceLink 结构定义
- 添加多对多关联设计
- 添加嵌套列表支持
- 更新迁移策略

### 2. 差异分析文档 (GAP-ANALYSIS.md)

内容：
- 已完成项清单
- 需重构项清单及具体修改内容
- 需新增项清单及实现建议
- 可废弃项清单
- 迁移计划时间线
