# AI 知识提取流程规划

> 返回 [文档中心](../INDEX.md) | [数据架构](data-architecture.md) | [L4 扩展规划](L4-PROFILE-EXPANSION-PLAN.md)

## 📋 文档说明

本文档规划 AI 如何从 L1 原始数据中提取 L4 知识节点的完整流程。

**核心公式**：
```
L1 原始数据 + 现有画像 + 提示词模板 → AI → KnowledgeNode[]
```

**状态**: ⭐ 部分实现

### 实现进度 (2024-12-22)

| 组件 | 状态 | 说明 |
|------|------|------|
| 数据脱敏策略 | ⭐ 已实现 | 统一人物标识符 `[REL_ID:displayName]` |
| `TextSanitizer` | ⭐ 已实现 | 文本脱敏工具 |
| `DailyExtractionService` | ⭐ 已实现 | 每日数据提取服务 |
| `DailyExtractionModels` | ⭐ 已实现 | 数据提取包结构 |
| AI 提取 Prompt | 🔮 规划中 | 提示词模板设计 |
| AI 结果解析 | 🔮 规划中 | JSON 解析和验证 |
| 知识节点存储 | 🔮 规划中 | KnowledgeNode 持久化 |

**相关代码**：
- `Core/Models/DailyExtractionModels.swift` - 数据结构
- `Core/Utilities/TextSanitizer.swift` - 脱敏工具
- `DataLayer/SystemServices/DailyExtractionService.swift` - 提取服务

---

## � 每日数据结构分脱析

### L1 层数据来源（按日聚合）

系统中每日产生的数据分为以下几类：

```
┌─────────────────────────────────────────────────────────────────┐
│                    每日数据结构 (DayId: yyyy.MM.dd)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. JournalEntry[] (日记条目)                                   │
│     ├── content: String?          ⭐ 自由文本 - 需要分析        │
│     ├── type: EntryType           📦 枚举 - 结构化              │
│     ├── chronology: EntryChronology  📦 枚举 - 结构化           │
│     ├── category: EntryCategory?  📦 枚举 - 结构化              │
│     └── metadata.sender: String?  ⚠️ 可能含人名                 │
│                                                                 │
│  2. DailyTrackerRecord (每日追踪)                               │
│     ├── bodyEnergy: Int           📦 数值 - 结构化              │
│     ├── moodWeather: Int          📦 数值 - 结构化              │
│     └── activities: [ActivityContext]                           │
│         ├── activityType: ActivityType  📦 枚举 - 结构化        │
│         ├── companions: [CompanionType] 📦 枚举 - 结构化        │
│         ├── companionDetails: [String]? 🔗 关系ID引用           │
│         ├── details: String?      ⭐ 自由文本 - 需要分析        │
│         └── tags: [String]        📦 标签ID - 结构化            │
│                                                                 │
│  3. MindStateRecord (心境记录)                                  │
│     ├── valenceValue: Int         📦 数值 - 结构化              │
│     ├── labels: [String]          📦 预定义标签 - 结构化        │
│     └── influences: [String]      📦 预定义标签 - 结构化        │
│                                                                 │
│  4. AIConversation[] (AI对话)                                   │
│     └── messages: [AIMessage]                                   │
│         ├── role: MessageRole     📦 枚举 - 结构化              │
│         └── content: String       ⭐ 自由文本 - 需要分析        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

图例：
⭐ 自由文本 - 可能包含敏感信息，需要 AI 分析
📦 结构化数据 - 系统预定义，无隐私风险
🔗 ID 引用 - 指向其他数据，需要解析
⚠️ 可能敏感 - 需要检查
```

### 数据敏感性分类

| 数据字段 | 类型 | 敏感性 | 处理方式 |
|---------|------|--------|---------|
| `JournalEntry.content` | 自由文本 | 🔴 高 | 需要脱敏处理 |
| `ActivityContext.details` | 自由文本 | 🔴 高 | 需要脱敏处理 |
| `LoveLog.content` | 自由文本 | 🔴 高 | 需要脱敏处理 |
| `LoveLog.sender/receiver` | 字符串 | 🟡 中 | 可能是人名 |
| `JournalEntry.metadata.sender` | 字符串 | 🟡 中 | 可能是人名 |
| `ActivityContext.companionDetails` | ID数组 | 🟢 低 | 关系ID，需解析 |
| `QuestionEntry.*` | 结构化 | ✅ 无 | 系统预定义 |
| `ActivityContext.activityType` | 枚举 | ✅ 无 | 系统预定义 |
| `ActivityContext.companions` | 枚举 | ✅ 无 | 系统预定义 |
| `AIMessage.content` | 自由文本 | ✅ 无 | 用户已发送给AI，无需脱敏 |
| `bodyEnergy`, `moodWeather` | 数值 | ✅ 无 | 纯数值 |

### 关键洞察

1. **大部分数据是结构化的**：追踪器的 activityType、companions 都是系统预定义的枚举，不需要 AI 处理，也没有隐私风险。

2. **只有自由文本需要 AI 分析**：
   - `JournalEntry.content` - 日记正文
   - `ActivityContext.details` - 活动详情
   - `LoveLog.content/originalText` - 爱表内容

3. **AI对话内容无需脱敏**：用户已经选择发送给 AI，代表用户接受了这部分数据的"泄露"。

4. **人物引用有两种形式**：
   - **结构化引用**：`companionDetails` 存储的是 `NarrativeRelationship.id`
   - **自由文本提及**：用户在日记/对话中直接写的人名或称呼

5. **小数据也要包含**：
   - `QuestionEntry` - 时间胶囊（主要是 ID 引用，无需脱敏）
   - `LoveLog` - 爱表（sender/receiver 可能是人名，content 需要分析）

### ⚠️ 关于 MindStateRecord（待废弃）

**问题**：`MindStateRecord` 与 `DailyTrackerRecord` 存在功能重叠：
- `MindStateRecord.valenceValue` ≈ `DailyTrackerRecord.moodWeather` (都是情绪数值)
- `MindStateRecord.labels` ≈ 可以用 `ActivityContext.tags` 替代
- `MindStateRecord.influences` ≈ 可以用 `ActivityContext.details` 描述

**决定**：从 AI 知识提取流程中**移除 MindStateRecord**，统一使用 `DailyTrackerRecord`。

---

## 🔗 关系数据结构分析

### NarrativeRelationship 字段

```swift
struct NarrativeRelationship {
    let id: String                    // 唯一标识符
    var type: CompanionType           // family | friend | colleague | partner | other
    var displayName: String           // 用户设置的显示名称（如 "妈妈"、"小明"）
    var realName: String?             // 真实姓名（可选，如 "张美丽"）
    var aliases: [String]             // 别名列表（如 ["母亲", "老妈"]）
    var narrative: String?            // 用户写的关系描述
    var tags: [String]                // 用户定义的标签
}
```

### 人物标识的复杂性

用户可能用以下任何方式提及同一个人：

```
场景：用户的妈妈，真名张美丽

NarrativeRelationship:
  id: "rel_001"
  displayName: "妈妈"
  realName: "张美丽"
  aliases: ["母亲", "老妈", "我妈"]

用户可能在文本中写：
  - "今天和妈妈去医院" → 匹配 displayName
  - "母亲最近身体不好" → 匹配 aliases
  - "张美丽打电话来了" → 匹配 realName
  - "我妈说..." → 匹配 aliases
  - "老妈子又唠叨了" → 部分匹配 aliases
```

### 核心问题：数据一致性

**问题**：如果我们只脱敏部分数据，AI 可能会把同一个人识别为不同的人。

```
❌ 错误示例：部分脱敏

日记: "今天和妈妈去医院，张美丽说她血压高"
脱敏后: "今天和妈妈去医院，[PERSON_A]说她血压高"

AI 可能认为：
  - "妈妈" 是一个人
  - "[PERSON_A]" 是另一个人
  
结果：同一个人被识别为两个不同的人！
```

**解决方案**：统一人物标识符

```
✅ 正确示例：统一标识

日记: "今天和妈妈去医院，张美丽说她血压高"
处理后: "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说她血压高"

AI 理解：
  - 两处都是同一个人 (REL_001)
  - 这个人是 "妈妈" 类型的家人
```

---

## 🔐 隐私保护：数据脱敏策略

### 核心原则

**目标**：在不泄露用户隐私的前提下，**保留足够的语义信息**供 AI 提取知识，同时**保证数据一致性**。

**三大原则**：
1. **一致性原则**：同一个人在所有数据中必须使用相同的标识符
2. **语义保留原则**：脱敏后 AI 仍能理解关系类型和语义
3. **最小化原则**：只脱敏真正敏感的信息

### 人物标识统一策略

#### 问题分析

用户在不同地方可能用不同方式提及同一个人：

| 数据来源 | 提及方式 | 示例 |
|---------|---------|------|
| 追踪器 companionDetails | 关系ID | `["rel_001"]` |
| 日记 content | displayName | "和妈妈去医院" |
| 日记 content | aliases | "母亲说..." |
| 日记 content | realName | "张美丽打电话" |
| AI对话 content | 任意称呼 | "我妈最近..." |

#### 解决方案：统一人物标识符 (Unified Person Identifier)

**核心思想**：将所有人物提及统一转换为 `[REL_ID:displayName]` 格式

```
格式: [REL_xxx:显示名称]

示例:
  - [REL_001:妈妈] - 已知关系，使用 displayName
  - [UNKNOWN_PERSON:小王] - 未知人物，保留原名
```

#### 转换规则

```swift
/// 人物标识转换规则
struct PersonIdentifierRules {
    
    /// 1. 已知关系的所有名称 → [REL_ID:displayName]
    /// 
    /// 输入: "今天和妈妈去医院，张美丽说她血压高"
    /// 关系: { id: "rel_001", displayName: "妈妈", realName: "张美丽", aliases: ["母亲"] }
    /// 输出: "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说她血压高"
    ///
    /// 好处:
    /// - AI 知道两处是同一个人
    /// - AI 知道这是 "妈妈" 类型的家人
    /// - 真实姓名 "张美丽" 被隐藏
    
    /// 2. 追踪器 companionDetails → [REL_ID:displayName]
    ///
    /// 输入: companionDetails = ["rel_001", "rel_002"]
    /// 输出: "同伴: [REL_001:妈妈], [REL_002:小明]"
    
    /// 3. 未知人物 → [UNKNOWN_PERSON:原名]
    ///
    /// 输入: "今天遇到了李老师"
    /// 输出: "今天遇到了[UNKNOWN_PERSON:李老师]"
    ///
    /// 注意: 未知人物保留原名，因为：
    /// - 可能是新关系，AI 需要识别
    /// - 可能是临时提及，不需要建立关系
}
```

### 数据分类（修订版）

| 分类 | 处理方式 | 说明 | 示例 |
|------|---------|------|------|
| 🔴 **已知关系名称** | 统一标识符 | 所有匹配的名称转为 `[REL_ID:displayName]` | 妈妈、张美丽 → [REL_001:妈妈] |
| 🟡 **未知人物名称** | 标记但保留 | 转为 `[UNKNOWN_PERSON:原名]` | 李老师 → [UNKNOWN_PERSON:李老师] |
| 🔴 **敏感数字** | 固定占位符 | 手机号、身份证等 | 13812345678 → [PHONE] |
| 🟢 **通用称呼词** | 保留原样 | 不指向具体人的通用词 | "朋友"、"同事"（非特指） |
| 🟢 **地点/组织名** | 保留原样 | AI 需要理解语义 | 星巴克、协和医院 |
| 🟢 **结构化数据** | 保留原样 | 枚举、数值等 | activityType, bodyEnergy |
| ⚪ **技术数据** | 丢弃 | 无语义价值 | URL、文件路径、GPS |

### 已知关系名称识别

#### 构建名称映射表

```swift
/// 从所有关系中构建名称 → 关系ID 的映射
func buildNameToRelationshipMap(
    relationships: [NarrativeRelationship]
) -> [String: (relationshipId: String, displayName: String, type: CompanionType)] {
    
    var nameMap: [String: (String, String, CompanionType)] = [:]
    
    for relationship in relationships {
        let entry = (relationship.id, relationship.displayName, relationship.type)
        
        // 1. displayName
        nameMap[relationship.displayName] = entry
        
        // 2. realName (如果有)
        if let realName = relationship.realName {
            nameMap[realName] = entry
        }
        
        // 3. 所有 aliases
        for alias in relationship.aliases {
            nameMap[alias] = entry
        }
    }
    
    return nameMap
}

// 示例:
// relationships = [
//   { id: "rel_001", displayName: "妈妈", realName: "张美丽", aliases: ["母亲", "老妈"] }
// ]
// 
// nameMap = {
//   "妈妈": ("rel_001", "妈妈", .family),
//   "张美丽": ("rel_001", "妈妈", .family),
//   "母亲": ("rel_001", "妈妈", .family),
//   "老妈": ("rel_001", "妈妈", .family)
// }
```

#### 文本中的名称替换

```swift
/// 替换文本中的已知关系名称
func replaceKnownNames(
    in text: String,
    nameMap: [String: (relationshipId: String, displayName: String, type: CompanionType)]
) -> String {
    var result = text
    
    // 按名称长度降序排序，避免短名称先匹配导致的问题
    // 例如: "老妈" 应该优先于 "妈" 匹配
    let sortedNames = nameMap.keys.sorted { $0.count > $1.count }
    
    for name in sortedNames {
        guard let (relId, displayName, _) = nameMap[name] else { continue }
        
        // 替换为统一标识符
        let identifier = "[REL_\(relId):\(displayName)]"
        result = result.replacingOccurrences(of: name, with: identifier)
    }
    
    return result
}

// 示例:
// 输入: "今天和妈妈去医院，张美丽说她血压高，老妈让我别担心"
// 输出: "今天和[REL_rel_001:妈妈]去医院，[REL_rel_001:妈妈]说她血压高，[REL_rel_001:妈妈]让我别担心"
```

### 未知人物识别

#### 通用关系称呼词表

以下词汇是**通用称呼**，不指向具体个人，**不需要标记**：

```swift
/// 通用关系称呼 - 不指向具体个人，保留原样
let genericRelationTerms: Set<String> = [
    // 泛指家人
    "家人", "亲戚", "长辈", "晚辈",
    
    // 泛指社交
    "朋友", "同事", "同学", "室友", "邻居",
    "老板", "领导", "下属", "客户",
    "老师", "学生", "师傅", "徒弟",
    
    // 泛指亲密关系
    "男朋友", "女朋友", "对象", "伴侣",
    
    // 英文
    "friend", "colleague", "boss", "teacher"
]
```

**注意**：当用户写 "和朋友吃饭" 时，"朋友" 是泛指，不需要标记。但当用户写 "和小明吃饭" 时，"小明" 是具体人名，需要检查是否是已知关系。

#### 未知人物检测（简化版）

```swift
/// 检测文本中可能的未知人物名称
/// 
/// 策略：使用简单的启发式规则，不依赖复杂 NLP
/// - 中文人名通常 2-4 个字
/// - 常见姓氏开头
/// - 排除已知关系和通用称呼
func detectUnknownPersonNames(
    in text: String,
    knownNames: Set<String>,
    genericTerms: Set<String>
) -> [String] {
    
    // 常见中文姓氏（简化版，可扩展）
    let commonSurnames = ["张", "王", "李", "赵", "刘", "陈", "杨", "黄", "周", "吴",
                          "徐", "孙", "马", "朱", "胡", "郭", "何", "高", "林", "罗"]
    
    var unknownNames: [String] = []
    
    // 简单的正则匹配：姓 + 1-2个字
    for surname in commonSurnames {
        let pattern = "\(surname)[\\u4e00-\\u9fa5]{1,2}"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let name = String(text[range])
            
            // 排除已知关系和通用称呼
            if !knownNames.contains(name) && !genericTerms.contains(name) {
                unknownNames.append(name)
            }
        }
    }
    
    return unknownNames
}
```

### 敏感数字脱敏

```swift
struct SensitivePatterns {
    static let phone = try! NSRegularExpression(pattern: "1[3-9]\\d{9}")
    static let idCard = try! NSRegularExpression(pattern: "\\d{17}[\\dXx]")
    static let email = try! NSRegularExpression(pattern: "[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}")
    static let bankCard = try! NSRegularExpression(pattern: "\\d{16,19}")
    
    /// 脱敏敏感数字
    static func maskSensitiveNumbers(_ text: String) -> String {
        var result = text
        
        // 按顺序替换，避免重叠
        result = phone.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[PHONE]"
        )
        result = idCard.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[ID_CARD]"
        )
        result = email.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[EMAIL]"
        )
        // 银行卡放最后，避免误匹配手机号
        result = bankCard.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[BANK_CARD]"
        )
        
        return result
    }
}
```

### 完整脱敏流程

#### 流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                    统一人物标识脱敏流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┐    ┌─────────────┐    ┌─────────┐    ┌─────────┐  │
│  │ L1 数据 │ → │ 构建名称    │ → │ 统一替换 │ → │ 脱敏文本 │  │
│  │         │    │ 映射表      │    │         │    │         │  │
│  └─────────┘    └─────────────┘    └─────────┘    └─────────┘  │
│       │               │                 │              │        │
│       │               ↓                 ↓              │        │
│       │        ┌─────────────┐    ┌─────────────┐     │        │
│       │        │ 关系画像    │    │ 统一标识符  │     │        │
│       │        │ displayName │    │ [REL_ID:名] │     │        │
│       │        │ realName    │    └─────────────┘     │        │
│       │        │ aliases     │                        │        │
│       │        └─────────────┘                        │        │
│       │                                               │        │
│       │         处理规则：                            │        │
│       │         1. 已知关系所有名称 → [REL_ID:displayName]     │
│       │         2. 敏感数字 → [PHONE]/[ID_CARD]/...   │        │
│       │         3. 未知人物 → [UNKNOWN_PERSON:原名]   │        │
│       │         4. 地点/组织/通用词 → 保留原样        │        │
│       │                                               │        │
│       ↓                                               ↓        │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                    发送给 AI                         │       │
│  │  "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说..."  │       │
│  └─────────────────────────────────────────────────────┘       │
│                            │                                    │
│                            ↓                                    │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                   AI 返回结果                        │       │
│  │  { "personRef": "[REL_001:妈妈]", "nodeType": "..." }│       │
│  │  AI 知道两处是同一个人，且是 "妈妈" 类型的家人      │       │
│  └─────────────────────────────────────────────────────┘       │
│                            │                                    │
│                            ↓                                    │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                   结果处理                           │       │
│  │  1. 解析 [REL_001:妈妈] → relationshipId: "001"     │       │
│  │  2. 存储到对应关系的 attributes                      │       │
│  │  3. 无需还原，标识符本身包含语义                     │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 脱敏规则详解

##### 🔴 需要统一标识的内容

| 类型 | 识别方式 | 替换为 | 示例 |
|------|---------|--------|------|
| 已知关系名称 | displayName/realName/aliases 匹配 | `[REL_ID:displayName]` | 妈妈、张美丽、老妈 → [REL_001:妈妈] |
| 未知人物名称 | 姓氏+名字模式 | `[UNKNOWN_PERSON:原名]` | 李老师 → [UNKNOWN_PERSON:李老师] |
| 手机号 | 正则 `1[3-9]\d{9}` | `[PHONE]` | 13812345678 → [PHONE] |
| 身份证 | 正则 `\d{17}[\dXx]` | `[ID_CARD]` | 110101199001011234 → [ID_CARD] |
| 银行卡 | 正则 `\d{16,19}` | `[BANK_CARD]` | 6222021234567890123 → [BANK_CARD] |
| 邮箱 | 正则 `[\w.-]+@[\w.-]+` | `[EMAIL]` | test@example.com → [EMAIL] |

##### 🟢 保留原样的内容

| 类型 | 说明 | 示例 | 保留原因 |
|------|------|------|---------|
| 地点名称 | 商家、地标 | 星巴克、协和医院 | AI 需要理解地点类型 |
| 组织名称 | 公司、学校 | 字节跳动、清华大学 | AI 需要理解组织类型 |
| 通用关系词 | 泛指的关系词 | "朋友"、"同事"（非特指） | 不指向具体个人 |
| 活动类型 | 系统预定义枚举 | work, exercise, reading | 结构化数据 |
| 情绪描述 | 通用情绪词汇 | 开心、焦虑、平静 | 语义必需 |
| 技能名称 | 通用技能词汇 | Swift、摄影、日语 | 语义必需 |
| 时间表达 | 相对/绝对时间 | 今天、上周、2024-12-20 | 语义必需 |
| 数值 | 非敏感数值 | 跑了5公里、看了2小时书 | 语义必需 |

##### ⚪ 直接丢弃的内容

| 类型 | 原因 |
|------|------|
| 图片/音频 URL | 无法脱敏，且 AI 无法处理 |
| 文件路径 | 可能泄露设备信息 |
| GPS 精确坐标 | 可定位用户 |
| 设备 ID | 可追踪用户 |

#### 实现代码

##### 1. 构建名称映射表

```swift
/// 从所有关系中构建名称 → 关系信息的映射
func buildNameToRelationshipMap(
    relationships: [NarrativeRelationship]
) -> [String: (relationshipId: String, displayName: String, type: CompanionType)] {
    
    var nameMap: [String: (String, String, CompanionType)] = [:]
    
    for relationship in relationships {
        let entry = (relationship.id, relationship.displayName, relationship.type)
        
        // 1. displayName
        nameMap[relationship.displayName] = entry
        
        // 2. realName (如果有)
        if let realName = relationship.realName {
            nameMap[realName] = entry
        }
        
        // 3. 所有 aliases
        for alias in relationship.aliases {
            nameMap[alias] = entry
        }
    }
    
    return nameMap
}

// 示例:
// relationships = [
//   { id: "001", displayName: "妈妈", realName: "张美丽", aliases: ["母亲", "老妈"] }
// ]
// 
// nameMap = {
//   "妈妈": ("001", "妈妈", .family),
//   "张美丽": ("001", "妈妈", .family),
//   "母亲": ("001", "妈妈", .family),
//   "老妈": ("001", "妈妈", .family)
// }
```

##### 2. 统一人物标识替换

```swift
/// 替换文本中的已知关系名称为统一标识符
func replaceWithUnifiedIdentifier(
    in text: String,
    nameMap: [String: (relationshipId: String, displayName: String, type: CompanionType)]
) -> String {
    var result = text
    
    // 按名称长度降序排序，避免短名称先匹配导致的问题
    // 例如: "老妈" 应该优先于 "妈" 匹配
    let sortedNames = nameMap.keys.sorted { $0.count > $1.count }
    
    for name in sortedNames {
        guard let (relId, displayName, _) = nameMap[name] else { continue }
        
        // 替换为统一标识符: [REL_ID:displayName]
        let identifier = "[REL_\(relId):\(displayName)]"
        result = result.replacingOccurrences(of: name, with: identifier)
    }
    
    return result
}

// 示例:
// 输入: "今天和妈妈去医院，张美丽说她血压高，老妈让我别担心"
// 输出: "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说她血压高，[REL_001:妈妈]让我别担心"
```

##### 3. 敏感数字脱敏

```swift
struct SensitivePatterns {
    static let phone = try! NSRegularExpression(pattern: "1[3-9]\\d{9}")
    static let idCard = try! NSRegularExpression(pattern: "\\d{17}[\\dXx]")
    static let email = try! NSRegularExpression(pattern: "[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}")
    static let bankCard = try! NSRegularExpression(pattern: "\\d{16,19}")
    
    /// 脱敏敏感数字（直接替换为固定占位符）
    static func maskSensitiveNumbers(_ text: String) -> String {
        var result = text
        
        // 按顺序替换，避免重叠
        result = phone.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[PHONE]"
        )
        result = idCard.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[ID_CARD]"
        )
        result = email.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[EMAIL]"
        )
        // 银行卡放最后，避免误匹配手机号
        result = bankCard.stringByReplacingMatches(
            in: result, 
            range: NSRange(result.startIndex..., in: result), 
            withTemplate: "[BANK_CARD]"
        )
        
        return result
    }
}
```

##### 4. 未知人物检测

```swift
/// 通用关系称呼 - 不指向具体个人，保留原样
let genericRelationTerms: Set<String> = [
    // 泛指家人
    "家人", "亲戚", "长辈", "晚辈",
    // 泛指社交
    "朋友", "同事", "同学", "室友", "邻居",
    "老板", "领导", "下属", "客户",
    "老师", "学生", "师傅", "徒弟",
    // 泛指亲密关系
    "男朋友", "女朋友", "对象", "伴侣"
]

/// 检测文本中可能的未知人物名称
func detectUnknownPersonNames(
    in text: String,
    knownNames: Set<String>,
    genericTerms: Set<String>
) -> [String] {
    
    // 常见中文姓氏
    let commonSurnames = ["张", "王", "李", "赵", "刘", "陈", "杨", "黄", "周", "吴",
                          "徐", "孙", "马", "朱", "胡", "郭", "何", "高", "林", "罗"]
    
    var unknownNames: [String] = []
    
    // 简单的正则匹配：姓 + 1-2个字
    for surname in commonSurnames {
        let pattern = "\(surname)[\\u4e00-\\u9fa5]{1,2}"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let name = String(text[range])
            
            // 排除已知关系和通用称呼
            if !knownNames.contains(name) && !genericTerms.contains(name) {
                unknownNames.append(name)
            }
        }
    }
    
    return unknownNames
}
```

##### 5. 完整脱敏函数

```swift
/// 完整的文本脱敏处理
func sanitizeText(
    _ text: String,
    relationships: [NarrativeRelationship]
) -> String {
    // 1. 构建名称映射表
    let nameMap = buildNameToRelationshipMap(relationships: relationships)
    
    // 2. 替换已知关系名称为统一标识符
    var result = replaceWithUnifiedIdentifier(in: text, nameMap: nameMap)
    
    // 3. 检测并标记未知人物
    let knownNames = Set(nameMap.keys)
    let unknownNames = detectUnknownPersonNames(
        in: text, 
        knownNames: knownNames, 
        genericTerms: genericRelationTerms
    )
    for name in unknownNames {
        result = result.replacingOccurrences(
            of: name, 
            with: "[UNKNOWN_PERSON:\(name)]"
        )
    }
    
    // 4. 脱敏敏感数字
    result = SensitivePatterns.maskSensitiveNumbers(result)
    
    return result
}
```

#### 脱敏示例

**原始日记**：
```
今天和妈妈去星巴克中关村店喝咖啡。她说最近在字节跳动工作压力很大，
血压有点高。我建议她去协和医院检查一下。晚上给张美丽打了电话 13812345678。
```

**关系画像**：
```json
{
    "id": "001",
    "displayName": "妈妈",
    "realName": "张美丽",
    "aliases": ["母亲", "老妈"]
}
```

**脱敏后发送给 AI**：
```
今天和[REL_001:妈妈]去星巴克中关村店喝咖啡。她说最近在字节跳动工作压力很大，
血压有点高。我建议她去协和医院检查一下。晚上给[REL_001:妈妈]打了电话[PHONE]。
```

**说明**：
- ✅ "妈妈" → `[REL_001:妈妈]` - AI 知道这是已知关系
- ✅ "张美丽" → `[REL_001:妈妈]` - 同一个人，统一标识
- ✅ "星巴克中关村店" 保留 → AI 理解这是咖啡馆
- ✅ "字节跳动" 保留 → AI 理解这是科技公司
- ✅ "协和医院" 保留 → AI 理解这是医院
- 🔴 "13812345678" → `[PHONE]` - 敏感数字脱敏

**AI 返回**：
```json
{
  "relationshipUpdates": [{
    "personRef": "[REL_001:妈妈]",
    "newAttributes": [{
      "nodeType": "health_status",
      "name": "血压状况",
      "attributes": { "condition": "高血压", "severity": "mild" }
    }]
  }],
  "userNodes": [{
    "nodeType": "value",
    "name": "关心家人健康",
    "confidence": 0.75,
    "reasoning": "用户主动建议[REL_001:妈妈]去医院检查"
  }]
}
```

**结果处理**：
```swift
// 解析 personRef 获取 relationshipId
let personRef = "[REL_001:妈妈]"
let relationshipId = parseRelationshipId(personRef) // "001"

// 直接存储到对应关系
relationship.attributes.append(newAttribute)
```

### 数据一致性保障

#### 核心问题

**问题**：用户可能用不同方式提及同一个人，如果处理不当，AI 会认为是不同的人。

```
❌ 错误示例：部分脱敏

日记: "今天和妈妈去医院，张美丽说她血压高"
错误脱敏: "今天和妈妈去医院，[PERSON_A]说她血压高"

AI 可能认为：
  - "妈妈" 是一个人
  - "[PERSON_A]" 是另一个人
  
结果：同一个人被识别为两个不同的人！
```

#### 解决方案

**统一人物标识符**确保同一个人在所有数据中使用相同的标识：

```
✅ 正确示例：统一标识

日记: "今天和妈妈去医院，张美丽说她血压高"
正确脱敏: "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说她血压高"

AI 理解：
  - 两处都是同一个人 (REL_001)
  - 这个人是 "妈妈" 类型的家人
```

#### 跨数据源一致性

| 数据来源 | 原始数据 | 统一标识后 |
|---------|---------|-----------|
| 日记 content | "和妈妈去医院" | "和[REL_001:妈妈]去医院" |
| 日记 content | "张美丽说..." | "[REL_001:妈妈]说..." |
| 追踪器 companionDetails | `["001"]` | "同伴: [REL_001:妈妈]" |
| AI对话 content | "我妈最近..." | "[REL_001:妈妈]最近..." |

### 安全保障

| 保障措施 | 说明 |
|---------|------|
| 统一标识符不含真名 | `[REL_001:妈妈]` 只包含 displayName，不包含 realName |
| 敏感数字完全移除 | 手机号、身份证等直接替换为固定占位符 |
| 地点/组织保留 | 保留语义必需的信息，但不能定位到具体用户 |
| 标识符可解析 | AI 返回的标识符可直接解析为 relationshipId |
| 无需还原映射 | 标识符本身包含语义，无需维护还原映射表 |

### 隐私 vs 语义 vs 一致性

```
┌─────────────────────────────────────────────────────────────┐
│              统一人物标识符的三重保障                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   隐私保护   │  │   语义保留   │  │  数据一致性  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│        │                │                │                  │
│        ↓                ↓                ↓                  │
│  ┌─────────────────────────────────────────────────┐       │
│  │           [REL_001:妈妈]                         │       │
│  │                                                  │       │
│  │  ✅ 隐私: 真名 "张美丽" 被隐藏                   │       │
│  │  ✅ 语义: AI 知道这是 "妈妈" 类型的家人          │       │
│  │  ✅ 一致: 所有提及都指向同一个 REL_001           │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 输入：L1 原始数据结构

### 1. 日记条目 (JournalEntry)

```swift
struct JournalEntry {
    let id: String
    let type: EntryType           // text | image | video | audio | file | mixed
    let chronology: EntryChronology  // past | present | future
    let content: String?          // ⭐ 主要文本内容
    let timestamp: String         // 时间戳
    let category: EntryCategory?  // dream | health | emotion | work | social | media | life
}
```

**可提取信息**：
- `content` → 技能、目标、价值观、人物提及、情绪、事件
- `category` → 辅助分类判断
- `chronology` → 区分回忆/当下/计划

### 2. 每日追踪 (DailyTrackerRecord)

```swift
struct DailyTrackerRecord {
    let date: String
    let bodyEnergy: Int           // 0-100 身体能量
    let moodWeather: Int          // 0-100 心情天气
    let activities: [ActivityContext]
}

struct ActivityContext {
    let activityType: ActivityType  // work | study | exercise | date | party...
    let companions: [CompanionType] // alone | partner | family | friends...
    let companionDetails: [String]? // NarrativeRelationship IDs
    let details: String?            // ⭐ 活动详情文本
    let tags: [String]              // 用户标签
}
```

**可提取信息**：
- `activities` → 生活方式、兴趣爱好
- `companions` + `companionDetails` → 关系互动模式
- `details` → 具体事件、人物提及

### 3. 心境记录 (MindStateRecord)

```swift
struct MindStateRecord {
    let date: String
    let valenceValue: Int         // 情绪效价
    let labels: [String]          // ⭐ 情绪标签
    let influences: [String]      // ⭐ 影响因素
}
```

**可提取信息**：
- `labels` → 性格特质、情绪模式
- `influences` → 价值观、恐惧担忧、生活方式

### 4. AI 对话 (AIConversation)

```swift
struct AIConversation {
    let messages: [AIMessage]
}

struct AIMessage {
    let role: MessageRole         // user | assistant
    let content: String           // ⭐ 对话内容
}
```

**可提取信息**：
- 用户消息 → 技能、目标、价值观、人物提及、问题/困惑
- 对话主题 → 兴趣爱好、专业领域

---

## 🎯 输出：KnowledgeNode 结构

### 用户画像节点类型

| nodeType | 提取来源 | 置信度基准 |
|----------|---------|-----------|
| `skill` | 日记中提到的技能、对话中讨论的专业话题 | 0.7-0.9 |
| `value` | 日记中的价值判断、选择理由 | 0.6-0.8 |
| `hobby` | 追踪器活动、日记中的休闲描述 | 0.8-0.9 |
| `goal` | 日记中的计划、对话中的目标讨论 | 0.7-0.9 |
| `trait` | 心境标签、日记中的自我描述 | 0.6-0.8 |
| `fear` | 心境影响因素、日记中的担忧 | 0.5-0.7 |
| `fact` | 日记中的明确事实陈述 | 0.8-0.95 |
| `lifestyle` | 追踪器活动模式、日记中的习惯描述 | 0.8-0.9 |
| `belief` | 日记中的信念表达、对话中的观点 | 0.6-0.8 |
| `preference` | 日记中的偏好表达、选择模式 | 0.7-0.85 |

### 关系画像节点类型

| nodeType | 提取来源 | 置信度基准 |
|----------|---------|-----------|
| `relationship_status` | 日记中的关系描述、互动频率 | 0.6-0.8 |
| `interaction_pattern` | 追踪器同伴数据、日记中的互动描述 | 0.7-0.9 |
| `emotional_connection` | 日记中的情感表达 | 0.5-0.7 |
| `shared_memory` | 日记中的共同经历描述 | 0.8-0.95 |
| `health_status` | 日记中提到的亲人健康 | 0.6-0.8 |
| `life_event` | 日记中提到的对方重要事件 | 0.8-0.9 |

---

## 🔄 提取流程设计

### 流程概览

```
┌─────────────────────────────────────────────────────────────┐
│                    知识提取流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ 数据收集 │ → │ 上下文  │ → │ AI 提取 │ → │ 后处理  │  │
│  │ Collect │    │ Context │    │ Extract │    │ Process │  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
│       ↓              ↓              ↓              ↓        │
│  L1 原始数据    现有画像+关系    Prompt+LLM    去重+验证    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 阶段 1：数据收集 (Collect)

**输入**：日期范围 (如最近 7 天)

**输出**：结构化的原始数据包

```swift
struct ExtractionInput {
    let dateRange: DateRange
    let journalEntries: [JournalEntry]
    let trackerRecords: [DailyTrackerRecord]
    let mindStateRecords: [MindStateRecord]
    let conversations: [AIConversation]
}
```

**数据格式化**（给 AI 的文本）：

```markdown
## 日记记录

### 2024-12-20
- [10:30] 今天完成了 SwiftUI 动画的优化，终于搞定了那个卡顿问题。
- [14:00] 和妈妈视频通话，她说最近血压有点高，让我有点担心。
- [20:00] 晚上和小明一起打了两局游戏，好久没这么放松了。

### 2024-12-21
- [09:00] 早起跑步 5 公里，感觉状态不错。
- [15:00] 在咖啡馆看了一下午书，《原子习惯》真的很有启发。

## 每日追踪

### 2024-12-20
- 身体能量: 70/100 (精神不错)
- 心情天气: 65/100 (晴朗)
- 活动: 工作(独处), 社交(家人-妈妈), 游戏(朋友-小明)

### 2024-12-21
- 身体能量: 80/100 (精力充沛)
- 心情天气: 75/100 (阳光明媚)
- 活动: 运动(独处), 阅读(独处)

## 心境记录

### 2024-12-20
- 情绪: 平静、满足
- 影响因素: 工作成就感、家人健康担忧

## AI 对话摘要

### 2024-12-20 对话
用户讨论了 iOS 开发中的性能优化问题，询问了 SwiftUI 动画的最佳实践。
```

### 阶段 2：上下文构建 (Context)

**输入**：现有用户画像 + 关系画像

**输出**：上下文提示

```markdown
## 已知用户信息

### 基础信息
- 性别: 男
- 职业: 软件工程师
- 行业: 互联网
- 自我标签: 技术宅, 咖啡爱好者

### 已确认的知识节点
- [skill] Swift 编程 (advanced, 置信度 0.92)
- [goal] 学会日语 N2 (in_progress, 置信度 1.0)
- [hobby] 跑步 (weekly, 置信度 0.85)

### 关系画像
- 妈妈 (family): 别名[母亲, 老妈], 最近提及 3 次
- 小明 (friend): 别名[明哥], 最近提及 2 次
```

### 阶段 3：AI 提取 (Extract)

**Prompt 模板**：

```markdown
你是一个用户画像分析助手。根据用户的日记、追踪记录和对话，提取有价值的知识节点。

## 任务说明

1. 分析以下用户数据，提取新的知识节点或更新现有节点
2. 每个节点需要包含：类型、名称、描述、属性、置信度、来源
3. 置信度规则：
   - 明确陈述的事实: 0.85-0.95
   - 多次提及的信息: 0.75-0.85
   - 推断得出的信息: 0.5-0.7
4. 不要重复已确认的节点，除非有新信息需要更新
5. 识别人物提及时，尝试匹配已知关系的别名

## 用户数据

{formatted_input}

## 已知信息

{context}

## 输出格式

请以 JSON 格式输出，结构如下：

```json
{
  "userNodes": [
    {
      "nodeType": "skill",
      "name": "SwiftUI 动画优化",
      "description": "iOS 开发中的动画性能优化能力",
      "attributes": {
        "proficiency": "advanced",
        "category": "tech"
      },
      "confidence": 0.85,
      "sourceType": "aiExtracted",
      "sources": [
        {
          "type": "diary",
          "dayId": "2024-12-20",
          "snippet": "完成了 SwiftUI 动画的优化"
        }
      ],
      "reasoning": "用户明确提到完成了动画优化任务，表明具备相关技能"
    }
  ],
  "relationshipUpdates": [
    {
      "relationshipId": "rel_mom",
      "matchedBy": "妈妈",
      "newAttributes": [
        {
          "nodeType": "health_status",
          "name": "血压状况",
          "attributes": {
            "condition": "高血压",
            "severity": "mild"
          },
          "confidence": 0.75,
          "sources": [...]
        }
      ],
      "mentionRecord": {
        "dayId": "2024-12-20",
        "snippet": "和妈妈视频通话，她说最近血压有点高"
      }
    }
  ],
  "newRelationships": []
}
```

## 注意事项

1. 只提取有实际价值的信息，不要过度解读
2. 区分事实和推断，推断需要降低置信度
3. 人物识别要谨慎，不确定时不要强行匹配
4. 保持 JSON 格式严格正确
```

### 阶段 4：后处理 (Process)

**去重逻辑**：
```swift
func deduplicateNodes(
    newNodes: [KnowledgeNode],
    existingNodes: [KnowledgeNode]
) -> (toAdd: [KnowledgeNode], toUpdate: [KnowledgeNode]) {
    // 1. 按 nodeType + name 相似度匹配
    // 2. 相似度 > 0.8 视为同一节点，合并信息
    // 3. 合并时：置信度取较高值，来源合并
}
```

**验证逻辑**：
```swift
func validateExtractedNode(_ node: KnowledgeNode) -> Bool {
    // 1. 必填字段检查
    // 2. 置信度范围检查
    // 3. 来源链接有效性检查
}
```

---

## 📊 触发时机

### 自动触发

| 触发条件 | 处理范围 | 频率 |
|---------|---------|------|
| 每日结算 | 当天数据 | 每天 23:00 |
| 周度总结 | 最近 7 天 | 每周日 |
| 月度总结 | 最近 30 天 | 每月 1 日 |

### 手动触发

| 触发方式 | 处理范围 |
|---------|---------|
| 用户点击"更新画像" | 最近 7 天 |
| 用户点击"深度分析" | 最近 30 天 |

---

## 🔧 实现优先级

### P1.1 - 基础提取

| 任务 | 说明 |
|------|------|
| 数据格式化器 | 将 L1 数据转换为 AI 可读文本 |
| Prompt 模板 | 设计提取提示词 |
| JSON 解析器 | 解析 AI 返回的 JSON |
| 基础去重 | 按名称精确匹配去重 |

### P1.2 - 关系识别

| 任务 | 说明 |
|------|------|
| 别名匹配 | 根据 aliases 识别人物 |
| 提及记录 | 自动添加 RelationshipMention |
| 关系属性更新 | 更新关系的 attributes |

### P1.3 - 智能增强

| 任务 | 说明 |
|------|------|
| 语义去重 | 使用相似度算法去重 |
| 置信度调整 | 根据多次提及增强置信度 |
| 冲突检测 | 检测与现有节点的冲突 |

---

## 📝 待讨论问题

1. ~~**隐私考虑**：哪些数据不应该发送给 AI？~~ ✅ 已解决（统一人物标识符策略）
2. ~~**数据一致性**：如何确保同一个人在不同数据源中被识别为同一个人？~~ ✅ 已解决（统一人物标识符）
3. **提取频率**：每天提取 vs 累积后批量提取？
4. **Token 成本**：如何控制每次提取的数据量？
5. **用户确认流程**：低置信度节点如何展示给用户？
6. **Prompt 模板设计**：如何设计提示词以获得最佳提取效果？
7. **AI 返回格式**：JSON Schema 如何定义？
8. ~~**关系匹配**：AI 返回的人物引用如何匹配到具体的 relationshipId？~~ ✅ 已解决（标识符直接包含 ID）

---

## 🔗 相关文档

- [L4 层画像数据扩展规划](L4-PROFILE-EXPANSION-PLAN.md)
- [数据架构](data-architecture.md)
- [AI 对话功能](../features/ai-conversation.md)

---
**版本**: v1.2.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-22  
**状态**: 部分实现

**更新记录**:
- v1.2.0 (2024-12-22): 更新实现状态，DailyExtractionService 和 TextSanitizer 已实现
- v1.1.0 (2024-12-22): 统一人物标识符策略
- v1.0.0 (2024-12-20): 初始版本
