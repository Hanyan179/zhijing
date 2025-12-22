import Foundation

// MARK: - Daily Extraction Service

/// 每日数据提取服务 - 从 L1 数据生成 AI 可用的脱敏数据包
public final class DailyExtractionService {
    
    public static let shared = DailyExtractionService()
    
    private let sanitizer = TextSanitizer()
    
    private init() {}
    
    // MARK: - Main Extraction Method
    
    /// 提取指定日期的数据包
    /// - Parameter dayId: 日期 (yyyy.MM.dd)
    /// - Returns: 脱敏后的每日数据包
    public func extractDailyPackage(for dayId: String) async throws -> DailyExtractionPackage {
        // 1. 加载关系数据，构建名称映射表
        let relationships = NarrativeRelationshipRepository.shared.loadAll()
        sanitizer.buildNameMap(from: relationships)
        
        // 2. 提取各数据源
        let journalEntries = try await extractJournalEntries(for: dayId)
        let trackerRecord = try await extractTrackerRecord(for: dayId)
        let loveLogs = try await extractLoveLogs(for: dayId)
        let conversations = try await extractConversations(for: dayId)
        
        // 3. 生成关系上下文
        let relationshipContexts = sanitizer.generateRelationshipContexts(from: relationships)
        
        // 4. 计算统计
        let stats = calculateStats(
            journals: journalEntries,
            tracker: trackerRecord,
            loveLogs: loveLogs,
            conversations: conversations
        )
        
        return DailyExtractionPackage(
            dayId: dayId,
            extractedAt: Date(),
            journalEntries: journalEntries,
            trackerRecord: trackerRecord,
            loveLogs: loveLogs,
            aiConversations: conversations,
            knownRelationships: relationshipContexts,
            stats: stats
        )
    }
    
    // MARK: - Extract Journal Entries
    
    private func extractJournalEntries(for dayId: String) async throws -> [SanitizedJournalEntry] {
        let timeline = TimelineRepository.shared.getDailyTimeline(for: dayId)
        
        // 从 timeline.items 中提取所有 entries
        var allEntries: [JournalEntry] = []
        for item in timeline.items {
            switch item {
            case .scene(let scene):
                allEntries.append(contentsOf: scene.entries)
            case .journey(let journey):
                allEntries.append(contentsOf: journey.entries)
            }
        }
        
        return allEntries.map { entry in
            SanitizedJournalEntry(
                id: entry.id,
                timestamp: extractTime(from: entry.timestamp),
                type: entry.type.rawValue,
                chronology: entry.chronology.rawValue,
                category: entry.category?.rawValue,
                content: sanitizer.sanitize(entry.content),
                sender: sanitizer.sanitizeName(entry.metadata?.sender)
            )
        }
    }
    
    // MARK: - Extract Tracker Record
    
    private func extractTrackerRecord(for dayId: String) async throws -> SanitizedTrackerRecord? {
        guard let record = DailyTrackerRepository.shared.load(for: dayId) else {
            return nil
        }
        
        let activities = try await extractActivities(record.activities)
        
        return SanitizedTrackerRecord(
            bodyEnergy: record.bodyEnergy,
            moodWeather: record.moodWeather,
            activities: activities
        )
    }
    
    private func extractActivities(_ activities: [ActivityContext]) async throws -> [SanitizedActivity] {
        return activities.map { activity in
            // 将 companionDetails (relationship IDs) 转换为 [REL_ID:name] 格式
            let companionRefs = convertCompanionDetails(activity.companionDetails)
            
            // 将 tag IDs 转换为 tag 文本
            let tagTexts = convertTagIds(activity.tags, activityType: activity.activityType)
            
            return SanitizedActivity(
                id: activity.id,
                activityType: activity.activityType.rawValue,
                companions: activity.companions.map { $0.rawValue },
                companionRefs: companionRefs,
                details: sanitizer.sanitize(activity.details),
                tags: tagTexts
            )
        }
    }
    
    /// 将 relationship IDs 转换为 [REL_ID:displayName] 格式
    private func convertCompanionDetails(_ ids: [String]?) -> [String] {
        guard let ids = ids else { return [] }
        
        return ids.compactMap { id in
            if let relationship = NarrativeRelationshipRepository.shared.load(id: id) {
                return "[REL_\(relationship.id):\(relationship.displayName)]"
            }
            return nil
        }
    }
    
    /// 将 tag IDs 转换为 tag 文本
    private func convertTagIds(_ ids: [String], activityType: ActivityType) -> [String] {
        return ids.compactMap { id in
            ActivityTagRepository.shared.getTag(id: id)?.text
        }
    }
    
    // MARK: - Extract Love Logs
    
    private func extractLoveLogs(for dayId: String) async throws -> [SanitizedLoveLog] {
        let allLogs = LoveLogRepository.shared.getAllLogs()
        
        // 过滤当天的记录
        let dayLogs = allLogs.filter { log in
            // mentionTime 格式是 yyyy.MM.dd
            log.mentionTime == dayId
        }
        
        return dayLogs.map { log in
            SanitizedLoveLog(
                id: log.id,
                timestamp: log.timestamp,
                senderRef: sanitizer.sanitizeName(log.sender) ?? log.sender,
                receiverRef: sanitizer.sanitizeName(log.receiver) ?? log.receiver,
                content: sanitizer.sanitize(log.content) ?? log.content
            )
        }
    }
    
    // MARK: - Extract AI Conversations
    
    private func extractConversations(for dayId: String) async throws -> [AIConversationSummary] {
        let allConversations = AIConversationRepository.shared.loadAll()
        
        // 过滤当天的对话
        let dayConversations = allConversations.filter { conv in
            // 从 createdAt 提取日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd"
            return dateFormatter.string(from: conv.createdAt) == dayId
        }
        
        return dayConversations.map { conv in
            // 只提取用户消息（无需脱敏）
            let userMessages = conv.messages
                .filter { $0.role == .user }
                .map { $0.content }
            
            return AIConversationSummary(
                id: conv.id,
                timestamp: formatTime(conv.createdAt),
                messageCount: conv.messages.count,
                userMessages: userMessages,
                topics: nil  // TODO: 可以后续添加主题提取
            )
        }
    }
    
    // MARK: - Calculate Stats
    
    private func calculateStats(
        journals: [SanitizedJournalEntry],
        tracker: SanitizedTrackerRecord?,
        loveLogs: [SanitizedLoveLog],
        conversations: [AIConversationSummary]
    ) -> ExtractionStats {
        // 估算文本长度
        var totalLength = 0
        
        for entry in journals {
            totalLength += entry.content?.count ?? 0
        }
        
        if let tracker = tracker {
            for activity in tracker.activities {
                totalLength += activity.details?.count ?? 0
            }
        }
        
        for log in loveLogs {
            totalLength += log.content.count
        }
        
        for conv in conversations {
            for msg in conv.userMessages {
                totalLength += msg.count
            }
        }
        
        return ExtractionStats(
            journalCount: journals.count,
            hasTracker: tracker != nil,
            loveLogCount: loveLogs.count,
            conversationCount: conversations.count,
            totalTextLength: totalLength
        )
    }
    
    // MARK: - Helpers
    
    private func extractTime(from timestamp: String) -> String {
        // timestamp 格式可能是 "yyyy.MM.dd HH:mm" 或 ISO8601
        if timestamp.contains(" ") {
            return String(timestamp.split(separator: " ").last ?? "")
        }
        // 尝试解析 ISO8601
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        return timestamp
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Extraction Options

/// 提取选项 - 控制提取哪些数据
public struct ExtractionOptions {
    public var includeJournals: Bool = true
    public var includeTracker: Bool = true
    public var includeLoveLogs: Bool = true
    public var includeConversations: Bool = true
    
    /// 最大文本长度（用于控制 token）
    public var maxTextLength: Int? = nil
    
    public static let all = ExtractionOptions()
    
    public static let journalsOnly = ExtractionOptions(
        includeJournals: true,
        includeTracker: false,
        includeLoveLogs: false,
        includeConversations: false
    )
    
    public init(
        includeJournals: Bool = true,
        includeTracker: Bool = true,
        includeLoveLogs: Bool = true,
        includeConversations: Bool = true,
        maxTextLength: Int? = nil
    ) {
        self.includeJournals = includeJournals
        self.includeTracker = includeTracker
        self.includeLoveLogs = includeLoveLogs
        self.includeConversations = includeConversations
        self.maxTextLength = maxTextLength
    }
}
