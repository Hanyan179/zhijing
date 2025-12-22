import Foundation

// MARK: - Zone 1: Overview Stats (Always Displayed)

/// Core recording statistics - always shown in InsightSheet
public struct OverviewStats {
    public let streak: Int           // Consecutive days with entries
    public let totalDays: Int        // Total days with at least one entry
    public let totalEntries: Int     // Total JournalEntry count
    public let totalWords: Int       // Total character count from content
    
    public init(streak: Int = 0, totalDays: Int = 0, totalEntries: Int = 0, totalWords: Int = 0) {
        self.streak = streak
        self.totalDays = totalDays
        self.totalEntries = totalEntries
        self.totalWords = totalWords
    }
    
    public static let empty = OverviewStats()
}

// MARK: - Zone 2: Feature Usage Stats (Conditional Display)

/// Feature usage statistics - shown only when count > 0
public struct FeatureUsageStats {
    public let aiConversations: Int      // AI conversation count
    public let aiMessages: Int           // AI message count
    public let trackerDays: Int          // Days with DailyTrackerRecord
    public let mindRecords: Int          // MindStateRecord count
    public let capsuleTotal: Int         // Total QuestionEntry count
    public let capsulePending: Int       // Pending capsules (delivery_date > today)
    public let loveLogCount: Int         // LoveLog count
    public let relationshipCount: Int    // NarrativeRelationship count
    
    public init(
        aiConversations: Int = 0,
        aiMessages: Int = 0,
        trackerDays: Int = 0,
        mindRecords: Int = 0,
        capsuleTotal: Int = 0,
        capsulePending: Int = 0,
        loveLogCount: Int = 0,
        relationshipCount: Int = 0
    ) {
        self.aiConversations = aiConversations
        self.aiMessages = aiMessages
        self.trackerDays = trackerDays
        self.mindRecords = mindRecords
        self.capsuleTotal = capsuleTotal
        self.capsulePending = capsulePending
        self.loveLogCount = loveLogCount
        self.relationshipCount = relationshipCount
    }
    
    /// Returns true if any feature has data
    public var hasAnyData: Bool {
        return aiConversations > 0 ||
               trackerDays > 0 ||
               mindRecords > 0 ||
               capsuleTotal > 0 ||
               loveLogCount > 0 ||
               relationshipCount > 0
    }
    
    public static let empty = FeatureUsageStats()
}

// MARK: - Zone 3: Data Insight Stats (Threshold-based Display)

/// Data insight statistics - shown only when threshold met
public struct DataInsightStats {
    public let hourDistribution: [Int]                    // 24-hour distribution [0-23]
    public let activityDistribution: [String: Int]        // ActivityType rawValue -> count
    public let moodTrend: [(date: String, value: Int)]    // Sorted by date
    public let topLocations: [(name: String, count: Int)] // Sorted by count desc
    public let loveSources: [(name: String, count: Int)]  // Sorted by count desc
    
    public init(
        hourDistribution: [Int] = Array(repeating: 0, count: 24),
        activityDistribution: [String: Int] = [:],
        moodTrend: [(date: String, value: Int)] = [],
        topLocations: [(name: String, count: Int)] = [],
        loveSources: [(name: String, count: Int)] = []
    ) {
        self.hourDistribution = hourDistribution
        self.activityDistribution = activityDistribution
        self.moodTrend = moodTrend
        self.topLocations = topLocations
        self.loveSources = loveSources
    }
    
    public static let empty = DataInsightStats()
}

// MARK: - Visibility Thresholds

/// Thresholds for showing Zone 3 charts
public enum InsightThreshold {
    public static let hourChart = 10        // ≥10 entries for hour distribution
    public static let activityChart = 5     // ≥5 tracker days for activity pie
    public static let moodChart = 7         // ≥7 mind records for mood trend
    public static let locationRank = 3      // ≥3 locations for ranking
    public static let loveRank = 3          // ≥3 love logs for ranking
}
