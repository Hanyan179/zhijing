import Foundation

// MARK: - Basic Enums

public enum Gender: String, Codable, CaseIterable {
    case male, female, other
    
    public var localizedValue: String {
        Localization.tr("gender_\(rawValue)")
    }
    
    public var displayName: String {
        switch self {
        case .male: return Localization.tr("enum_gender_male")
        case .female: return Localization.tr("enum_gender_female")
        case .other: return Localization.tr("enum_gender_other")
        }
    }
}

public enum Education: String, Codable, CaseIterable {
    case highSchool, bachelor, master, phd
    
    public var localizedValue: String {
        Localization.tr("education_\(rawValue)")
    }
    
    public var displayName: String {
        switch self {
        case .highSchool: return Localization.tr("enum_education_highSchool")
        case .bachelor: return Localization.tr("enum_education_bachelor")
        case .master: return Localization.tr("enum_education_master")
        case .phd: return Localization.tr("enum_education_phd")
        }
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
/// 纯静态核心信息，不包含任何动态或历史数据
public struct StaticCore: Codable {
    // Basic identity (all optional)
    public var nickname: String?                // 用户昵称
    public var gender: Gender?
    public var birthYearMonth: String?          // YYYY-MM
    public var hometown: String?
    public var currentCity: String?
    
    // Occupation info
    public var occupation: String?
    public var industry: String?
    public var education: Education?
    
    // MARK: - Codable with backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case nickname
        case gender
        case birthYearMonth
        case hometown
        case currentCity
        case occupation
        case industry
        case education
        case selfTags       // 旧字段，用于迁移
        case updateHistory  // 旧字段，忽略
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        birthYearMonth = try container.decodeIfPresent(String.self, forKey: .birthYearMonth)
        hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        currentCity = try container.decodeIfPresent(String.self, forKey: .currentCity)
        occupation = try container.decodeIfPresent(String.self, forKey: .occupation)
        industry = try container.decodeIfPresent(String.self, forKey: .industry)
        education = try container.decodeIfPresent(Education.self, forKey: .education)
        
        // 向后兼容：如果没有 nickname 但有 selfTags，使用第一个 selfTag 作为 nickname
        if nickname == nil {
            if let selfTags = try container.decodeIfPresent([String].self, forKey: .selfTags),
               let firstTag = selfTags.first, !firstTag.isEmpty {
                nickname = firstTag
            }
        }
        // updateHistory 直接忽略，不再读取
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(birthYearMonth, forKey: .birthYearMonth)
        try container.encodeIfPresent(hometown, forKey: .hometown)
        try container.encodeIfPresent(currentCity, forKey: .currentCity)
        try container.encodeIfPresent(occupation, forKey: .occupation)
        try container.encodeIfPresent(industry, forKey: .industry)
        try container.encodeIfPresent(education, forKey: .education)
        // 不再写入 selfTags 和 updateHistory
    }
    
    public init(
        nickname: String? = nil,
        gender: Gender? = nil,
        birthYearMonth: String? = nil,
        hometown: String? = nil,
        currentCity: String? = nil,
        occupation: String? = nil,
        industry: String? = nil,
        education: Education? = nil
    ) {
        self.nickname = nickname
        self.gender = gender
        self.birthYearMonth = birthYearMonth
        self.hometown = hometown
        self.currentCity = currentCity
        self.occupation = occupation
        self.industry = industry
        self.education = education
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
