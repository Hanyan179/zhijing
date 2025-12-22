import Foundation

// MARK: - Basic Enums

public enum Gender: String, Codable, CaseIterable {
    case male, female, other
    
    public var localizedValue: String {
        Localization.tr("gender_\(rawValue)")
    }
}

public enum Education: String, Codable, CaseIterable {
    case highSchool, bachelor, master, phd
    
    public var localizedValue: String {
        Localization.tr("education_\(rawValue)")
    }
}

// MARK: - L3 Layer: Narrative User Profile (叙事用户画像)

/// Main user profile with narrative-based design (no scores)
public struct NarrativeUserProfile: Codable, Identifiable {
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    
    // Static core - user manually input, rarely changes
    public var staticCore: StaticCore
    
    // Recent portrait - AI generated based on recent data (implemented later)
    public var recentPortrait: RecentPortrait?
    
    // 🆕 Dynamic knowledge nodes (L4 expansion)
    // Stores skills, values, goals, traits, hobbies, etc.
    public var knowledgeNodes: [KnowledgeNode]
    
    // 🆕 AI conversation preferences
    public var aiPreferences: AIPreferences?
    
    // Relationship constellation references
    public var relationshipIds: [String]
    
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        staticCore: StaticCore = StaticCore(),
        recentPortrait: RecentPortrait? = nil,
        knowledgeNodes: [KnowledgeNode] = [],
        aiPreferences: AIPreferences? = nil,
        relationshipIds: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.staticCore = staticCore
        self.recentPortrait = recentPortrait
        self.knowledgeNodes = knowledgeNodes
        self.aiPreferences = aiPreferences
        self.relationshipIds = relationshipIds
    }
}

// MARK: - Static Core (静态内核)

/// User manually input identity information - all fields optional
public struct StaticCore: Codable {
    // Basic identity (all optional)
    public var gender: Gender?
    public var birthYearMonth: String?          // YYYY-MM
    public var hometown: String?
    public var currentCity: String?
    
    // Occupation info
    public var occupation: String?
    public var industry: String?
    public var education: Education?
    
    // Self description tags (user defined)
    public var selfTags: [String]
    
    // Update history tracking
    public var updateHistory: [ProfileUpdateRecord]
    
    public init(
        gender: Gender? = nil,
        birthYearMonth: String? = nil,
        hometown: String? = nil,
        currentCity: String? = nil,
        occupation: String? = nil,
        industry: String? = nil,
        education: Education? = nil,
        selfTags: [String] = [],
        updateHistory: [ProfileUpdateRecord] = []
    ) {
        self.gender = gender
        self.birthYearMonth = birthYearMonth
        self.hometown = hometown
        self.currentCity = currentCity
        self.occupation = occupation
        self.industry = industry
        self.education = education
        self.selfTags = selfTags
        self.updateHistory = updateHistory
    }
}

// MARK: - Profile Update Record

/// Record of a single field update for history tracking
public struct ProfileUpdateRecord: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let fieldName: String
    public let oldValue: String?
    public let newValue: String?
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        fieldName: String,
        oldValue: String?,
        newValue: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - Recent Portrait (近期画像)

/// AI generated narrative portrait based on recent data
/// Placeholder structure - full implementation in later phase
public struct RecentPortrait: Codable, Identifiable {
    public let id: String
    public let generatedAt: Date
    public let dataRangeStart: Date
    public let dataRangeEnd: Date
    
    // Narrative summaries (AI generated)
    public var overallNarrative: String
    public var focusNarrative: String?
    
    // Extracted keywords (factual data)
    public var focusTopics: [String]
    public var moodKeywords: [String]
    public var frequentActivities: [String]
    
    // Comparison with previous period
    public var comparisonNarrative: String?
    
    public init(
        id: String = UUID().uuidString,
        generatedAt: Date = Date(),
        dataRangeStart: Date,
        dataRangeEnd: Date,
        overallNarrative: String,
        focusNarrative: String? = nil,
        focusTopics: [String] = [],
        moodKeywords: [String] = [],
        frequentActivities: [String] = [],
        comparisonNarrative: String? = nil
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.dataRangeStart = dataRangeStart
        self.dataRangeEnd = dataRangeEnd
        self.overallNarrative = overallNarrative
        self.focusNarrative = focusNarrative
        self.focusTopics = focusTopics
        self.moodKeywords = moodKeywords
        self.frequentActivities = frequentActivities
        self.comparisonNarrative = comparisonNarrative
    }
}

// MARK: - Shared Enums (reuse from existing models)

// Gender and Education enums are already defined in UserProfileModels.swift
// We reference them here for clarity but don't redefine to avoid conflicts
