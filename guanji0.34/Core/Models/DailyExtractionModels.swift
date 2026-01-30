import Foundation

// MARK: - Daily Extraction Data Package

/// 每日数据提取包 - AI 知识提取的输入数据结构
/// 所有人物引用已统一为 [REL_ID:displayName] 格式
public struct DailyExtractionPackage: Codable {
    public let dayId: String                          // yyyy.MM.dd
    public let extractedAt: Date
    
    // MARK: - L1 Data Sources (已脱敏)
    
    /// 日记条目（content 已脱敏）
    public let journalEntries: [SanitizedJournalEntry]
    
    /// 每日追踪（details 已脱敏，companionDetails 已转换为标识符）
    public let trackerRecord: SanitizedTrackerRecord?
    
    /// 爱表（sender/receiver/content 已脱敏）
    public let loveLogs: [SanitizedLoveLog]
    
    /// AI 对话（包含用户消息和AI回复，不含思考过程）
    public let aiConversations: [AIConversationSummary]
    
    /// 问题表（当天显示的问题）
    public let questions: [SanitizedQuestion]
    
    public init(
        dayId: String,
        extractedAt: Date = Date(),
        journalEntries: [SanitizedJournalEntry] = [],
        trackerRecord: SanitizedTrackerRecord? = nil,
        loveLogs: [SanitizedLoveLog] = [],
        aiConversations: [AIConversationSummary] = [],
        questions: [SanitizedQuestion] = []
    ) {
        self.dayId = dayId
        self.extractedAt = extractedAt
        self.journalEntries = journalEntries
        self.trackerRecord = trackerRecord
        self.loveLogs = loveLogs
        self.aiConversations = aiConversations
        self.questions = questions
    }
}

// MARK: - Sanitized Data Types

/// 脱敏后的日记条目
public struct SanitizedJournalEntry: Codable {
    public let timestamp: String                      // HH:mm
    public let type: String                           // EntryType.rawValue
    public let chronology: String                     // past | present | future
    public let category: String?                      // EntryCategory.rawValue
    public let content: String?                       // 已脱敏的文本内容
    public let sender: String?                        // 已转换为 [REL_ID:name] 或保留原样
    public let targetDate: String?                    // 目标日期（past类型：发送给哪一天）
    
    public init(
        timestamp: String,
        type: String,
        chronology: String,
        category: String?,
        content: String?,
        sender: String?,
        targetDate: String? = nil
    ) {
        self.timestamp = timestamp
        self.type = type
        self.chronology = chronology
        self.category = category
        self.content = content
        self.sender = sender
        self.targetDate = targetDate
    }
}

/// 脱敏后的每日追踪记录
public struct SanitizedTrackerRecord: Codable {
    public let bodyEnergy: Int                        // 0-100
    public let moodWeather: Int                       // 0-100
    public let activities: [SanitizedActivity]
    
    public init(
        bodyEnergy: Int,
        moodWeather: Int,
        activities: [SanitizedActivity]
    ) {
        self.bodyEnergy = bodyEnergy
        self.moodWeather = moodWeather
        self.activities = activities
    }
}

/// 脱敏后的活动上下文
public struct SanitizedActivity: Codable {
    public let activityType: String                   // ActivityType.rawValue
    public let companions: [String]                   // CompanionType.rawValue[]
    public let companionRefs: [String]                // [REL_ID:name] 格式
    public let details: String?                       // 已脱敏的详情
    public let tags: [String]                         // 标签文本（非 ID）
    
    public init(
        activityType: String,
        companions: [String],
        companionRefs: [String],
        details: String?,
        tags: [String]
    ) {
        self.activityType = activityType
        self.companions = companions
        self.companionRefs = companionRefs
        self.details = details
        self.tags = tags
    }
}

/// 脱敏后的爱表记录
public struct SanitizedLoveLog: Codable {
    public let timestamp: String
    public let senderRef: String                      // [REL_ID:name] 或 "Me"
    public let receiverRef: String                    // [REL_ID:name] 或 "Me"
    public let content: String                        // 已脱敏的内容
    
    public init(
        timestamp: String,
        senderRef: String,
        receiverRef: String,
        content: String
    ) {
        self.timestamp = timestamp
        self.senderRef = senderRef
        self.receiverRef = receiverRef
        self.content = content
    }
}

/// AI 对话摘要（无需脱敏）
public struct AIConversationSummary: Codable {
    public let timestamp: String
    public let messageCount: Int
    public let messages: [AIMessageSummary]           // 按顺序的对话消息（用户问→AI回→...）
    public let topics: [String]?                      // 可选：对话主题标签
    
    public init(
        timestamp: String,
        messageCount: Int,
        messages: [AIMessageSummary] = [],
        topics: [String]? = nil
    ) {
        self.timestamp = timestamp
        self.messageCount = messageCount
        self.messages = messages
        self.topics = topics
    }
}

/// AI 对话消息摘要
public struct AIMessageSummary: Codable {
    public let role: String                           // "user" | "assistant"
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// 脱敏后的问题记录
public struct SanitizedQuestion: Codable {
    public let createdAt: String                      // 创建日期
    public let dayId: String                          // 关联的日期
    public let systemPrompt: String?                  // 问题内容
    public let intervalDays: Int                      // 间隔天数
    public let deliveryDate: String                   // 交付日期
    
    public init(
        createdAt: String,
        dayId: String,
        systemPrompt: String?,
        intervalDays: Int,
        deliveryDate: String
    ) {
        self.createdAt = createdAt
        self.dayId = dayId
        self.systemPrompt = systemPrompt
        self.intervalDays = intervalDays
        self.deliveryDate = deliveryDate
    }
}

// MARK: - Context Types

/// 关系上下文（供 AI 匹配）
public struct RelationshipContext: Codable, Identifiable {
    public let id: String                             // relationship ID
    public let ref: String                            // [REL_ID:displayName] 格式
    public let type: String                           // CompanionType.rawValue
    public let displayName: String
    public let aliases: [String]                      // 所有别名（不含 realName）
    
    public init(
        id: String,
        ref: String,
        type: String,
        displayName: String,
        aliases: [String]
    ) {
        self.id = id
        self.ref = ref
        self.type = type
        self.displayName = displayName
        self.aliases = aliases
    }
}

/// 提取统计
public struct ExtractionStats: Codable {
    public let journalCount: Int
    public let hasTracker: Bool
    public let loveLogCount: Int
    public let conversationCount: Int
    public let totalTextLength: Int                   // 估算 token 用
    
    public var isEmpty: Bool {
        journalCount == 0 && !hasTracker && loveLogCount == 0 && conversationCount == 0
    }
    
    public init(
        journalCount: Int,
        hasTracker: Bool,
        loveLogCount: Int,
        conversationCount: Int,
        totalTextLength: Int
    ) {
        self.journalCount = journalCount
        self.hasTracker = hasTracker
        self.loveLogCount = loveLogCount
        self.conversationCount = conversationCount
        self.totalTextLength = totalTextLength
    }
}

// MARK: - Person Identifier

/// 统一人物标识符
public struct PersonIdentifier {
    public let relationshipId: String
    public let displayName: String
    
    /// 格式化为 [REL_ID:displayName]
    public var formatted: String {
        "[REL_\(relationshipId):\(displayName)]"
    }
    
    /// 从格式化字符串解析
    public static func parse(_ formatted: String) -> PersonIdentifier? {
        // 匹配 [REL_xxx:yyy] 格式
        let pattern = "\\[REL_([^:]+):([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: formatted, range: NSRange(formatted.startIndex..., in: formatted)),
              let idRange = Range(match.range(at: 1), in: formatted),
              let nameRange = Range(match.range(at: 2), in: formatted) else {
            return nil
        }
        return PersonIdentifier(
            relationshipId: String(formatted[idRange]),
            displayName: String(formatted[nameRange])
        )
    }
    
    public init(relationshipId: String, displayName: String) {
        self.relationshipId = relationshipId
        self.displayName = displayName
    }
}
