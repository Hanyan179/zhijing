import Foundation

// MARK: - L3 Layer: Narrative Relationship (叙事关系)

/// Relationship model based on narrative and fact anchors (no scores)
public struct NarrativeRelationship: Codable, Identifiable, Hashable {
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    
    // Basic identity
    public var type: CompanionType
    public var displayName: String
    public var realName: String?                // Optional, encrypted
    public var avatar: String?                  // Emoji or image path
    
    // Narrative description (user written)
    public var narrative: String?               // "我的大学室友，一起经历了很多"
    public var tags: [String]                   // User defined tags ["室友", "游戏搭子"]
    
    // Fact anchors (verifiable objective facts)
    public var factAnchors: RelationshipFactAnchors
    
    // Mention tracking (system generated)
    public var mentions: [RelationshipMention]
    
    // Type-specific metadata
    public var metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        type: CompanionType,
        displayName: String,
        realName: String? = nil,
        avatar: String? = nil,
        narrative: String? = nil,
        tags: [String] = [],
        factAnchors: RelationshipFactAnchors = RelationshipFactAnchors(),
        mentions: [RelationshipMention] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.type = type
        self.displayName = displayName
        self.realName = realName
        self.avatar = avatar
        self.narrative = narrative
        self.tags = tags
        self.factAnchors = factAnchors
        self.mentions = mentions
        self.metadata = metadata
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: NarrativeRelationship, rhs: NarrativeRelationship) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Relationship Fact Anchors (事实锚点)

/// Verifiable objective facts, replacing subjective scores
public struct RelationshipFactAnchors: Codable {
    public var firstMeetingDate: String?        // YYYY-MM-DD or YYYY-MM
    public var anniversaries: [Anniversary]     // List of anniversaries
    public var sharedExperiences: [String]      // ["一起去日本旅行", "大学毕业"]
    
    public init(
        firstMeetingDate: String? = nil,
        anniversaries: [Anniversary] = [],
        sharedExperiences: [String] = []
    ) {
        self.firstMeetingDate = firstMeetingDate
        self.anniversaries = anniversaries
        self.sharedExperiences = sharedExperiences
    }
}

// MARK: - Anniversary (纪念日)

/// A memorable date in the relationship
public struct Anniversary: Codable, Identifiable {
    public let id: String
    public var name: String                     // "相识纪念日", "结婚纪念日"
    public var date: String                     // MM-DD
    public var year: Int?                       // Optional year
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        date: String,
        year: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.year = year
    }
}

// MARK: - Relationship Mention (提及记录)

/// System auto-extracted mention record from diary/conversation
public struct RelationshipMention: Codable, Identifiable {
    public let id: String
    public let date: Date
    public let sourceType: MentionSource
    public let sourceId: String                 // JournalEntry ID or DailyTracker ID
    public let contextSnippet: String           // "今天和小明一起吃了火锅..."
    
    public init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        sourceType: MentionSource,
        sourceId: String,
        contextSnippet: String
    ) {
        self.id = id
        self.date = date
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.contextSnippet = contextSnippet
    }
}

// MARK: - Mention Source (提及来源)

/// Source type for relationship mentions
public enum MentionSource: String, Codable {
    case diary              // 日记
    case dailyTracker       // 每日快速记录
    case aiConversation     // AI对话
    
    public var localizedKey: String { "mention_source_\(rawValue)" }
}

// MARK: - Helper Extensions

extension NarrativeRelationship {
    /// Get recent mentions within specified days
    public func recentMentions(days: Int = 30) -> [RelationshipMention] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return mentions.filter { $0.date >= cutoffDate }
    }
    
    /// Get mention count for display
    public var mentionCount: Int {
        mentions.count
    }
    
    /// Check if has any fact anchors
    public var hasFactAnchors: Bool {
        factAnchors.firstMeetingDate != nil ||
        !factAnchors.anniversaries.isEmpty ||
        !factAnchors.sharedExperiences.isEmpty
    }
}

// MARK: - Migration Helper

extension NarrativeRelationship {
    /// Create from legacy RelationshipProfile (for migration)
    public static func fromLegacy(_ legacy: RelationshipProfile) -> NarrativeRelationship {
        NarrativeRelationship(
            id: legacy.id,
            createdAt: legacy.createdAt,
            updatedAt: legacy.updatedAt,
            type: legacy.type,
            displayName: legacy.displayName,
            realName: legacy.realName,
            avatar: legacy.avatar,
            narrative: legacy.notes,
            tags: legacy.tags,
            factAnchors: RelationshipFactAnchors(
                firstMeetingDate: legacy.metadata[RelationshipMetadataKey.anniversaryMet],
                anniversaries: [],
                sharedExperiences: []
            ),
            mentions: [],
            metadata: legacy.metadata
        )
    }
}
