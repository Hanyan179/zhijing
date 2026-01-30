import Foundation

// MARK: - L4 Layer: AI Preferences (AI 对话偏好)
// User preferences for AI interaction

/// AI conversation preferences - user's preferences for AI interaction
public struct AIPreferences: Codable {
    // ===== Style Preferences =====
    public var style: AIStylePreference
    
    // ===== Response Preferences =====
    public var response: AIResponsePreference
    
    // ===== Topic Preferences =====
    public var topics: AITopicPreference
    
    // ===== Tracking Information =====
    public var tracking: NodeTracking
    
    public init(
        style: AIStylePreference = AIStylePreference(),
        response: AIResponsePreference = AIResponsePreference(),
        topics: AITopicPreference = AITopicPreference(),
        tracking: NodeTracking = NodeTracking()
    ) {
        self.style = style
        self.response = response
        self.topics = topics
        self.tracking = tracking
    }
}

// MARK: - AI Style Preference

/// AI style preferences
public struct AIStylePreference: Codable {
    public var tone: AITone?                      // formal | casual | friendly | professional
    public var verbosity: AIVerbosity?            // concise | balanced | detailed
    public var personality: AIPersonality?        // supportive | challenging | neutral
    public var language: String?                  // Preferred language style
    
    public init(
        tone: AITone? = nil,
        verbosity: AIVerbosity? = nil,
        personality: AIPersonality? = nil,
        language: String? = nil
    ) {
        self.tone = tone
        self.verbosity = verbosity
        self.personality = personality
        self.language = language
    }
}

// MARK: - AI Tone

/// AI conversation tone
public enum AITone: String, Codable, CaseIterable {
    case formal         // 正式
    case casual         // 随意
    case friendly       // 友好
    case professional   // 专业
    
    public var localizedValue: String {
        Localization.tr("ai_tone_\(rawValue)")
    }
}

// MARK: - AI Verbosity

/// AI response verbosity level
public enum AIVerbosity: String, Codable, CaseIterable {
    case concise        // 简洁
    case balanced       // 平衡
    case detailed       // 详细
    
    public var localizedValue: String {
        Localization.tr("ai_verbosity_\(rawValue)")
    }
}

// MARK: - AI Personality

/// AI personality style
public enum AIPersonality: String, Codable, CaseIterable {
    case supportive     // 支持型
    case challenging    // 挑战型
    case neutral        // 中立型
    
    public var localizedValue: String {
        Localization.tr("ai_personality_\(rawValue)")
    }
}

// MARK: - AI Response Preference

/// AI response preferences
public struct AIResponsePreference: Codable {
    public var preferredLength: AIResponseLength? // short | medium | long
    public var includeExamples: Bool?             // Whether to include examples
    public var includeEmoji: Bool?                // Whether to use emoji
    public var structuredFormat: Bool?            // Whether to use structured format (lists, headers, etc.)
    
    public init(
        preferredLength: AIResponseLength? = nil,
        includeExamples: Bool? = nil,
        includeEmoji: Bool? = nil,
        structuredFormat: Bool? = nil
    ) {
        self.preferredLength = preferredLength
        self.includeExamples = includeExamples
        self.includeEmoji = includeEmoji
        self.structuredFormat = structuredFormat
    }
}

// MARK: - AI Response Length

/// AI response length preference
public enum AIResponseLength: String, Codable, CaseIterable {
    case short          // 简短
    case medium         // 中等
    case long           // 详尽
    
    public var localizedValue: String {
        Localization.tr("ai_response_length_\(rawValue)")
    }
}

// MARK: - AI Topic Preference

/// AI topic preferences
public struct AITopicPreference: Codable {
    public var favorites: [String]                // Topics user likes to discuss
    public var avoid: [String]                    // Topics to avoid
    public var expertise: [String]                // User's expertise areas (AI can discuss more deeply)
    
    public init(
        favorites: [String] = [],
        avoid: [String] = [],
        expertise: [String] = []
    ) {
        self.favorites = favorites
        self.avoid = avoid
        self.expertise = expertise
    }
}

// MARK: - Helper Extensions

extension AIPreferences {
    /// Check if any preferences are set
    public var hasAnyPreference: Bool {
        style.tone != nil ||
        style.verbosity != nil ||
        style.personality != nil ||
        response.preferredLength != nil ||
        !topics.favorites.isEmpty ||
        !topics.avoid.isEmpty
    }
    
    /// Generate system prompt snippet based on preferences
    public func generatePromptSnippet() -> String? {
        var parts: [String] = []
        
        if let tone = style.tone {
            parts.append("Use a \(tone.rawValue) tone")
        }
        
        if let verbosity = style.verbosity {
            parts.append("Be \(verbosity.rawValue) in responses")
        }
        
        if let personality = style.personality {
            parts.append("Adopt a \(personality.rawValue) personality")
        }
        
        if let length = response.preferredLength {
            parts.append("Keep responses \(length.rawValue)")
        }
        
        if response.includeEmoji == true {
            parts.append("Feel free to use emoji")
        } else if response.includeEmoji == false {
            parts.append("Avoid using emoji")
        }
        
        if !topics.favorites.isEmpty {
            parts.append("User enjoys discussing: \(topics.favorites.joined(separator: ", "))")
        }
        
        if !topics.avoid.isEmpty {
            parts.append("Avoid topics: \(topics.avoid.joined(separator: ", "))")
        }
        
        if !topics.expertise.isEmpty {
            parts.append("User has expertise in: \(topics.expertise.joined(separator: ", "))")
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: ". ") + "."
    }
}
