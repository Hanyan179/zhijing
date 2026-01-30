import Foundation
import SwiftUI

// MARK: - Body Energy Level

/// 7-segment body energy level (-3 to +3)
public enum BodyEnergyLevel: Int, CaseIterable, Identifiable {
    case collapsed = -3      // 累趴了
    case exhausted = -2      // 筋疲力尽
    case tired = -1          // 有点累
    case normal = 0          // 正常
    case fresh = 1           // 精神不错
    case energetic = 2       // 精力充沛
    case unstoppable = 3     // 状态爆表
    
    public var id: Int { rawValue }
    
    public var titleKey: String {
        switch self {
        case .collapsed: return "body_collapsed"
        case .exhausted: return "body_exhausted"
        case .tired: return "body_tired"
        case .normal: return "body_normal"
        case .fresh: return "body_fresh"
        case .energetic: return "body_energetic"
        case .unstoppable: return "body_unstoppable"
        }
    }
    
    public var iconName: String {
        switch self {
        case .collapsed: return "battery.0"
        case .exhausted: return "battery.25"
        case .tired: return "battery.25"
        case .normal: return "battery.50"
        case .fresh: return "battery.75"
        case .energetic: return "battery.100"
        case .unstoppable: return "bolt.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .collapsed, .exhausted:
            return Color(red: 0.90, green: 0.30, blue: 0.30)
        case .tired:
            return Color(red: 0.94, green: 0.60, blue: 0.64)
        case .normal:
            return Color(red: 0.95, green: 0.80, blue: 0.20)
        case .fresh:
            return Color(red: 0.38, green: 0.74, blue: 0.52)
        case .energetic, .unstoppable:
            return Color(red: 0.30, green: 0.80, blue: 0.40)
        }
    }
    
    /// Map 0-100 continuous value to 7 levels for smooth slider experience
    public static func from(_ value: Int) -> BodyEnergyLevel {
        // 0-100 → 7 levels (each ~14.3 points)
        switch value {
        case 0..<15: return .collapsed
        case 15..<29: return .exhausted
        case 29..<43: return .tired
        case 43..<57: return .normal
        case 57..<71: return .fresh
        case 71..<86: return .energetic
        default: return .unstoppable
        }
    }
}

// MARK: - Daily Tracker Record (L1 Layer)

/// Main record for daily quick tracking
public struct DailyTrackerRecord: Codable, Identifiable {
    public let id: String
    public let date: String                    // yyyy.MM.dd (统一日期格式)
    public let createdAt: Date
    public let updatedAt: Date
    
    // Step 1: Daily Status (0-100 continuous scale)
    public let bodyEnergy: Int                 // 0-100 (50 = normal)
    public let moodWeather: Int                // 0-100 (50 = neutral)
    
    // Step 2 & 3: Activities + Context
    public let activities: [ActivityContext]
    
    public init(
        id: String = UUID().uuidString,
        date: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        bodyEnergy: Int,
        moodWeather: Int,
        activities: [ActivityContext]
    ) {
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bodyEnergy = bodyEnergy
        self.moodWeather = moodWeather
        self.activities = activities
    }
}

// MARK: - Activity Context

/// Context for a single activity
public struct ActivityContext: Codable, Identifiable {
    public let id: String
    public let activityType: ActivityType
    public var companions: [CompanionType]
    public var companionDetails: [String]?     // NarrativeRelationship IDs
    public var details: String?
    public var tags: [String]                  // ActivityTag IDs
    
    public init(
        id: String = UUID().uuidString,
        activityType: ActivityType,
        companions: [CompanionType] = [],
        companionDetails: [String]? = nil,
        details: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.activityType = activityType
        self.companions = companions
        self.companionDetails = companionDetails
        self.details = details
        self.tags = tags
    }
}

// MARK: - Activity Type

/// 22 preset activity types organized by five-dimension model
public enum ActivityType: String, Codable, CaseIterable, Identifiable {
    // A. Competence & Habits (生存与产出)
    case work = "work"
    case study = "study"
    case housework = "housework"
    case shopping = "shopping"
    case errands = "errands"
    case medical = "medical"
    
    // B. Identity & Personality (探索与身心)
    case internet = "internet"
    case reading = "reading"
    case creativity = "creativity"
    case relax = "relax"
    case gaming = "gaming"
    case exercise = "exercise"
    case outdoors = "outdoors"
    case moviesTV = "movies_tv"
    
    // C. Social & Relations (连接与情感)
    case date = "date"
    case walkPet = "walk_pet"
    case party = "party"
    case travel = "travel"
    
    public var id: String { rawValue }
    
    public var group: ActivityGroup {
        switch self {
        case .work, .study, .housework, .shopping, .errands, .medical:
            return .competence
        case .internet, .reading, .creativity, .relax, .gaming, .exercise, .outdoors, .moviesTV:
            return .identity
        case .date, .walkPet, .party, .travel:
            return .social
        }
    }
    
    public var localizedKey: String { "activity_\(rawValue)" }
    
    public var iconName: String {
        switch self {
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .housework: return "house.fill"
        case .shopping: return "cart.fill"
        case .errands: return "list.bullet"
        case .medical: return "cross.case.fill"
        case .internet: return "wifi"
        case .reading: return "book.pages.fill"
        case .creativity: return "paintbrush.fill"
        case .relax: return "bed.double.fill"
        case .gaming: return "gamecontroller.fill"
        case .exercise: return "figure.run"
        case .outdoors: return "leaf.fill"
        case .moviesTV: return "tv.fill"
        case .date: return "heart.fill"
        case .walkPet: return "pawprint.fill"
        case .party: return "party.popper.fill"
        case .travel: return "airplane"
        }
    }
    
    public var isWorkRelated: Bool {
        return self == .work || self == .study
    }
    
    /// Default companion types for this activity
    public var defaultCompanions: [CompanionType] {
        switch self {
        case .date: return [.partner]           // 约会 → 伴侣
        case .walkPet: return [.pet]            // 遛宠 → 宠物
        case .party: return [.friends]          // 聚会 → 朋友
        case .work, .study: return [.alone]     // 工作/学习 → 独处
        default: return []                       // 其他 → 用户选择
        }
    }
}

// MARK: - Activity Group

public enum ActivityGroup: String, Codable {
    case competence = "competence"      // 生存与产出
    case identity = "identity"          // 探索与身心
    case social = "social"              // 连接与情感
    
    public var localizedKey: String { "activity_group_\(rawValue)" }
    
    public var activities: [ActivityType] {
        ActivityType.allCases.filter { $0.group == self }
    }
}

// MARK: - Companion Type

/// 7 preset relationship types
public enum CompanionType: String, Codable, CaseIterable, Identifiable {
    case alone = "alone"
    case partner = "partner"
    case family = "family"
    case friends = "friends"
    case colleagues = "colleagues"
    case onlineFriends = "online_friends"
    case pet = "pet"
    
    public var id: String { rawValue }
    public var localizedKey: String { "companion_\(rawValue)" }
    
    public var iconName: String {
        switch self {
        case .alone: return "person.fill"
        case .partner: return "heart.fill"
        case .family: return "house.fill"
        case .friends: return "person.2.fill"
        case .colleagues: return "briefcase.fill"
        case .onlineFriends: return "network"
        case .pet: return "pawprint.fill"
        }
    }
}

// MARK: - Activity Tag

/// User-customizable tags for activities
public struct ActivityTag: Codable, Identifiable {
    public let id: String
    public let activityType: ActivityType
    public let text: String
    public let isSystemPreset: Bool
    public var usageCount: Int
    public var lastUsedAt: Date?
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        activityType: ActivityType,
        text: String,
        isSystemPreset: Bool = false,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.activityType = activityType
        self.text = text
        self.isSystemPreset = isSystemPreset
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}

// MARK: - Companion Profile

/// User-customizable companion profiles
public struct CompanionProfile: Codable, Identifiable {
    public let id: String
    public let name: String
    public let type: CompanionType
    public var usageCount: Int
    public var lastUsedAt: Date?
    public let createdAt: Date
    public var notes: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: CompanionType,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.notes = notes
    }
}

// MARK: - Smart Preference

/// Smart prefill preferences based on user habits
public struct SmartPreference: Codable {
    public let activityType: ActivityType
    public var preferredCompanions: [CompanionType]
    public var preferredTags: [String]              // ActivityTag IDs
    public var lastUpdatedAt: Date
    
    public init(
        activityType: ActivityType,
        preferredCompanions: [CompanionType] = [],
        preferredTags: [String] = [],
        lastUpdatedAt: Date = Date()
    ) {
        self.activityType = activityType
        self.preferredCompanions = preferredCompanions
        self.preferredTags = preferredTags
        self.lastUpdatedAt = lastUpdatedAt
    }
}
