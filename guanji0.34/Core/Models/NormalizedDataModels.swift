import Foundation

// MARK: - L1.5 Layer: Normalized Data Layer

// MARK: - L1.5a: User Custom Data (Data Dictionary)

/// User custom data pool - stores all user-defined data with deduplication
public struct UserCustomData: Codable, Identifiable {
    public let id: String
    public let category: CustomDataCategory
    public let value: String
    public let createdAt: Date
    
    // Statistics
    public var usageCount: Int
    public var lastUsedAt: Date?
    public var firstUsedAt: Date
    
    // Multi-source tracking
    public var sources: [DataSourceRef]
    
    // Related information
    public var relatedActivity: ActivityType?
    public var relatedPersonID: String?         // NarrativeRelationship ID
    
    // Profile extraction status
    public var extractedToProfile: Bool
    public var extractedAt: Date?
    public var extractionReason: String?
    
    // Metadata
    public var metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        category: CustomDataCategory,
        value: String,
        createdAt: Date = Date(),
        usageCount: Int = 1,
        lastUsedAt: Date? = nil,
        firstUsedAt: Date = Date(),
        sources: [DataSourceRef] = [],
        relatedActivity: ActivityType? = nil,
        relatedPersonID: String? = nil,
        extractedToProfile: Bool = false,
        extractedAt: Date? = nil,
        extractionReason: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.category = category
        self.value = value
        self.createdAt = createdAt
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.firstUsedAt = firstUsedAt
        self.sources = sources
        self.relatedActivity = relatedActivity
        self.relatedPersonID = relatedPersonID
        self.extractedToProfile = extractedToProfile
        self.extractedAt = extractedAt
        self.extractionReason = extractionReason
        self.metadata = metadata
    }
}

// MARK: - Custom Data Category

public enum CustomDataCategory: String, Codable, CaseIterable {
    case game
    case sport
    case hobby
    case food
    case place
    case person
    case skill
    case interest
    case book
    case movie
    case music
    case other
    
    public var localizedKey: String { "custom_data_\(rawValue)" }
}

// MARK: - L1.5b: Structured Event (Normalized Event Stream)

/// Structured event - normalized events that reference UserCustomData
public struct StructuredEvent: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let eventType: EventType
    
    // Normalized fields
    public var title: String
    public var description: String?
    
    // References to UserCustomData (no duplication)
    public var participantIDs: [String]         // UserCustomData IDs (person)
    public var activityDetailIDs: [String]      // UserCustomData IDs (game/sport/etc)
    
    // Other fields
    public var location: String?                // POI (not coordinates)
    public var activityType: ActivityType?
    public var duration: TimeInterval?
    public var emotionalTone: String?
    
    // Dimension tags (pre-classification)
    public var dimensionTags: Set<DimensionTag>
    
    // Source traceability
    public var sources: [DataSourceRef]
    
    // Metadata
    public var metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        eventType: EventType,
        title: String,
        description: String? = nil,
        participantIDs: [String] = [],
        activityDetailIDs: [String] = [],
        location: String? = nil,
        activityType: ActivityType? = nil,
        duration: TimeInterval? = nil,
        emotionalTone: String? = nil,
        dimensionTags: Set<DimensionTag> = [],
        sources: [DataSourceRef] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.title = title
        self.description = description
        self.participantIDs = participantIDs
        self.activityDetailIDs = activityDetailIDs
        self.location = location
        self.activityType = activityType
        self.duration = duration
        self.emotionalTone = emotionalTone
        self.dimensionTags = dimensionTags
        self.sources = sources
        self.metadata = metadata
    }
}

// MARK: - Event Type

public enum EventType: String, Codable {
    case conversation
    case activity
    case emotion
    case location
    case social
    case work
    case health
}

// MARK: - Dimension Tag

public enum DimensionTag: String, Codable, CaseIterable {
    case identity       // 身份与生理
    case personality    // 性格与心理
    case social         // 社会与关系
    case competence     // 能力与发展
    case lifestyle      // 习惯与生活
    
    public var localizedKey: String { "dimension_\(rawValue)" }
}

// MARK: - Data Source Reference

/// Reference to raw data source
public struct DataSourceRef: Codable, Equatable {
    public let type: RawDataType
    public let id: String
    
    public init(type: RawDataType, id: String) {
        self.type = type
        self.id = id
    }
}

public enum RawDataType: String, Codable {
    case diary
    case chat
    case audio
    case gps
    case dailyTracker
}
