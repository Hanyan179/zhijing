# Daily Extraction Service 使用指南

[← 返回文档首页](INDEX.md)

## 概述

`DailyExtractionService` 是 AI 知识提取的核心服务，负责从 L1 原始数据生成脱敏后的每日数据包。

## 核心功能

1. **自动脱敏**：所有人物名称统一为 `[REL_ID:displayName]` 格式
2. **敏感数字过滤**：手机号、身份证、邮箱、银行卡自动脱敏
3. **数据聚合**：按日聚合所有数据源（日记、追踪、爱表、AI对话）
4. **关系上下文**：提供已知关系列表供 AI 匹配

## 使用方式

### 基础用法

```swift
// 提取今天的数据
let today = DateUtilities.today
let package = try await DailyExtractionService.shared.extractDailyPackage(for: today)

// 检查是否有数据
if package.stats.isEmpty {
    print("今天没有数据")
    return
}

// 访问各数据源
print("日记条目: \(package.journalEntries.count)")
print("追踪记录: \(package.trackerRecord != nil ? "有" : "无")")
print("爱表记录: \(package.loveLogs.count)")
print("AI对话: \(package.aiConversations.count)")
```

### 数据结构

#### DailyExtractionPackage

```swift
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

#### SanitizedJournalEntry

```swift
struct SanitizedJournalEntry {
    let id: String
    let timestamp: String                      // "14:30"
    let type: String                           // "text" | "image" | ...
    let chronology: String                     // "past" | "present" | "future"
    let category: String?                      // "work" | "health" | ...
    let content: String?                       // 已脱敏的内容
    let sender: String?                        // [REL_ID:name] 或 "Me"
}
```

#### SanitizedTrackerRecord

```swift
struct SanitizedTrackerRecord {
    let bodyEnergy: Int                        // 0-100
    let moodWeather: Int                       // 0-100
    let activities: [SanitizedActivity]
}

struct SanitizedActivity {
    let id: String
    let activityType: String                   // "work" | "exercise" | ...
    let companions: [String]                   // ["alone"] | ["family"] | ...
    let companionRefs: [String]                // ["[REL_001:妈妈]"]
    let details: String?                       // 已脱敏的详情
    let tags: [String]                         // 标签文本
}
```

## 脱敏示例

### 输入（原始数据）

```
日记: "今天和妈妈去医院，张美丽说她血压有点高。我的手机号是 13812345678。"

关系画像:
{
    id: "001",
    displayName: "妈妈",
    realName: "张美丽",
    aliases: ["母亲", "老妈"]
}
```

### 输出（脱敏后）

```
日记: "今天和[REL_001:妈妈]去医院，[REL_001:妈妈]说她血压有点高。我的手机号是[PHONE]。"

关系上下文:
{
    id: "001",
    ref: "[REL_001:妈妈]",
    type: "family",
    displayName: "妈妈",
    aliases: ["母亲", "老妈"]
}
```

## 发送给 AI

### 格式化为文本

```swift
func formatForAI(_ package: DailyExtractionPackage) -> String {
    var text = "# \(package.dayId) 数据\n\n"
    
    // 1. 日记
    if !package.journalEntries.isEmpty {
        text += "## 日记记录\n\n"
        for entry in package.journalEntries {
            text += "[\(entry.timestamp)] \(entry.content ?? "")\n"
        }
        text += "\n"
    }
    
    // 2. 追踪
    if let tracker = package.trackerRecord {
        text += "## 每日追踪\n\n"
        text += "身体能量: \(tracker.bodyEnergy)/100\n"
        text += "心情天气: \(tracker.moodWeather)/100\n"
        text += "活动:\n"
        for activity in tracker.activities {
            text += "- \(activity.activityType)"
            if !activity.companionRefs.isEmpty {
                text += " (同伴: \(activity.companionRefs.joined(separator: ", ")))"
            }
            if let details = activity.details {
                text += ": \(details)"
            }
            text += "\n"
        }
        text += "\n"
    }
    
    // 3. 关系上下文
    if !package.knownRelationships.isEmpty {
        text += "## 已知关系\n\n"
        for rel in package.knownRelationships {
            text += "- \(rel.ref) (\(rel.type))\n"
        }
        text += "\n"
    }
    
    return text
}
```

### 发送示例

```swift
let package = try await DailyExtractionService.shared.extractDailyPackage(for: today)
let formattedText = formatForAI(package)

// 发送给 AI
let prompt = """
你是一个用户画像分析助手。根据以下数据，提取有价值的知识节点。

\(formattedText)

请以 JSON 格式输出提取结果。
"""

let response = try await AIService.shared.sendMessage(prompt)
```

## Token 控制

```swift
// 估算文本长度
let estimatedTokens = package.stats.totalTextLength / 4  // 粗略估算

if estimatedTokens > 8000 {
    // 数据太多，需要分批或筛选
    print("数据量过大，建议分批处理")
}
```

## 注意事项

1. **AI 对话无需脱敏**：用户已经发送给 AI，代表接受了数据"泄露"
2. **关系 ID 格式**：`[REL_ID:displayName]` 可以直接解析
3. **未知人物**：会标记为 `[UNKNOWN_PERSON:原名]`
4. **敏感数字**：统一替换为 `[PHONE]`、`[ID_CARD]` 等

## 解析 AI 返回

```swift
// AI 返回的 personRef 格式: "[REL_001:妈妈]"
if let identifier = PersonIdentifier.parse(personRef) {
    print("关系ID: \(identifier.relationshipId)")  // "001"
    print("显示名: \(identifier.displayName)")      // "妈妈"
    
    // 直接使用 relationshipId 更新关系数据
    let relationship = NarrativeRelationshipRepository.shared.load(id: identifier.relationshipId)
}
```

## 完整示例

```swift
// 1. 提取数据
let package = try await DailyExtractionService.shared.extractDailyPackage(for: "2024.12.22")

// 2. 格式化
let text = formatForAI(package)

// 3. 发送给 AI
let aiResponse = try await AIService.shared.sendMessage(text)

// 4. 解析 AI 返回的知识节点
let nodes = try JSONDecoder().decode([KnowledgeNode].self, from: aiResponse.data)

// 5. 保存到用户画像
for node in nodes {
    if let personRef = node.personRef,
       let identifier = PersonIdentifier.parse(personRef) {
        // 更新关系的 attributes
        var relationship = NarrativeRelationshipRepository.shared.load(id: identifier.relationshipId)
        relationship?.attributes.append(node)
        NarrativeRelationshipRepository.shared.save(relationship!)
    } else {
        // 更新用户画像
        var profile = NarrativeUserProfileRepository.shared.load()
        profile.knowledgeNodes.append(node)
        NarrativeUserProfileRepository.shared.save(profile)
    }
}
```

---

**相关文档**：
- [AI 知识提取流程规划](architecture/AI-KNOWLEDGE-EXTRACTION-PLAN.md)
- [L4 画像数据扩展规划](architecture/L4-PROFILE-EXPANSION-PLAN.md)

---
**版本**: v1.0.0  
**更新日期**: 2024-12-22  
**状态**: 已发布
