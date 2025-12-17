import Foundation

public struct QuestionEntry: Codable, Identifiable {
    public let id: String
    public let created_at: String
    public let updated_at: String
    public let system_prompt: String?
    public let journal_now_id: String
    public let journal_future_id: String?
    public let interval_days: Int
    public let delivery_date: String
}

public struct LoveLog: Codable, Identifiable {
    public let id: String
    public let mentionTime: String
    public let timestamp: String
    public let sender: String
    public let receiver: String
    public let content: String
    public let originalText: String
}

public enum AchievementStatus: String, Codable {
    case locked
    case detectedTeaser
    case unlocked
}

public struct LocalizedString: Codable {
    public let en: String
    public let zh: String
}

public struct UserAchievement: Codable, Identifiable {
    public var id: String { definitionId }
    public let definitionId: String
    public let status: AchievementStatus
    public let currentLevel: Int
    public let progressValue: Double
    public let targetValue: Double
    public let aiGeneratedTitle: LocalizedString?
    public let aiPoeticDescription: LocalizedString?
    public let aiComment: LocalizedString?
    public let relatedEntryIDs: [String]
    public let lastUpdatedAt: String
    public let unlockedAt: String?
}

public struct DayRecord: Codable, Identifiable {
    public let id: String
    public let date: String
    public let title: String
    public let summary: String
    public let tags: [EntryCategory]
}

public typealias HistoryItem = DayRecord
