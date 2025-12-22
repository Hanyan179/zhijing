# L4 层画像数据扩展规划

> 返回 [文档中心](../INDEX.md) | [数据架构](data-architecture.md)

## 📋 文档说明

本文档规划 L4 核心知识层的用户画像和关系画像的完整数据结构。

**核心设计理念**：
- 使用**通用知识节点 (KnowledgeNode)** 结构，而非固定 Schema
- 区分**共有维度**（系统预定义）和**个人独特维度**（用户/AI 创建）
- 结构规范一致，内容自由扩展
- 支持**溯源追踪**：每个知识点都能追溯到原始数据来源
- 支持**置信度机制**：AI 提取的信息有置信度，随时间衰减或增强

**状态**: ⭐ P0 已实现（数据结构）

---

## 🎯 设计哲学：通用节点 vs 固定 Schema

### 为什么不用固定 Schema？

| 问题 | 固定 Schema | 通用节点 |
|------|------------|---------|
| 添加新维度 | 改代码、改数据结构、重新编译 | 只加 nodeType 字符串 |
| 数据迁移 | 每次改动都要迁移旧数据 | 几乎不需要迁移 |
| AI 扩展 | 只能提取预定义维度 | 可自由创建新维度 |
| 个人差异 | 所有人结构相同 | 每人可有独特维度 |
| 验证复杂度 | 每个字段单独验证 | 统一结构验证 |
| 前端展示 | 每个字段单独 UI | 通用渲染器 + 模板 |

### 核心原则

1. **结构规范一致**：所有节点使用相同的 KnowledgeNode 结构
2. **内容自由扩展**：nodeType 和 attributes 可随时扩展
3. **共有 + 独特**：系统预定义共有维度，用户/AI 可创建独特维度
4. **向后兼容**：新版本自动兼容旧数据
5. **溯源可追**：每个知识点都能追溯到原始日记/对话
6. **置信度驱动**：AI 提取的信息有置信度，用户确认后提升

---

## 🏗️ 核心数据结构：KnowledgeNode

### 通用知识节点

```swift
/// 通用知识节点 - L4 层的核心数据结构
/// 用于存储用户画像和关系画像中的各种维度信息
struct KnowledgeNode: Codable, Identifiable {
    // ===== 唯一标识 =====
    let id: String                        // UUID
    
    // ===== 节点类型 =====
    let nodeType: String                  // 维度类型（可扩展字符串，如 "skill", "value", "goal"）
    let nodeCategory: NodeCategory        // common（系统预定义）| personal（用户/AI创建）
    
    // ===== 核心内容 =====
    var name: String                      // 节点名称（如 "Swift 编程", "家庭优先"）
    var description: String?              // 描述（可选）
    var tags: [String]                    // 用户自定义标签
    
    // ===== 动态属性（Key-Value） =====
    var attributes: [String: AttributeValue]  // 灵活的属性存储
    
    // ===== 追踪信息 =====
    var tracking: NodeTracking            // 来源、置信度、变化历史
    
    // ===== 关联关系 =====
    var relations: [NodeRelation]         // 与其他节点的关联
    
    // ===== 时间戳 =====
    let createdAt: Date
    var updatedAt: Date
}

/// 节点分类
enum NodeCategory: String, Codable {
    case common     // 共有维度：系统预定义，所有用户都可能有
    case personal   // 个人独特：用户或 AI 创建的独特维度
}
```

### 属性值类型

```swift
/// 属性值 - 支持多种数据类型
enum AttributeValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([String])
    case date(Date)
    
    // 便捷访问方法
    var stringValue: String? { ... }
    var intValue: Int? { ... }
    var doubleValue: Double? { ... }
    var boolValue: Bool? { ... }
    var arrayValue: [String]? { ... }
    var dateValue: Date? { ... }
}
```

### 追踪信息（NodeTracking）

```swift
/// 节点追踪信息 - 记录来源、置信度、变化历史
struct NodeTracking: Codable {
    // ===== 来源信息 =====
    var source: NodeSource
    
    // ===== 时间线 =====
    var timeline: NodeTimeline
    
    // ===== 确认状态 =====
    var verification: NodeVerification
    
    // ===== 变化历史 =====
    var changeHistory: [NodeChange]
}

/// 节点来源
struct NodeSource: Codable {
    var type: SourceType                  // user_input | ai_extracted | ai_inferred
    var confidence: Double?               // 0.0 ~ 1.0（仅 AI 来源有）
    var extractedFrom: [SourceLink]       // 溯源链接列表
}

/// 来源类型
enum SourceType: String, Codable {
    case userInput      // 用户手动输入
    case aiExtracted    // AI 从原始数据中提取
    case aiInferred     // AI 推断得出
}

/// 节点时间线
struct NodeTimeline: Codable {
    var firstDiscovered: Date             // 首次发现/创建
    var lastUpdated: Date                 // 最后更新
    var lastConfirmed: Date?              // 用户最后确认时间
}

/// 节点验证状态
struct NodeVerification: Codable {
    var confirmedByUser: Bool             // 用户是否已确认
    var needsReview: Bool                 // 是否需要用户审核
}
```

### 溯源链接（SourceLink）

```swift
/// 溯源链接 - 连接 L4 知识节点与 L1 原始数据
struct SourceLink: Codable, Identifiable {
    let id: String
    var sourceType: String                // diary | conversation | tracker | mindState
    var sourceId: String                  // 具体记录 ID（JournalEntry.id, AIMessage.id 等）
    var dayId: String                     // 所属日期 (YYYY-MM-DD)
    var snippet: String?                  // 相关文本片段（用于展示）
    var relevanceScore: Double?           // 相关性评分 0.0 ~ 1.0
    var extractedAt: Date                 // 提取时间
}
```

### 变化记录（NodeChange）

```swift
/// 节点变化记录 - 追踪节点的修改历史
struct NodeChange: Codable, Identifiable {
    let id: String
    var timestamp: Date
    var changeType: ChangeType            // created | updated | confirmed | deleted
    var field: String?                    // 变化的字段名（如 "name", "attributes.proficiency"）
    var oldValue: AttributeValue?         // 旧值
    var newValue: AttributeValue?         // 新值
    var reason: ChangeReason              // 变化原因
    var confidence: Double?               // 变化后的置信度
}

/// 变化类型
enum ChangeType: String, Codable {
    case created        // 新建
    case updated        // 更新
    case confirmed      // 用户确认
    case deleted        // 删除
}

/// 变化原因
enum ChangeReason: String, Codable {
    case userEdit       // 用户手动编辑
    case aiUpdate       // AI 自动更新
    case correction     // 纠正错误
    case decay          // 置信度衰减
    case enhancement    // 置信度增强（多次提及）
}
```

### 节点关联（NodeRelation）

```swift
/// 节点关联 - 描述节点之间的关系
struct NodeRelation: Codable, Identifiable {
    let id: String
    var targetNodeId: String              // 关联的目标节点 ID
    var relationType: RelationType        // 关联类型
    var strength: Double?                 // 关联强度 0.0 ~ 1.0
    var description: String?              // 关联描述
}

/// 关联类型
enum RelationType: String, Codable {
    case requires       // 依赖关系（如：技能A 需要 技能B）
    case conflictsWith  // 冲突关系（如：价值观A 与 价值观B 冲突）
    case supports       // 支持关系（如：目标A 支持 价值观B）
    case relatedTo      // 一般关联
    case partOf         // 从属关系（如：子目标 属于 大目标）
}
```

---

## 📊 维度分类：共有 vs 个人独特

### 设计理念

每个人都有一些共同的维度（如技能、价值观、目标），但每个人在这些维度上的具体内容不同。同时，每个人也可能有一些独特的维度（如特殊收藏、独特经历）。

```
┌─────────────────────────────────────────────────────────────┐
│                    KnowledgeNode 结构                        │
├─────────────────────────────────────────────────────────────┤
│  nodeCategory = "common"                                     │
│  ├── skill (技能)                                           │
│  ├── value (价值观)                                         │
│  ├── goal (目标)                                            │
│  ├── trait (性格特质)                                       │
│  ├── hobby (兴趣爱好)                                       │
│  ├── fear (恐惧担忧)                                        │
│  ├── fact (核心事实)                                        │
│  ├── lifestyle (生活方式)                                   │
│  ├── belief (信念)                                          │
│  └── preference (偏好)                                      │
├─────────────────────────────────────────────────────────────┤
│  nodeCategory = "personal"                                   │
│  ├── (用户自定义维度)                                       │
│  └── (AI 发现的独特维度)                                    │
└─────────────────────────────────────────────────────────────┘
```

### 共有维度（Common）- 用户画像

系统预定义，所有用户都可能有，有标准的属性模板供参考。

| nodeType | 中文名 | 说明 | 核心属性 | 示例 |
|----------|--------|------|----------|------|
| `skill` | 技能 | 用户掌握的技能 | proficiency, category, frequency, yearsOfExperience | Swift 编程 (advanced) |
| `value` | 价值观 | 核心价值观 | importance, manifestation | 家庭优先 (critical) |
| `hobby` | 兴趣爱好 | 业余爱好 | frequency, startedDate, investedTime | 摄影 (weekly) |
| `goal` | 目标 | 人生目标 | timeframe, status, progress, deadline | 学会日语 (in_progress, 30%) |
| `trait` | 性格特质 | 性格特征 | strength, context, isPositive | 内向 (strong, 社交场合) |
| `fear` | 恐惧担忧 | 焦虑点 | severity, trigger, copingStrategy | 公开演讲 (moderate) |
| `fact` | 核心事实 | 不容篡改的事实 | importance, date, isVerified | 2020年结婚 |
| `lifestyle` | 生活方式 | 生活习惯 | frequency, time, duration | 早起跑步 (daily, 6:00) |
| `belief` | 信念 | 人生信念 | strength, origin | 努力必有回报 |
| `preference` | 偏好 | 各类偏好 | category, strength, context | 喜欢安静环境工作 |

### 共有维度（Common）- 关系画像

用于描述与他人关系的维度。

| nodeType | 中文名 | 说明 | 核心属性 | 示例 |
|----------|--------|------|----------|------|
| `relationship_status` | 关系状态 | 当前关系状态 | state, healthScore, activityLevel, lastInteraction | 亲密 (healthy, active) |
| `interaction_pattern` | 互动模式 | 互动习惯 | frequency, channels, preferredTopics | 每周视频通话 |
| `emotional_connection` | 情感连接 | 情感纽带 | intensity, trust, tone, sharedValues | 深厚信任 |
| `shared_memory` | 共同记忆 | 重要共同经历 | date, emotion, importance, location | 一起去日本旅行 |
| `health_status` | 健康状态 | 亲人健康（仅家人） | condition, severity, treatment, lastCheckup | 高血压 (controlled) |
| `life_event` | 人生事件 | 对方的重要事件 | eventType, date, impact | 升职 (2024-06) |

### 个人独特维度（Personal）

用户或 AI 创建的独特维度，没有预定义模板。

```json
// 示例 1：用户创建的收藏维度
{
    "nodeType": "collection",
    "nodeCategory": "personal",
    "name": "黑胶唱片收藏",
    "description": "从大学开始收集的黑胶唱片",
    "attributes": {
        "count": 127,
        "favoriteGenre": "Jazz",
        "startedYear": 2015,
        "storageLocation": "书房"
    }
}

// 示例 2：AI 发现的独特维度
{
    "nodeType": "ritual",
    "nodeCategory": "personal",
    "name": "周五电影之夜",
    "description": "每周五晚上和家人一起看电影的传统",
    "attributes": {
        "frequency": "weekly",
        "participants": ["妻子", "儿子"],
        "startedDate": "2022-03"
    },
    "tracking": {
        "source": {
            "type": "ai_extracted",
            "confidence": 0.85
        }
    }
}
```

### 属性模板（可选参考）

属性模板用于 UI 展示和输入提示，**不强制要求**。

```json
{
    "skill": {
        "proficiency": {
            "type": "enum",
            "options": ["beginner", "intermediate", "advanced", "expert"],
            "displayNames": ["入门", "中级", "高级", "专家"]
        },
        "category": {
            "type": "enum",
            "options": ["tech", "language", "sport", "art", "music", "business", "other"],
            "displayNames": ["技术", "语言", "运动", "艺术", "音乐", "商业", "其他"]
        },
        "frequency": {
            "type": "enum",
            "options": ["daily", "weekly", "monthly", "occasional"],
            "displayNames": ["每天", "每周", "每月", "偶尔"]
        },
        "yearsOfExperience": {
            "type": "int",
            "min": 0,
            "max": 50
        }
    },
    "goal": {
        "timeframe": {
            "type": "enum",
            "options": ["short_term", "mid_term", "long_term"],
            "displayNames": ["短期(1年内)", "中期(1-3年)", "长期(3年以上)"]
        },
        "status": {
            "type": "enum",
            "options": ["planning", "in_progress", "achieved", "abandoned"],
            "displayNames": ["计划中", "进行中", "已达成", "已放弃"]
        },
        "progress": {
            "type": "double",
            "min": 0.0,
            "max": 1.0,
            "displayFormat": "percentage"
        }
    },
    "relationship_status": {
        "state": {
            "type": "enum",
            "options": ["close", "normal", "distant", "estranged"],
            "displayNames": ["亲密", "正常", "疏远", "断联"]
        },
        "healthScore": {
            "type": "double",
            "min": 0.0,
            "max": 1.0,
            "displayFormat": "percentage"
        },
        "activityLevel": {
            "type": "enum",
            "options": ["very_active", "active", "moderate", "inactive"],
            "displayNames": ["非常活跃", "活跃", "一般", "不活跃"]
        }
    }
}
```

**重要说明**：
- 模板是**可选的**，用于 UI 展示和验证参考
- 用户可以添加模板中没有的属性
- AI 可以创建新的 nodeType，不受模板限制
- 前端根据 nodeType 选择合适的渲染方式，未知类型使用通用渲染器

---

## 👤 用户画像结构

### 完整结构（扩展后）

```swift
/// 叙事用户画像 - 扩展版
struct NarrativeUserProfile: Codable, Identifiable {
    let id: String
    let createdAt: Date
    var updatedAt: Date
    
    // ===== 静态核心（少量固定字段，用户手动维护） =====
    var staticCore: StaticCore
    
    // ===== 近期画像（AI 生成的叙事描述） =====
    var recentPortrait: RecentPortrait?
    
    // ===== 🆕 动态知识（通用节点列表） =====
    var knowledgeNodes: [KnowledgeNode]
    
    // ===== 🆕 AI 对话偏好 =====
    var aiPreferences: AIPreferences?
    
    // ===== 关系引用 =====
    var relationshipIds: [String]
}
```

### 静态核心（保持不变）

```swift
/// 静态核心 - 用户手动输入的基础信息
struct StaticCore: Codable {
    // Basic identity (all optional)
    var gender: Gender?
    var birthYearMonth: String?          // YYYY-MM
    var hometown: String?
    var currentCity: String?
    
    // Occupation info
    var occupation: String?
    var industry: String?
    var education: Education?
    
    // Self description tags
    var selfTags: [String]
    
    // Update history tracking
    var updateHistory: [ProfileUpdateRecord]
}
```

### AI 对话偏好（新增）

```swift
/// AI 对话偏好 - 用户与 AI 交互的偏好设置
struct AIPreferences: Codable {
    // ===== 风格偏好 =====
    var style: AIStylePreference
    
    // ===== 回复偏好 =====
    var response: AIResponsePreference
    
    // ===== 话题偏好 =====
    var topics: AITopicPreference
    
    // ===== 追踪信息 =====
    var tracking: NodeTracking
}

/// AI 风格偏好
struct AIStylePreference: Codable {
    var tone: String?                     // formal | casual | friendly | professional
    var verbosity: String?                // concise | balanced | detailed
    var personality: String?              // supportive | challenging | neutral
    var language: String?                 // 偏好的语言风格
}

/// AI 回复偏好
struct AIResponsePreference: Codable {
    var preferredLength: String?          // short | medium | long
    var includeExamples: Bool?            // 是否包含示例
    var includeEmoji: Bool?               // 是否使用表情
    var structuredFormat: Bool?           // 是否使用结构化格式（列表、标题等）
}

/// AI 话题偏好
struct AITopicPreference: Codable {
    var favorites: [String]               // 喜欢讨论的话题
    var avoid: [String]                   // 避免的话题
    var expertise: [String]               // 用户擅长的领域（AI 可以更深入讨论）
}
```

### 用户画像示例（JSON）

```json
{
    "id": "user_001",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-12-22T10:00:00Z",
    "staticCore": {
        "gender": "male",
        "birthYearMonth": "1990-05",
        "hometown": "北京",
        "currentCity": "上海",
        "occupation": "软件工程师",
        "industry": "互联网",
        "education": "master",
        "selfTags": ["技术宅", "咖啡爱好者"]
    },
    "knowledgeNodes": [
        {
            "id": "node_001",
            "nodeType": "skill",
            "nodeCategory": "common",
            "name": "Swift 编程",
            "description": "iOS 开发主力语言",
            "tags": ["编程", "iOS"],
            "attributes": {
                "proficiency": "advanced",
                "category": "tech",
                "yearsOfExperience": 5
            },
            "tracking": {
                "source": {
                    "type": "ai_extracted",
                    "confidence": 0.92,
                    "extractedFrom": [
                        {
                            "sourceType": "diary",
                            "sourceId": "entry_123",
                            "dayId": "2024-12-20",
                            "snippet": "今天完成了 SwiftUI 动画的优化..."
                        }
                    ]
                },
                "timeline": {
                    "firstDiscovered": "2024-06-15T00:00:00Z",
                    "lastUpdated": "2024-12-20T00:00:00Z"
                },
                "verification": {
                    "confirmedByUser": true,
                    "needsReview": false
                }
            }
        },
        {
            "id": "node_002",
            "nodeType": "goal",
            "nodeCategory": "common",
            "name": "学会日语 N2",
            "description": "为了能看懂日本技术文档",
            "tags": ["学习", "语言"],
            "attributes": {
                "timeframe": "mid_term",
                "status": "in_progress",
                "progress": 0.3,
                "deadline": "2025-12-31"
            },
            "tracking": {
                "source": {
                    "type": "user_input",
                    "confidence": 1.0
                }
            }
        }
    ],
    "aiPreferences": {
        "style": {
            "tone": "casual",
            "verbosity": "balanced"
        },
        "response": {
            "preferredLength": "medium",
            "includeExamples": true
        },
        "topics": {
            "favorites": ["技术", "效率工具", "咖啡"],
            "avoid": ["政治"],
            "expertise": ["iOS 开发", "Swift"]
        }
    },
    "relationshipIds": ["rel_001", "rel_002"]
}
```

---

## 👥 关系画像结构

### 完整结构（扩展后）

```swift
/// 叙事关系画像 - 扩展版
struct NarrativeRelationship: Codable, Identifiable {
    let id: String
    let createdAt: Date
    var updatedAt: Date
    
    // ===== 基础信息（固定字段） =====
    var type: CompanionType               // family | friend | colleague | partner | other
    var displayName: String               // 显示名称
    var realName: String?                 // 真实姓名（可选，加密存储）
    var avatar: String?                   // 头像（Emoji 或图片路径）
    var aliases: [String]                 // 别名（用于 AI 识别）
    
    // ===== 叙事描述 =====
    var narrative: String?                // 用户写的关系描述
    var tags: [String]                    // 用户定义的标签
    
    // ===== 事实锚点 =====
    var factAnchors: RelationshipFactAnchors
    
    // ===== 提及记录 =====
    var mentions: [RelationshipMention]
    
    // ===== 🆕 动态属性（通用节点） =====
    var attributes: [KnowledgeNode]
    
    // ===== 类型特定元数据 =====
    var metadata: [String: String]
}
```

### 事实锚点（保持不变）

```swift
/// 事实锚点 - 可验证的客观事实
struct RelationshipFactAnchors: Codable {
    var firstMeetingDate: String?         // YYYY-MM-DD or YYYY-MM
    var anniversaries: [Anniversary]      // 纪念日列表
    var sharedExperiences: [String]       // 共同经历
}
```

### 关系画像示例（JSON）

```json
{
    "id": "rel_001",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-12-22T10:00:00Z",
    "type": "family",
    "displayName": "妈妈",
    "realName": "张美丽",
    "avatar": "👩",
    "aliases": ["母亲", "老妈", "妈"],
    "narrative": "最爱我的人，总是担心我吃不好睡不好",
    "tags": ["家人", "最亲近"],
    "factAnchors": {
        "firstMeetingDate": "1990-05-15",
        "anniversaries": [
            {
                "id": "ann_001",
                "name": "母亲节",
                "date": "05-12"
            }
        ],
        "sharedExperiences": ["一起去日本旅行", "教我做饭"]
    },
    "mentions": [
        {
            "id": "mention_001",
            "date": "2024-12-20T10:00:00Z",
            "sourceType": "diary",
            "sourceId": "entry_456",
            "contextSnippet": "今天和妈妈视频通话，她说最近血压有点高..."
        }
    ],
    "attributes": [
        {
            "id": "attr_001",
            "nodeType": "relationship_status",
            "nodeCategory": "common",
            "name": "关系状态",
            "attributes": {
                "state": "close",
                "healthScore": 0.9,
                "activityLevel": "active",
                "lastInteraction": "2024-12-20"
            },
            "tracking": {
                "source": {
                    "type": "ai_extracted",
                    "confidence": 0.88
                }
            }
        },
        {
            "id": "attr_002",
            "nodeType": "health_status",
            "nodeCategory": "common",
            "name": "健康状态",
            "description": "妈妈的健康情况",
            "attributes": {
                "condition": "高血压",
                "severity": "mild",
                "treatment": "服药控制",
                "lastCheckup": "2024-12-15"
            },
            "tracking": {
                "source": {
                    "type": "ai_extracted",
                    "confidence": 0.75,
                    "extractedFrom": [
                        {
                            "sourceType": "diary",
                            "sourceId": "entry_456",
                            "dayId": "2024-12-20",
                            "snippet": "她说最近血压有点高..."
                        }
                    ]
                },
                "verification": {
                    "confirmedByUser": false,
                    "needsReview": true
                }
            }
        },
        {
            "id": "attr_003",
            "nodeType": "interaction_pattern",
            "nodeCategory": "common",
            "name": "互动模式",
            "attributes": {
                "frequency": "weekly",
                "channels": ["视频通话", "微信"],
                "preferredTopics": ["健康", "工作", "生活"]
            }
        }
    ],
    "metadata": {}
}
```

---

## 🔄 数据验证策略

### 结构验证（必须通过）

所有 KnowledgeNode 必须通过以下验证：

```swift
/// 节点验证器
struct KnowledgeNodeValidator {
    
    /// 验证节点结构
    static func validate(_ node: KnowledgeNode) -> ValidationResult {
        var errors: [String] = []
        
        // 1. id 必须存在且非空
        if node.id.isEmpty {
            errors.append("id 不能为空")
        }
        
        // 2. nodeType 必须是非空字符串
        if node.nodeType.isEmpty {
            errors.append("nodeType 不能为空")
        }
        
        // 3. name 必须是非空字符串
        if node.name.isEmpty {
            errors.append("name 不能为空")
        }
        
        // 4. nodeCategory 必须是有效值
        // (由 enum 类型保证)
        
        // 5. confidence 如果存在，必须在 0.0 ~ 1.0 之间
        if let confidence = node.tracking.source.confidence {
            if confidence < 0.0 || confidence > 1.0 {
                errors.append("confidence 必须在 0.0 ~ 1.0 之间")
            }
        }
        
        // 6. 时间戳必须有效
        if node.createdAt > node.updatedAt {
            errors.append("createdAt 不能晚于 updatedAt")
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

enum ValidationResult {
    case valid
    case invalid([String])
}
```

### 属性验证（可选，用于 UI 提示）

基于模板验证 enum 字段的值是否有效，但**不强制拒绝**。

```swift
/// 属性验证器 - 用于 UI 提示，不强制
struct AttributeValidator {
    
    /// 验证属性值是否符合模板
    static func validateAgainstTemplate(
        nodeType: String,
        attributes: [String: AttributeValue],
        template: AttributeTemplate?
    ) -> [AttributeWarning] {
        guard let template = template else { return [] }
        
        var warnings: [AttributeWarning] = []
        
        for (key, value) in attributes {
            if let fieldTemplate = template.fields[key] {
                if !fieldTemplate.isValidValue(value) {
                    warnings.append(AttributeWarning(
                        field: key,
                        message: "值 '\(value)' 不在推荐选项中",
                        severity: .info  // 仅提示，不阻止
                    ))
                }
            }
        }
        
        return warnings
    }
}
```

---

## 📈 置信度机制

### 置信度来源

| 来源类型 | 初始置信度 | 说明 |
|----------|-----------|------|
| `user_input` | 1.0 | 用户手动输入，完全可信 |
| `ai_extracted` | 0.6 ~ 0.95 | AI 从原始数据提取，根据证据强度 |
| `ai_inferred` | 0.3 ~ 0.7 | AI 推断得出，需要更多验证 |

### 置信度衰减

AI 提取的信息如果长时间未被确认或更新，置信度会逐渐衰减。

```swift
/// 置信度衰减计算
/// - 衰减周期：180 天
/// - 最大衰减：30%
/// - 用户确认后重置为 1.0
func calculateDecayedConfidence(
    originalConfidence: Double,
    daysSinceLastUpdate: Int
) -> Double {
    // 用户输入不衰减
    guard originalConfidence < 1.0 else { return 1.0 }
    
    // 衰减公式：原始置信度 * (1 - 天数/180 * 0.3)
    let decayFactor = 1.0 - (Double(daysSinceLastUpdate) / 180.0 * 0.3)
    let decayed = originalConfidence * max(decayFactor, 0.7)  // 最低保留 70%
    
    return max(decayed, 0.1)  // 绝对最低 0.1
}

// 示例：
// 原始 0.9，30 天后 → 0.855
// 原始 0.9，90 天后 → 0.765
// 原始 0.9，180 天后 → 0.63
```

### 置信度增强

以下情况会增强置信度：

| 触发条件 | 置信度变化 | 说明 |
|----------|-----------|------|
| 用户确认 | → 1.0 | 用户点击"确认"按钮 |
| 多次提及 | +0.05/次 | 在不同日记/对话中多次提及（上限 0.95） |
| 相关证据 | +0.1 | 发现新的支持证据 |
| 用户编辑 | → 1.0 | 用户修改内容后视为确认 |

```swift
/// 置信度增强计算
func enhanceConfidence(
    currentConfidence: Double,
    mentionCount: Int,
    isUserConfirmed: Bool
) -> Double {
    if isUserConfirmed {
        return 1.0
    }
    
    // 多次提及增强
    let mentionBonus = Double(mentionCount - 1) * 0.05
    let enhanced = currentConfidence + mentionBonus
    
    return min(enhanced, 0.95)  // AI 来源最高 0.95
}
```

### 置信度展示策略

| 置信度范围 | 展示方式 | 用户操作 |
|-----------|---------|---------|
| 0.9 ~ 1.0 | 正常显示 | 无需操作 |
| 0.7 ~ 0.9 | 显示 "AI 推测" 标签 | 可确认或修改 |
| 0.5 ~ 0.7 | 显示 "待确认" 标签 + 黄色高亮 | 建议确认 |
| < 0.5 | 显示 "低置信度" + 灰色 | 强烈建议确认或删除 |

---

## 🔍 与当前系统的差异对比

### 当前系统实现（代码）

| 模型 | 文件位置 | 结构特点 |
|------|---------|---------|
| `NarrativeUserProfile` | `Core/Models/NarrativeProfileModels.swift` | 固定 Schema，9 个静态字段 |
| `StaticCore` | 同上 | 9 个固定字段 + selfTags + updateHistory |
| `RecentPortrait` | 同上 | AI 生成的近期画像（已规划） |
| `NarrativeRelationship` | `Core/Models/NarrativeRelationshipModels.swift` | 固定 Schema |
| `RelationshipFactAnchors` | 同上 | 3 个固定字段 |
| `RelationshipMention` | 同上 | 提及记录（已实现） |

### 当前 StaticCore 字段（代码）

```swift
// 当前代码中的 StaticCore (NarrativeProfileModels.swift)
public struct StaticCore: Codable {
    public var gender: Gender?
    public var birthYearMonth: String?      // YYYY-MM
    public var hometown: String?
    public var currentCity: String?
    public var occupation: String?
    public var industry: String?
    public var education: Education?
    public var selfTags: [String]
    public var updateHistory: [ProfileUpdateRecord]
}
```

### 当前 NarrativeRelationship 字段（代码）

```swift
// 当前代码中的 NarrativeRelationship (NarrativeRelationshipModels.swift)
public struct NarrativeRelationship: Codable, Identifiable, Hashable {
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    public var type: CompanionType
    public var displayName: String
    public var realName: String?
    public var avatar: String?
    public var aliases: [String]            // ✅ 已有
    public var narrative: String?
    public var tags: [String]
    public var factAnchors: RelationshipFactAnchors
    public var mentions: [RelationshipMention]  // ✅ 已有
    public var metadata: [String: String]
}
```

### 差异对比表

| 方面 | 当前系统 | 新规划 | 差异程度 |
|------|---------|--------|----------|
| **用户画像维度** | 9 个固定字段 + selfTags | 通用节点 + 10+ 共有维度 | 🔴 重大差异 |
| **扩展性** | 加字段要改代码 | 加 nodeType 即可 | 🔴 重大差异 |
| **技能/价值观/目标** | ❌ 无 | ✅ 有 (skill, value, goal) | 🔴 缺失 |
| **置信度** | ❌ 无 | ✅ 有 (0.0~1.0) | 🔴 缺失 |
| **溯源链接** | ❌ 无 | ✅ 有 (SourceLink) | 🔴 缺失 |
| **变化历史** | ⚠️ updateHistory 仅记录字段名 | ✅ 完整的 changeHistory | 🟡 部分实现 |
| **关系状态** | ❌ 无 | ✅ relationship_status 节点 | 🔴 缺失 |
| **互动模式** | ⚠️ mentions 仅记录提及 | ✅ interaction_pattern 节点 | 🟡 部分实现 |
| **情感连接** | ❌ 无 | ✅ emotional_connection 节点 | 🔴 缺失 |
| **亲人健康** | ❌ 无 | ✅ health_status 节点 | 🔴 缺失 |
| **AI 偏好** | ⚠️ AISettings 仅技术配置 | ✅ AIPreferences 完整偏好 | 🟡 部分实现 |
| **个人独特维度** | ❌ 无 | ✅ nodeCategory = personal | 🔴 缺失 |
| **别名识别** | ✅ aliases 已有 | ✅ 保持 | ✅ 已实现 |
| **提及记录** | ✅ mentions 已有 | ✅ 保持 | ✅ 已实现 |

### 需要新增的内容

#### 用户画像 (NarrativeUserProfile)

| 新增内容 | 类型 | 说明 |
|---------|------|------|
| `knowledgeNodes` | 字段 | 通用知识节点列表 `[KnowledgeNode]` |
| `aiPreferences` | 字段 | AI 对话偏好 `AIPreferences?` |

#### 关系画像 (NarrativeRelationship)

| 新增内容 | 类型 | 说明 |
|---------|------|------|
| `attributes` | 字段 | 动态属性节点列表 `[KnowledgeNode]` |

#### 新增模型文件

| 文件名 | 包含内容 |
|--------|---------|
| `KnowledgeNodeModels.swift` | KnowledgeNode, NodeCategory, AttributeValue, NodeTracking, NodeSource, SourceType, NodeTimeline, NodeVerification, SourceLink, NodeChange, ChangeType, ChangeReason, NodeRelation, RelationType |
| `AIPreferencesModels.swift` | AIPreferences, AIStylePreference, AIResponsePreference, AITopicPreference |

### 迁移策略

```
迁移步骤（向后兼容）：

1. 创建新模型文件
   - KnowledgeNodeModels.swift
   - AIPreferencesModels.swift

2. 扩展现有模型（不删除任何字段）
   - NarrativeUserProfile 添加 knowledgeNodes: [KnowledgeNode] = []
   - NarrativeUserProfile 添加 aiPreferences: AIPreferences? = nil
   - NarrativeRelationship 添加 attributes: [KnowledgeNode] = []

3. 更新 Repository
   - NarrativeUserProfileRepository 支持读写新字段
   - NarrativeRelationshipRepository 支持读写新字段

4. JSON 兼容性
   - 旧数据读取时，新字段使用默认值（空数组/nil）
   - 新数据写入时，包含所有字段

5. 可选迁移
   - selfTags 可选择性迁移为 nodeType="tag" 的节点
   - 现有 mentions 保持不变，作为基础数据

6. 逐步填充
   - AI 功能上线后，逐步从日记/对话中提取知识节点
   - 用户可手动添加/确认知识节点
```

---

## 📝 实现优先级

### P0 - 核心基础 ⭐ 已完成 (2024-12-22)

| 任务 | 说明 | 状态 |
|------|------|------|
| 定义 KnowledgeNode 数据结构 | 创建 `KnowledgeNodeModels.swift` | ⭐ 已完成 |
| 定义 NodeTracking 等辅助结构 | SourceLink, NodeChange, NodeRelation | ⭐ 已完成 |
| 定义 AIPreferences 结构 | 创建 `AIPreferencesModels.swift` | ⭐ 已完成 |
| 扩展 NarrativeUserProfile | 添加 knowledgeNodes, aiPreferences 字段 | ⭐ 已完成 |
| 扩展 NarrativeRelationship | 添加 attributes 字段 | ⭐ 已完成 |
| 更新 Repository | 支持新字段的读写 | ⭐ 已完成 |

**相关代码**：
- `Core/Models/KnowledgeNodeModels.swift`
- `Core/Models/AIPreferencesModels.swift`
- `Core/Models/NarrativeProfileModels.swift` (扩展)
- `Core/Models/NarrativeRelationshipModels.swift` (扩展)

### P1 - AI 集成（需要 AI 服务）

| 任务 | 说明 | 依赖 |
|------|------|------|
| AI 自动提取节点 | 从日记/对话中提取知识节点 | P0 完成 + AI 服务 |
| 置信度计算 | 根据证据强度计算初始置信度 | AI 提取 |
| 溯源链接建立 | 建立 L4 节点与 L1 原始数据的关联 | AI 提取 |
| 用户审核流程 | 展示待确认节点，支持确认/修改/删除 | AI 提取 |

### P2 - 高级功能（优化体验）

| 任务 | 说明 | 依赖 |
|------|------|------|
| 置信度衰减机制 | 定时任务计算衰减 | P1 完成 |
| 节点关联关系 | 建立节点之间的关联 | P1 完成 |
| 变化历史追踪 | 记录每次修改的详细历史 | P0 完成 |
| 个人独特维度创建 | 用户/AI 创建新的 nodeType | P1 完成 |
| 属性模板管理 | 管理共有维度的属性模板 | P0 完成 |

### P3 - UI 展示（前端）

| 任务 | 说明 | 依赖 |
|------|------|------|
| 知识节点列表展示 | 在用户画像页展示 knowledgeNodes | P0 完成 |
| 节点详情页 | 展示单个节点的详细信息和溯源 | P0 完成 |
| 节点编辑页 | 支持用户编辑节点内容 | P0 完成 |
| 置信度可视化 | 展示置信度标签和颜色 | P1 完成 |
| 关系画像属性展示 | 在关系详情页展示 attributes | P0 完成 |

---

## 🔗 相关文档

- [数据架构](data-architecture.md) - 四层记忆系统整体设计
- [用户画像模型](../data/user-profile-models.md) - 当前模型文档
- [AI 对话功能](../features/ai-conversation.md) - AI 服务相关
- [个人中心功能](../features/profile.md) - 用户画像 UI

---

## 📎 附录：完整类型定义汇总

### 枚举类型

```swift
// 节点分类
enum NodeCategory: String, Codable {
    case common     // 共有维度
    case personal   // 个人独特
}

// 来源类型
enum SourceType: String, Codable {
    case userInput      // 用户输入
    case aiExtracted    // AI 提取
    case aiInferred     // AI 推断
}

// 变化类型
enum ChangeType: String, Codable {
    case created, updated, confirmed, deleted
}

// 变化原因
enum ChangeReason: String, Codable {
    case userEdit, aiUpdate, correction, decay, enhancement
}

// 关联类型
enum RelationType: String, Codable {
    case requires, conflictsWith, supports, relatedTo, partOf
}
```

### 共有维度 nodeType 列表

**用户画像**:
- `skill` - 技能
- `value` - 价值观
- `hobby` - 兴趣爱好
- `goal` - 目标
- `trait` - 性格特质
- `fear` - 恐惧担忧
- `fact` - 核心事实
- `lifestyle` - 生活方式
- `belief` - 信念
- `preference` - 偏好

**关系画像**:
- `relationship_status` - 关系状态
- `interaction_pattern` - 互动模式
- `emotional_connection` - 情感连接
- `shared_memory` - 共同记忆
- `health_status` - 健康状态
- `life_event` - 人生事件

---
**版本**: v2.1.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-22  
**状态**: 规划中

**更新记录**:
- v2.1.0 (2024-12-22): 完善数据结构定义，添加 Swift 代码示例，详细差异对比，实现优先级
- v2.0.0 (2024-12-22): 重构为通用知识节点设计，添加与当前系统差异对比
- v1.0.0 (2024-12-19): 初始版本
