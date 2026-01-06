# AI 知识提取接口文档

[← 返回文档首页](INDEX.md)

## 📋 文档说明

本文档定义 iOS 客户端与 AI 知识提取服务器之间的接口规范。

---

## 🧮 核心公式

### 公式 1：快速定位（第一轮）

```
DailyPackage → AI → QuickAnalysis
```

**输入**：每日数据包（已脱敏）
**输出**：快速分析结果 + 需要的上下文列表

```
QuickAnalysis = {
    summary: String,              // 今日概要
    detectedPersons: [PersonRef], // 检测到的人物引用
    suggestedContexts: [          // 建议请求的上下文
        { type: "user_profile", reason: "检测到技能相关内容" },
        { type: "relationship", id: "001", reason: "提及妈妈健康" }
    ],
    potentialNodes: [             // 潜在可提取的节点类型
        { nodeType: "skill", count: 2 },
        { nodeType: "health_status", personRef: "[REL_001:妈妈]" }
    ]
}
```

### 公式 2：提交上下文（第二轮）

```
requestId + RequestedContext → AI → L4Data[]
```

**输入**：请求ID（关联缓存的 DailyPackage）+ 请求的上下文（用户画像/关系画像）
**输出**：L4层任意数据（KnowledgeNode、RelationshipUpdate、ProfileUpdate 等）

```
L4Data = KnowledgeNode | RelationshipAttribute | ProfileInsight | ...
```

**优势**：
- 节省带宽：第二轮不需要重复发送 DailyPackage
- 节省 Token：服务器已缓存原始数据，仅需补充上下文

### 公式 3：灵活输出

```
服务端返回 = {
    type: "knowledge_node" | "relationship_update" | "profile_insight" | "custom",
    data: Any  // 符合 iOS 定义的数据结构即可
}
```

**核心原则**：
- iOS 定义数据结构规范
- 服务端按规范返回任意 L4 数据
- 输出类型灵活，不限于固定结构

---

## 🔄 两轮交互流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    两轮交互流程                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                                                │
│  │  第一轮     │  DailyPackage → 快速分析                       │
│  │  快速定位   │  返回：requestId + 概要 + 建议的上下文维度     │
│  └─────────────┘  (服务器缓存 DailyPackage)                     │
│         │                                                       │
│         ↓                                                       │
│  ┌─────────────┐                                                │
│  │  iOS 端     │  根据 suggestedContexts 准备上下文数据         │
│  │  准备上下文 │  调用 ContextBuilder 构建脱敏后的上下文        │
│  └─────────────┘                                                │
│         │                                                       │
│         ↓                                                       │
│  ┌─────────────┐                                                │
│  │  第二轮     │  requestId + Context → 完整提取                │
│  │  提交上下文 │  返回：L4 任意数据（节点、更新、洞察等）       │
│  └─────────────┘  (服务器用 requestId 关联缓存的 DailyPackage)  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔌 接口定义

### 接口 1：快速分析

```
POST /api/v1/knowledge/analyze
```

### 接口 2：提交上下文

```
POST /api/v1/knowledge/context
```

### 认证

```
Authorization: Bearer {user_token}
```

---

## 📤 请求格式 (Request)

### 接口 1：快速分析 (Analyze)

**端点**: `POST /api/v1/knowledge/analyze`

**请求体**：仅发送每日数据包，不含上下文

```json
{
  "dayId": "2024.12.22",
  "extractedAt": "2024-12-22T10:30:00Z",
  "data": {
    "journalEntries": [...],
    "trackerRecord": {...},
    "loveLogs": [...],
    "aiConversations": [...]
  },
  "knownRelationships": [...]
}
```

**响应**：快速分析结果

```json
{
  "success": true,
  "requestId": "req_abc123",
  "analysis": {
    "summary": "今日主要记录了工作和家人互动",
    "detectedPersons": ["[REL_001:妈妈]", "[REL_002:小明]"],
    "suggestedContexts": [
      { "type": "user_profile", "reason": "检测到技能相关内容" },
      { "type": "relationship", "id": "001", "reason": "提及妈妈健康状况" }
    ],
    "potentialNodes": [
      { "nodeType": "skill", "name": "SwiftUI动画", "confidence": 0.8 },
      { "nodeType": "health_status", "personRef": "[REL_001:妈妈]", "confidence": 0.75 }
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `requestId` | String | 请求ID，用于第二轮关联缓存的 DailyPackage |
| `analysis` | Object | 分析结果 |

### 接口 2：提交上下文 (Submit Context)

**端点**: `POST /api/v1/knowledge/context`

**说明**：服务器在第一轮已缓存 DailyPackage，第二轮仅需提交请求的上下文数据

**请求体**：仅上下文数据（根据第一轮返回的 requestId 和 suggestedContexts）

```json
{
  "requestId": "req_abc123",
  "context": {
    "userProfile": {...},
    "relationships": [...]
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `requestId` | String | ✅ | 第一轮返回的请求ID，用于关联缓存的 DailyPackage |
| `context` | Object | ✅ | 根据 suggestedContexts 准备的上下文数据 |

**响应**：L4 任意数据（灵活格式）

```json
{
  "success": true,
  "requestId": "req_abc123",
  "results": [
    {
      "type": "knowledge_node",
      "target": "user",
      "data": { ... }
    },
    {
      "type": "relationship_attribute",
      "target": "[REL_001:妈妈]",
      "data": { ... }
    }
  ]
}
```

---

## 📦 数据结构详解

#### 1. 基础信息

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `dayId` | String | ✅ | 日期标识 (yyyy.MM.dd) |
| `extractedAt` | String | ✅ | 提取时间 (ISO 8601) |
| `data` | Object | ✅ | L1 原始数据（已脱敏） |
| `context` | Object | ✅ | 现有画像上下文 |
| `options` | Object | ❌ | 提取选项 |

#### 2. data 对象

##### 2.1 journalEntries (日记条目数组)

```json
{
  "journalEntries": [
    {
      "id": "entry_001",
      "timestamp": "10:30",
      "type": "text",
      "chronology": "present",
      "category": "work",
      "content": "今天完成了 SwiftUI 动画优化，和[REL_001:妈妈]视频通话。",
      "sender": null
    }
  ]
}
```

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | String | 日记条目ID | "entry_001" |
| `timestamp` | String | 时间 (HH:mm) | "10:30" |
| `type` | String | 类型 | "text", "image", "video", "audio", "mixed" |
| `chronology` | String | 时态 | "past", "present", "future" |
| `category` | String? | 分类 | "work", "health", "emotion", "social" 等 |
| `content` | String? | 内容（已脱敏） | "今天和[REL_001:妈妈]..." |
| `sender` | String? | 发送者 | "[REL_002:小明]" 或 null |

##### 2.2 trackerRecord (每日追踪记录)

```json
{
  "trackerRecord": {
    "bodyEnergy": 70,
    "moodWeather": 65,
    "activities": [
      {
        "id": "act_001",
        "activityType": "work",
        "companions": ["alone"],
        "companionRefs": [],
        "details": "完成了项目的核心功能开发",
        "tags": ["编程", "专注"]
      },
      {
        "id": "act_002",
        "activityType": "social",
        "companions": ["family"],
        "companionRefs": ["[REL_001:妈妈]"],
        "details": "视频通话聊了半小时",
        "tags": ["家人", "关心"]
      }
    ]
  }
}
```

| 字段 | 类型 | 说明 | 取值范围 |
|------|------|------|----------|
| `bodyEnergy` | Int | 身体能量 | 0-100 |
| `moodWeather` | Int | 心情天气 | 0-100 |
| `activities` | Array | 活动列表 | - |

**Activity 对象**：

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | String | 活动ID | "act_001" |
| `activityType` | String | 活动类型 | "work", "exercise", "social", "reading" 等 |
| `companions` | String[] | 同伴类型 | ["alone"], ["family"], ["friends"] |
| `companionRefs` | String[] | 同伴引用 | ["[REL_001:妈妈]"] |
| `details` | String? | 详情（已脱敏） | "完成了项目开发" |
| `tags` | String[] | 标签 | ["编程", "专注"] |

##### 2.3 loveLogs (爱表记录数组)

```json
{
  "loveLogs": [
    {
      "id": "love_001",
      "timestamp": "14:30",
      "senderRef": "Me",
      "receiverRef": "[REL_003:女朋友]",
      "content": "今天想你了"
    }
  ]
}
```

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | String | 爱表ID | "love_001" |
| `timestamp` | String | 时间 (HH:mm) | "14:30" |
| `senderRef` | String | 发送者引用 | "Me" 或 "[REL_xxx:名称]" |
| `receiverRef` | String | 接收者引用 | "[REL_003:女朋友]" |
| `content` | String | 内容（已脱敏） | "今天想你了" |

##### 2.4 aiConversations (AI对话摘要数组)

```json
{
  "aiConversations": [
    {
      "id": "conv_001",
      "timestamp": "15:00",
      "messageCount": 8,
      "userMessages": [
        "如何优化 SwiftUI 动画性能？",
        "有没有推荐的学习资源？"
      ],
      "topics": ["iOS开发", "性能优化"]
    }
  ]
}
```

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | String | 对话ID | "conv_001" |
| `timestamp` | String | 时间 (HH:mm) | "15:00" |
| `messageCount` | Int | 消息数量 | 8 |
| `userMessages` | String[] | 用户消息列表 | ["如何优化..."] |
| `topics` | String[]? | 话题标签 | ["iOS开发"] |

#### 3. context 对象

##### 3.1 userProfile (用户画像上下文)

```json
{
  "userProfile": {
    "staticCore": {
      "gender": "male",
      "occupation": "软件工程师",
      "industry": "互联网",
      "selfTags": ["技术宅", "咖啡爱好者"]
    },
    "existingNodes": [
      {
        "nodeType": "skill",
        "name": "Swift 编程",
        "attributes": {
          "proficiency": "advanced"
        },
        "confidence": 0.92
      }
    ]
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `staticCore` | Object | 静态核心信息 |
| `existingNodes` | Array | 已有知识节点（避免重复提取） |

##### 3.2 relationships (关系画像上下文)

```json
{
  "relationships": [
    {
      "id": "001",
      "ref": "[REL_001:妈妈]",
      "type": "family",
      "displayName": "妈妈",
      "aliases": ["母亲", "老妈"],
      "existingAttributes": [
        {
          "nodeType": "relationship_status",
          "name": "关系状态",
          "attributes": {
            "state": "close"
          }
        }
      ]
    }
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 关系ID |
| `ref` | String | 统一标识符 |
| `type` | String | 关系类型 |
| `displayName` | String | 显示名称 |
| `aliases` | String[] | 别名列表 |
| `existingAttributes` | Array | 已有属性节点 |

#### 4. options 对象（可选）

```json
{
  "options": {
    "includeUserNodes": true,
    "includeRelationshipNodes": true,
    "confidenceThreshold": 0.5,
    "maxNodesPerType": 10
  }
}
```

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `includeUserNodes` | Boolean | true | 是否提取用户画像节点 |
| `includeRelationshipNodes` | Boolean | true | 是否提取关系画像节点 |
| `confidenceThreshold` | Float | 0.5 | 最低置信度阈值 (0.0-1.0) |
| `maxNodesPerType` | Int | 10 | 每种类型最多返回节点数 |

---

## 📥 响应格式 (Response)

### 成功响应 (200 OK)

```json
{
  "success": true,
  "extractedAt": "2024-12-22T10:30:15Z",
  "results": {
    "userNodes": [...],
    "relationshipUpdates": [...]
  },
  "metadata": {
    "totalNodesExtracted": 5,
    "processingTimeMs": 1234,
    "modelVersion": "gpt-4-turbo"
  }
}
```

### 响应结构

#### 1. userNodes (用户画像节点数组)

```json
{
  "userNodes": [
    {
      "nodeType": "skill",
      "nodeCategory": "common",
      "name": "SwiftUI 动画优化",
      "description": "用户在 iOS 开发中擅长 SwiftUI 动画性能优化",
      "tags": ["iOS", "性能优化"],
      "attributes": {
        "proficiency": "advanced",
        "category": "tech",
        "yearsOfExperience": 3
      },
      "tracking": {
        "source": {
          "type": "ai_extracted",
          "confidence": 0.85,
          "extractedFrom": [
            {
              "sourceType": "diary",
              "sourceId": "entry_001",
              "dayId": "2024.12.22",
              "snippet": "今天完成了 SwiftUI 动画优化",
              "relevanceScore": 0.9
            }
          ]
        }
      },
      "relations": []
    },
    {
      "nodeType": "value",
      "nodeCategory": "common",
      "name": "关心家人健康",
      "description": "用户重视家人的健康状况，会主动关心和建议",
      "tags": ["家庭", "健康"],
      "attributes": {
        "importance": "high",
        "manifestation": "主动询问、提供建议"
      },
      "tracking": {
        "source": {
          "type": "ai_extracted",
          "confidence": 0.75,
          "extractedFrom": [
            {
              "sourceType": "diary",
              "sourceId": "entry_001",
              "dayId": "2024.12.22",
              "snippet": "和[REL_001:妈妈]视频通话",
              "relevanceScore": 0.8
            }
          ]
        }
      },
      "relations": []
    }
  ]
}
```

**UserNode 字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `nodeType` | String | ✅ | 节点类型 (skill, value, goal, hobby 等) |
| `nodeCategory` | String | ✅ | 节点分类 (common, personal) |
| `name` | String | ✅ | 节点名称 |
| `description` | String? | ❌ | 描述 |
| `tags` | String[] | ✅ | 标签 |
| `attributes` | Object | ✅ | 动态属性 (Key-Value) |
| `tracking` | Object | ✅ | 追踪信息 |
| `relations` | Array | ✅ | 关联关系 |

**tracking 对象**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `source` | Object | ✅ | 来源信息 |
| `source.type` | String | ✅ | "ai_extracted" 或 "ai_inferred" |
| `source.confidence` | Float | ✅ | 置信度 (0.0-1.0) |
| `source.extractedFrom` | Array | ✅ | 溯源链接列表 |

**extractedFrom 对象**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `sourceType` | String | ✅ | "diary", "tracker", "conversation", "loveLog" |
| `sourceId` | String | ✅ | 原始数据ID |
| `dayId` | String | ✅ | 日期 (yyyy.MM.dd) |
| `snippet` | String | ✅ | 相关文本片段 |
| `relevanceScore` | Float | ❌ | 相关性评分 (0.0-1.0) |

#### 2. relationshipUpdates (关系画像更新数组)

```json
{
  "relationshipUpdates": [
    {
      "personRef": "[REL_001:妈妈]",
      "relationshipId": "001",
      "newAttributes": [
        {
          "nodeType": "health_status",
          "nodeCategory": "common",
          "name": "血压状况",
          "description": "妈妈最近血压有点高",
          "tags": ["健康", "需关注"],
          "attributes": {
            "condition": "高血压",
            "severity": "mild",
            "treatment": "未知",
            "lastMentioned": "2024.12.22"
          },
          "tracking": {
            "source": {
              "type": "ai_extracted",
              "confidence": 0.75,
              "extractedFrom": [
                {
                  "sourceType": "diary",
                  "sourceId": "entry_001",
                  "dayId": "2024.12.22",
                  "snippet": "和[REL_001:妈妈]视频通话，她说血压有点高",
                  "relevanceScore": 0.9
                }
              ]
            }
          },
          "relations": []
        },
        {
          "nodeType": "interaction_pattern",
          "nodeCategory": "common",
          "name": "互动模式",
          "description": "定期视频通话",
          "tags": ["沟通", "家人"],
          "attributes": {
            "frequency": "weekly",
            "channels": ["视频通话"],
            "preferredTopics": ["健康", "工作"]
          },
          "tracking": {
            "source": {
              "type": "ai_extracted",
              "confidence": 0.8,
              "extractedFrom": [
                {
                  "sourceType": "tracker",
                  "sourceId": "act_002",
                  "dayId": "2024.12.22",
                  "snippet": "视频通话聊了半小时",
                  "relevanceScore": 0.85
                }
              ]
            }
          },
          "relations": []
        }
      ]
    }
  ]
}
```

**RelationshipUpdate 字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `personRef` | String | ✅ | 人物引用 ([REL_xxx:名称]) |
| `relationshipId` | String | ✅ | 关系ID (从 personRef 解析) |
| `newAttributes` | Array | ✅ | 新增/更新的属性节点 |

**newAttributes 数组元素结构与 userNodes 相同**。

#### 3. metadata (元数据)

```json
{
  "metadata": {
    "totalNodesExtracted": 5,
    "userNodesCount": 2,
    "relationshipUpdatesCount": 1,
    "processingTimeMs": 1234,
    "modelVersion": "gpt-4-turbo",
    "warnings": []
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `totalNodesExtracted` | Int | 总提取节点数 |
| `userNodesCount` | Int | 用户画像节点数 |
| `relationshipUpdatesCount` | Int | 关系更新数 |
| `processingTimeMs` | Int | 处理耗时（毫秒） |
| `modelVersion` | String | AI 模型版本 |
| `warnings` | String[] | 警告信息（如数据不足） |

---

## ❌ 错误响应

### 400 Bad Request (请求格式错误)

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field: dayId",
    "details": {
      "field": "dayId",
      "reason": "Field is required"
    }
  }
}
```

### 401 Unauthorized (认证失败)

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  }
}
```

### 429 Too Many Requests (请求过多)

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retryAfter": 60
  }
}
```

### 500 Internal Server Error (服务器错误)

```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "requestId": "req_abc123"
  }
}
```

---

## 📊 数据量估算

### Token 估算

| 数据类型 | 平均 Token 数 | 说明 |
|---------|--------------|------|
| 日记条目 (1条) | 50-200 | 取决于内容长度 |
| 追踪记录 (1天) | 100-300 | 包含多个活动 |
| 爱表记录 (1条) | 20-50 | 简短文本 |
| AI对话 (1轮) | 100-500 | 取决于对话长度 |
| 上下文 (用户画像) | 200-500 | 已有节点数量 |
| 上下文 (关系画像) | 50-200/人 | 每个关系的属性 |

**单日数据估算**：
- 最小：~500 tokens (仅日记)
- 平均：~1500 tokens (日记 + 追踪 + 上下文)
- 最大：~5000 tokens (完整数据 + 多个关系)

---

## 🔒 安全与隐私

### 数据脱敏

所有发送到服务器的数据已经过脱敏处理：

| 敏感信息 | 脱敏方式 | 示例 |
|---------|---------|------|
| 人物真名 | 统一标识符 | "张美丽" → "[REL_001:妈妈]" |
| 手机号 | 固定占位符 | "13812345678" → "[PHONE]" |
| 身份证 | 固定占位符 | "110101..." → "[ID_CARD]" |
| 邮箱 | 固定占位符 | "test@example.com" → "[EMAIL]" |

### 传输安全

- ✅ 使用 HTTPS 加密传输
- ✅ 使用 Bearer Token 认证
- ✅ 服务器不存储原始数据
- ✅ 仅返回知识节点，不返回原始文本

---

## 📝 使用示例

### Swift 代码示例

```swift
// 1. 准备请求数据
let package = try await DailyExtractionService.shared.extractDailyPackage(for: "2024.12.22")
let userProfile = NarrativeUserProfileRepository.shared.load()
let relationships = NarrativeRelationshipRepository.shared.loadAll()

// 2. 构建请求体
let requestBody: [String: Any] = [
    "dayId": package.dayId,
    "extractedAt": ISO8601DateFormatter().string(from: package.extractedAt),
    "data": [
        "journalEntries": package.journalEntries.map { $0.toDictionary() },
        "trackerRecord": package.trackerRecord?.toDictionary(),
        "loveLogs": package.loveLogs.map { $0.toDictionary() },
        "aiConversations": package.aiConversations.map { $0.toDictionary() }
    ],
    "context": [
        "userProfile": [
            "staticCore": userProfile.staticCore.toDictionary(),
            "existingNodes": userProfile.knowledgeNodes.map { $0.toSummary() }
        ],
        "relationships": relationships.map { rel in
            [
                "id": rel.id,
                "ref": PersonIdentifier(relationshipId: rel.id, displayName: rel.displayName).formatted,
                "type": rel.type.rawValue,
                "displayName": rel.displayName,
                "aliases": rel.aliases,
                "existingAttributes": rel.attributes.map { $0.toSummary() }
            ]
        }
    ],
    "options": [
        "includeUserNodes": true,
        "includeRelationshipNodes": true,
        "confidenceThreshold": 0.5
    ]
]

// 3. 发送请求
let url = URL(string: "https://api.yourserver.com/api/v1/knowledge/extract")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

let (data, response) = try await URLSession.shared.data(for: request)

// 4. 解析响应
let result = try JSONDecoder().decode(ExtractionResponse.self, from: data)

// 5. 存储结果
if result.success {
    // 存储用户画像节点
    for node in result.results.userNodes {
        userProfile.knowledgeNodes.append(node)
    }
    NarrativeUserProfileRepository.shared.save(userProfile)
    
    // 存储关系画像更新
    for update in result.results.relationshipUpdates {
        if var relationship = NarrativeRelationshipRepository.shared.load(id: update.relationshipId) {
            relationship.attributes.append(contentsOf: update.newAttributes)
            NarrativeRelationshipRepository.shared.save(relationship)
        }
    }
}
```

---

## 🔄 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| v1.0.0 | 2024-12-22 | 初始版本 |

---

## 📁 iOS 数据模型文件索引

服务器端开发时，需要参考以下 iOS 数据模型文件来理解完整的数据结构：

### 核心模型文件

| 文件路径 | 说明 | 关键类型 |
|---------|------|---------|
| `Core/Models/KnowledgeNodeModels.swift` | **L4 知识节点** | `KnowledgeNode`, `NodeTracking`, `SourceLink`, `NodeChange` |
| `Core/Models/NarrativeProfileModels.swift` | **用户画像** | `NarrativeUserProfile`, `StaticCore`, `RecentPortrait` |
| `Core/Models/NarrativeRelationshipModels.swift` | **关系画像** | `NarrativeRelationship`, `RelationshipFactAnchors`, `RelationshipMention` |
| `Core/Models/AIPreferencesModels.swift` | **AI 偏好** | `AIPreferences`, `AIStylePreference`, `AITopicPreference` |
| `Core/Models/DailyExtractionModels.swift` | **每日提取包** | `DailyExtractionPackage`, `SanitizedJournalEntry`, `PersonIdentifier` |
| `Core/Models/KnowledgeAPIModels.swift` | **API 交互模型** | `ContextRequest`, `ExtractedResult`, `KnowledgeAPIError` |

### L1 原始数据模型

| 文件路径 | 说明 | 关键类型 |
|---------|------|---------|
| `Core/Models/JournalEntry.swift` | 日记条目 | `JournalEntry`, `EntryType`, `EntryCategory`, `EntryChronology` |
| `Core/Models/DailyTimeline.swift` | 每日时间轴 | `DailyTimeline`, `TimelineItem` |
| `Core/Models/DailyTrackerModels.swift` | 每日追踪 | `DailyTrackerRecord`, `ActivityContext`, `ActivityType` |
| `Core/Models/AIConversationModels.swift` | AI 对话 | `AIConversation`, `AIMessage` |
| `Core/Models/MindStateRecord.swift` | 心境记录 | `MindStateRecord` |
| `Core/Models/LocationModel.swift` | 地点模型 | `LocationVO`, `AddressMapping`, `AddressFence` |

### 服务层文件

| 文件路径 | 说明 |
|---------|------|
| `DataLayer/SystemServices/ContextBuilder.swift` | 上下文构建器（脱敏处理） |
| `DataLayer/SystemServices/KnowledgeExportService.swift` | 数据导出服务 |
| `DataLayer/SystemServices/KnowledgeImportService.swift` | 数据导入服务 |
| `Core/Utilities/TextSanitizer.swift` | 文本脱敏工具 |

---

## 🗂️ 完整数据维度设计

### iOS 端数据变化汇总

服务器返回的数据会影响以下 iOS 本地数据：

| 数据类型 | 存储位置 | 操作类型 | 说明 |
|---------|---------|---------|------|
| **用户画像节点** | `NarrativeUserProfile.knowledgeNodes` | 增/改/删 | 技能、价值观、目标、兴趣等 |
| **关系画像属性** | `NarrativeRelationship.attributes` | 增/改/删 | 关系状态、互动模式、健康状态等 |
| **AI 偏好** | `NarrativeUserProfile.aiPreferences` | 改 | 对话风格偏好（可选） |
| **溯源链接** | `KnowledgeNode.tracking.source.extractedFrom` | 增 | 连接 L4 与 L1 |
| **变更历史** | `KnowledgeNode.tracking.changeHistory` | 增 | 追踪修改记录 |
| **提及记录** | `NarrativeRelationship.mentions` | 增 | 关系提及记录（可选） |

### 用户画像 nodeType 列表

| nodeType | 中文名 | 说明 | 核心属性 |
|----------|--------|------|----------|
| `skill` | 技能 | 用户掌握的技能 | proficiency, category, yearsOfExperience |
| `value` | 价值观 | 核心价值观 | importance, manifestation |
| `hobby` | 兴趣爱好 | 业余爱好 | frequency, startedDate |
| `goal` | 目标 | 人生目标 | timeframe, status, progress, deadline |
| `trait` | 性格特质 | 性格特征 | strength, context, isPositive |
| `fear` | 恐惧担忧 | 焦虑点 | severity, trigger |
| `fact` | 核心事实 | 不容篡改的事实 | importance, date |
| `lifestyle` | 生活方式 | 生活习惯 | frequency, time |
| `belief` | 信念 | 人生信念 | strength, origin |
| `preference` | 偏好 | 各类偏好 | category, strength |

### 关系画像 nodeType 列表

| nodeType | 中文名 | 说明 | 核心属性 |
|----------|--------|------|----------|
| `relationship_status` | 关系状态 | 当前关系状态 | state, healthScore, activityLevel |
| `interaction_pattern` | 互动模式 | 互动习惯 | frequency, channels, preferredTopics |
| `emotional_connection` | 情感连接 | 情感纽带 | intensity, trust, tone |
| `shared_memory` | 共同记忆 | 重要共同经历 | date, emotion, importance |
| `health_status` | 健康状态 | 亲人健康（仅家人） | condition, severity, treatment |
| `life_event` | 人生事件 | 对方的重要事件 | eventType, date, impact |

### 完整响应结构（含变更记录）

服务器返回的完整结构应包含：

```json
{
  "success": true,
  "requestId": "req_abc123",
  "dayId": "2024.12.22",
  "extractedAt": "2024-12-22T10:30:15Z",
  
  "results": {
    "userNodes": [
      {
        "action": "create",
        "nodeType": "skill",
        "nodeCategory": "common",
        "name": "SwiftUI 动画优化",
        "description": "...",
        "tags": ["iOS", "性能优化"],
        "attributes": {
          "proficiency": { "type": "string", "value": "advanced" },
          "category": { "type": "string", "value": "tech" }
        },
        "tracking": {
          "source": {
            "type": "ai_extracted",
            "confidence": 0.85,
            "extractedFrom": [
              {
                "sourceType": "diary",
                "sourceId": "entry_001",
                "dayId": "2024.12.22",
                "snippet": "今天完成了 SwiftUI 动画优化",
                "relevanceScore": 0.9
              }
            ]
          },
          "timeline": {
            "firstDiscovered": "2024-12-22T10:30:00Z",
            "lastUpdated": "2024-12-22T10:30:00Z"
          },
          "verification": {
            "confirmedByUser": false,
            "needsReview": true
          },
          "changeHistory": [
            {
              "timestamp": "2024-12-22T10:30:00Z",
              "changeType": "created",
              "reason": "ai_update",
              "confidence": 0.85
            }
          ]
        },
        "relations": []
      }
    ],
    
    "relationshipUpdates": [
      {
        "personRef": "[REL_001:妈妈]",
        "relationshipId": "001",
        "newAttributes": [...],
        "updatedAttributes": [
          {
            "nodeId": "existing_node_id",
            "action": "update",
            "changes": [
              {
                "field": "attributes.lastMentioned",
                "oldValue": { "type": "string", "value": "2024.12.20" },
                "newValue": { "type": "string", "value": "2024.12.22" }
              }
            ],
            "tracking": {
              "changeHistory": [
                {
                  "timestamp": "2024-12-22T10:30:00Z",
                  "changeType": "updated",
                  "field": "attributes.lastMentioned",
                  "reason": "ai_update",
                  "confidence": 0.9
                }
              ]
            }
          }
        ],
        "newMentions": [
          {
            "date": "2024-12-22T10:30:00Z",
            "sourceType": "diary",
            "sourceId": "entry_001",
            "contextSnippet": "和[REL_001:妈妈]视频通话，她说血压有点高"
          }
        ]
      }
    ]
  },
  
  "metadata": {
    "totalNodesExtracted": 5,
    "userNodesCount": 2,
    "relationshipUpdatesCount": 1,
    "newNodesCount": 3,
    "updatedNodesCount": 2,
    "processingTimeMs": 1234,
    "modelVersion": "gpt-4-turbo",
    "warnings": []
  }
}
```

### action 字段说明

| action | 说明 | iOS 处理 |
|--------|------|---------|
| `create` | 新建节点 | 添加到 knowledgeNodes/attributes 数组 |
| `update` | 更新现有节点 | 根据 nodeId 找到并更新 |
| `confirm` | 确认节点（提升置信度） | 设置 confirmedByUser = true |
| `delete` | 删除节点 | 从数组中移除 |

### AttributeValue 编码格式

服务器返回的属性值需要使用以下格式：

```json
{
  "attributes": {
    "proficiency": { "type": "string", "value": "advanced" },
    "yearsOfExperience": { "type": "int", "value": 5 },
    "confidence": { "type": "double", "value": 0.85 },
    "isActive": { "type": "bool", "value": true },
    "tags": { "type": "array", "value": ["iOS", "Swift"] },
    "startDate": { "type": "date", "value": "2024-01-01T00:00:00Z" }
  }
}
```

| type | 说明 | value 类型 |
|------|------|-----------|
| `string` | 字符串 | String |
| `int` | 整数 | Int |
| `double` | 浮点数 | Double |
| `bool` | 布尔值 | Bool |
| `array` | 字符串数组 | [String] |
| `date` | 日期 | ISO 8601 String |

---

## 🎯 提示词工程参考

### AI 提取任务描述

服务器端 AI 需要完成以下任务：

1. **实体识别**：识别日记中提到的人物、地点、活动
2. **知识提取**：从文本中提取技能、价值观、目标等维度
3. **关系分析**：分析用户与他人的互动模式、情感连接
4. **置信度评估**：根据证据强度评估提取结果的可信度
5. **溯源标注**：标注每个提取结果的来源位置

### 输入数据说明

| 数据源 | 内容 | 提取重点 |
|--------|------|---------|
| `journalEntries` | 日记文本 | 技能、价值观、情感、人物互动 |
| `trackerRecord` | 活动记录 | 生活方式、互动模式、能量状态 |
| `loveLogs` | 爱表记录 | 关系亲密度、情感表达 |
| `aiConversations` | AI 对话 | 兴趣话题、学习目标、困惑点 |

### 人物引用格式

- 格式：`[REL_xxx:显示名]`
- 示例：`[REL_001:妈妈]`、`[REL_002:小明]`
- 解析：`REL_` 后是关系 ID，`:` 后是显示名称

---

**相关文档**：
- [L4 画像扩展规划](architecture/L4-PROFILE-EXPANSION-PLAN.md)
- [AI 知识提取流程](architecture/AI-KNOWLEDGE-EXTRACTION-PLAN.md)
- [每日提取服务使用指南](DAILY_EXTRACTION_USAGE.md)
- [数据架构](architecture/data-architecture.md)

---
**版本**: v1.1.0  
**作者**: Hansen  
**更新日期**: 2024-12-22  
**状态**: 已发布

**更新记录**:
- v1.1.0 (2024-12-22): 添加完整数据维度设计、模型文件索引、变更记录结构
- v1.0.0 (2024-12-22): 初始版本
