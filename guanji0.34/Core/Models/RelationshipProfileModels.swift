import Foundation

// MARK: - L3 Layer: Relationship Profile (Semantic Memory)
// ⚠️ DEPRECATED: Use NarrativeRelationship from NarrativeRelationshipModels.swift instead
// This model contains score-based fields (intimacyLevel, emotionalConnection, etc.)
// that cannot be extracted from user diaries.
// Migration: Use ProfileMigrationService to migrate to NarrativeRelationship.

/// Relationship profile for managing social connections
/// - Warning: Deprecated. Use `NarrativeRelationship` instead.
@available(*, deprecated, message: "Use NarrativeRelationship from NarrativeRelationshipModels.swift")
public struct RelationshipProfile: Codable, Identifiable, Hashable {
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: RelationshipProfile, rhs: RelationshipProfile) -> Bool {
        lhs.id == rhs.id
    }
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    
    // Basic info
    public var type: CompanionType
    public var displayName: String
    public var realName: String?                // Optional, encrypted
    public var avatar: String?                  // Emoji or image path
    
    // Relationship attributes
    public var intimacyLevel: Int               // 1-10
    public var interactionFrequency: InteractionFrequency
    public var emotionalConnection: Int         // 1-10
    
    // Interaction statistics
    public var totalInteractions: Int
    public var lastInteractionDate: Date?
    public var recentInteractionDates: [Date]   // Last 30 days
    
    // Type-specific data
    public var metadata: [String: String]       // Flexible metadata for type-specific fields
    
    // Notes
    public var notes: String?
    public var tags: [String]
    
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        type: CompanionType,
        displayName: String,
        realName: String? = nil,
        avatar: String? = nil,
        intimacyLevel: Int = 5,
        interactionFrequency: InteractionFrequency = .occasional,
        emotionalConnection: Int = 5,
        totalInteractions: Int = 0,
        lastInteractionDate: Date? = nil,
        recentInteractionDates: [Date] = [],
        metadata: [String: String] = [:],
        notes: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.type = type
        self.displayName = displayName
        self.realName = realName
        self.avatar = avatar
        self.intimacyLevel = intimacyLevel
        self.interactionFrequency = interactionFrequency
        self.emotionalConnection = emotionalConnection
        self.totalInteractions = totalInteractions
        self.lastInteractionDate = lastInteractionDate
        self.recentInteractionDates = recentInteractionDates
        self.metadata = metadata
        self.notes = notes
        self.tags = tags
    }
}

// MARK: - Interaction Frequency

public enum InteractionFrequency: String, Codable {
    case daily          // 每天
    case frequent       // 频繁 (每周多次)
    case regular        // 定期 (每周)
    case occasional     // 偶尔 (每月)
    case rare           // 罕见 (每季度)
    case veryRare       // 极少 (每年)
    
    public var localizedKey: String { "interaction_\(rawValue)" }
}

// MARK: - Type-Specific Metadata Keys

/// Metadata keys for different relationship types
public enum RelationshipMetadataKey {
    // Partner
    public static let partnerStatus = "partner_status"              // dating/married/separated
    public static let anniversaryMet = "anniversary_met"            // MM-DD
    public static let anniversaryDating = "anniversary_dating"      // MM-DD
    public static let anniversaryMarried = "anniversary_married"    // MM-DD
    
    // Family
    public static let familyRole = "family_role"                    // parent/child/sibling/other
    public static let livingTogether = "living_together"            // true/false
    
    // Friends
    public static let friendIntimacy = "friend_intimacy"            // acquaintance/friend/closeFriend/bestFriend
    public static let yearsKnown = "years_known"                    // Int
    
    // Colleagues
    public static let workRelationship = "work_relationship"        // superior/subordinate/peer/partner
    public static let company = "company"                           // String
    public static let department = "department"                     // String
    
    // Online Friends
    public static let platform = "platform"                         // String
    public static let hasMetInPerson = "has_met_in_person"          // true/false
    
    // Pet
    public static let petType = "pet_type"                          // cat/dog/bird/fish/other
    public static let petAge = "pet_age"                            // Int
    public static let petBreed = "pet_breed"                        // String
}

// MARK: - Helper Extensions

extension RelationshipProfile {
    // Partner helpers
    public var partnerStatus: String? {
        get { metadata[RelationshipMetadataKey.partnerStatus] }
        set { metadata[RelationshipMetadataKey.partnerStatus] = newValue }
    }
    
    public var anniversaryMet: String? {
        get { metadata[RelationshipMetadataKey.anniversaryMet] }
        set { metadata[RelationshipMetadataKey.anniversaryMet] = newValue }
    }
    
    public var anniversaryDating: String? {
        get { metadata[RelationshipMetadataKey.anniversaryDating] }
        set { metadata[RelationshipMetadataKey.anniversaryDating] = newValue }
    }
    
    public var anniversaryMarried: String? {
        get { metadata[RelationshipMetadataKey.anniversaryMarried] }
        set { metadata[RelationshipMetadataKey.anniversaryMarried] = newValue }
    }
    
    // Family helpers
    public var familyRole: String? {
        get { metadata[RelationshipMetadataKey.familyRole] }
        set { metadata[RelationshipMetadataKey.familyRole] = newValue }
    }
    
    public var livingTogether: Bool {
        get { metadata[RelationshipMetadataKey.livingTogether] == "true" }
        set { metadata[RelationshipMetadataKey.livingTogether] = newValue ? "true" : "false" }
    }
    
    // Friends helpers
    public var friendIntimacy: String? {
        get { metadata[RelationshipMetadataKey.friendIntimacy] }
        set { metadata[RelationshipMetadataKey.friendIntimacy] = newValue }
    }
    
    public var yearsKnown: Int? {
        get { 
            guard let value = metadata[RelationshipMetadataKey.yearsKnown] else { return nil }
            return Int(value)
        }
        set { 
            metadata[RelationshipMetadataKey.yearsKnown] = newValue.map { String($0) }
        }
    }
    
    // Colleagues helpers
    public var workRelationship: String? {
        get { metadata[RelationshipMetadataKey.workRelationship] }
        set { metadata[RelationshipMetadataKey.workRelationship] = newValue }
    }
    
    public var company: String? {
        get { metadata[RelationshipMetadataKey.company] }
        set { metadata[RelationshipMetadataKey.company] = newValue }
    }
    
    public var department: String? {
        get { metadata[RelationshipMetadataKey.department] }
        set { metadata[RelationshipMetadataKey.department] = newValue }
    }
    
    // Online Friends helpers
    public var platform: String? {
        get { metadata[RelationshipMetadataKey.platform] }
        set { metadata[RelationshipMetadataKey.platform] = newValue }
    }
    
    public var hasMetInPerson: Bool {
        get { metadata[RelationshipMetadataKey.hasMetInPerson] == "true" }
        set { metadata[RelationshipMetadataKey.hasMetInPerson] = newValue ? "true" : "false" }
    }
    
    // Pet helpers
    public var petType: String? {
        get { metadata[RelationshipMetadataKey.petType] }
        set { metadata[RelationshipMetadataKey.petType] = newValue }
    }
    
    public var petAge: Int? {
        get {
            guard let value = metadata[RelationshipMetadataKey.petAge] else { return nil }
            return Int(value)
        }
        set {
            metadata[RelationshipMetadataKey.petAge] = newValue.map { String($0) }
        }
    }
    
    public var petBreed: String? {
        get { metadata[RelationshipMetadataKey.petBreed] }
        set { metadata[RelationshipMetadataKey.petBreed] = newValue }
    }
}

// MARK: - Relationship Health Analysis

public struct RelationshipHealth {
    public let score: Double
    public let status: HealthStatus
    public let suggestions: [String]
    
    public enum HealthStatus: String {
        case healthy, normal, needsAttention
    }
    
    public init(score: Double, status: HealthStatus, suggestions: [String]) {
        self.score = score
        self.status = status
        self.suggestions = suggestions
    }
}
