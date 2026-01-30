import Foundation

// MARK: - Knowledge API Models
// Data models for AI knowledge extraction API interaction
// iOS only handles data export/import, server handles AI processing

// MARK: - Context Request (Server → iOS)

/// Context request item - what the server needs from iOS
public struct ContextRequestItem: Codable {
    public let type: ContextType
    public let id: String?                        // Only for relationship type
    public let reason: String?
    
    public init(type: ContextType, id: String? = nil, reason: String? = nil) {
        self.type = type
        self.id = id
        self.reason = reason
    }
}

/// Context type enumeration
public enum ContextType: String, Codable {
    case userProfile = "user_profile"
    case relationship = "relationship"
}

/// Full context request from server
public struct ContextRequest: Codable {
    public let summary: String?
    public let detectedPersons: [String]          // [REL_xxx:name] format
    public let requestedContexts: [ContextRequestItem]
    
    public init(
        summary: String? = nil,
        detectedPersons: [String] = [],
        requestedContexts: [ContextRequestItem] = []
    ) {
        self.summary = summary
        self.detectedPersons = detectedPersons
        self.requestedContexts = requestedContexts
    }
}

// MARK: - Sanitized Context (iOS → Server)

/// Sanitized context package - sent to server in round 2
public struct SanitizedContext: Codable {
    public let userProfile: SanitizedUserProfile?
    public let relationships: [SanitizedRelationship]
    
    public init(
        userProfile: SanitizedUserProfile? = nil,
        relationships: [SanitizedRelationship] = []
    ) {
        self.userProfile = userProfile
        self.relationships = relationships
    }
}

/// Sanitized user profile - no sensitive info
public struct SanitizedUserProfile: Codable {
    public let staticCore: SanitizedStaticCore
    public let knowledgeNodes: [KnowledgeNodeSummary]
    public let aiPreferences: AIPreferencesSummary?
    
    public init(
        staticCore: SanitizedStaticCore,
        knowledgeNodes: [KnowledgeNodeSummary] = [],
        aiPreferences: AIPreferencesSummary? = nil
    ) {
        self.staticCore = staticCore
        self.knowledgeNodes = knowledgeNodes
        self.aiPreferences = aiPreferences
    }
}

/// Sanitized static core - no hometown/currentCity
public struct SanitizedStaticCore: Codable {
    public let nickname: String?
    public let gender: String?
    public let birthYearMonth: String?            // Only year-month, no specific date
    public let occupation: String?
    public let industry: String?
    public let education: String?
    
    public init(
        nickname: String? = nil,
        gender: String? = nil,
        birthYearMonth: String? = nil,
        occupation: String? = nil,
        industry: String? = nil,
        education: String? = nil
    ) {
        self.nickname = nickname
        self.gender = gender
        self.birthYearMonth = birthYearMonth
        self.occupation = occupation
        self.industry = industry
        self.education = education
    }
}

/// Knowledge node summary - only essential info
public struct KnowledgeNodeSummary: Codable {
    public let id: String
    public let nodeType: String
    public let name: String
    public let description: String?
    public let confidence: Double?
    public let tags: [String]
    
    public init(
        id: String,
        nodeType: String,
        name: String,
        description: String? = nil,
        confidence: Double? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.nodeType = nodeType
        self.name = name
        self.description = description
        self.confidence = confidence
        self.tags = tags
    }
}

/// AI preferences summary
public struct AIPreferencesSummary: Codable {
    public let preferredStyle: String?
    public let topics: [String]
    
    public init(preferredStyle: String? = nil, topics: [String] = []) {
        self.preferredStyle = preferredStyle
        self.topics = topics
    }
}

/// Sanitized relationship - no realName
public struct SanitizedRelationship: Codable {
    public let id: String
    public let ref: String                        // [REL_xxx:displayName]
    public let type: String                       // CompanionType
    public let displayName: String
    public let aliases: [String]
    public let narrative: String?                 // Sanitized description
    public let tags: [String]
    public let attributes: [KnowledgeNodeSummary]
    public let factAnchors: SanitizedFactAnchors?
    
    public init(
        id: String,
        ref: String,
        type: String,
        displayName: String,
        aliases: [String] = [],
        narrative: String? = nil,
        tags: [String] = [],
        attributes: [KnowledgeNodeSummary] = [],
        factAnchors: SanitizedFactAnchors? = nil
    ) {
        self.id = id
        self.ref = ref
        self.type = type
        self.displayName = displayName
        self.aliases = aliases
        self.narrative = narrative
        self.tags = tags
        self.attributes = attributes
        self.factAnchors = factAnchors
    }
}

/// Sanitized fact anchors
public struct SanitizedFactAnchors: Codable {
    public let firstMeetingDate: String?
    public let sharedExperiences: [String]
    
    public init(firstMeetingDate: String? = nil, sharedExperiences: [String] = []) {
        self.firstMeetingDate = firstMeetingDate
        self.sharedExperiences = sharedExperiences
    }
}

// MARK: - Extracted Results (Server → iOS)

/// Extracted result from server - flexible L4 data
public struct ExtractedResult: Codable {
    public let type: ExtractedResultType
    public let target: String                     // "user" or "[REL_xxx:name]"
    public let data: ExtractedData
    
    public init(type: ExtractedResultType, target: String, data: ExtractedData) {
        self.type = type
        self.target = target
        self.data = data
    }
}

/// Extracted result type
public enum ExtractedResultType: String, Codable {
    case knowledgeNode = "knowledge_node"
    case relationshipAttribute = "relationship_attribute"
    case profileInsight = "profile_insight"
    case custom = "custom"
}

/// Extracted data - flexible structure for different result types
public struct ExtractedData: Codable {
    // For knowledge_node type
    public let nodeType: String?
    public let name: String?
    public let description: String?
    public let confidence: Double?
    public let tags: [String]?
    public let attributes: [String: String]?      // Simplified attributes
    
    // For profile_insight type
    public let insight: String?
    public let category: String?
    
    // For custom type
    public let customData: [String: String]?
    
    // Source links
    public let sourceLinks: [ExtractedSourceLink]?
    
    public init(
        nodeType: String? = nil,
        name: String? = nil,
        description: String? = nil,
        confidence: Double? = nil,
        tags: [String]? = nil,
        attributes: [String: String]? = nil,
        insight: String? = nil,
        category: String? = nil,
        customData: [String: String]? = nil,
        sourceLinks: [ExtractedSourceLink]? = nil
    ) {
        self.nodeType = nodeType
        self.name = name
        self.description = description
        self.confidence = confidence
        self.tags = tags
        self.attributes = attributes
        self.insight = insight
        self.category = category
        self.customData = customData
        self.sourceLinks = sourceLinks
    }
}

/// Extracted source link - simplified version
public struct ExtractedSourceLink: Codable {
    public let sourceType: String
    public let sourceId: String
    public let dayId: String
    public let snippet: String?
    
    public init(sourceType: String, sourceId: String, dayId: String, snippet: String? = nil) {
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.dayId = dayId
        self.snippet = snippet
    }
}

// MARK: - Full Response Wrapper

/// Full extraction response from server
public struct ExtractionResponse: Codable {
    public let success: Bool
    public let dayId: String
    public let results: [ExtractedResult]?
    public let error: APIErrorInfo?
    
    public init(success: Bool, dayId: String, results: [ExtractedResult]? = nil, error: APIErrorInfo? = nil) {
        self.success = success
        self.dayId = dayId
        self.results = results
        self.error = error
    }
}

/// API error info
public struct APIErrorInfo: Codable {
    public let code: String
    public let message: String
    
    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}


// MARK: - Knowledge API Error

/// Knowledge API error types
public enum KnowledgeAPIError: Error, LocalizedError {
    case dataPreparationFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    case invalidContextRequest(String)
    case profileNotFound
    case relationshipNotFound(String)
    case importFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .dataPreparationFailed(let desc):
            return "数据准备失败: \(desc)"
        case .encodingFailed(let desc):
            return "编码失败: \(desc)"
        case .decodingFailed(let desc):
            return "解码失败: \(desc)"
        case .invalidContextRequest(let desc):
            return "无效的上下文请求: \(desc)"
        case .profileNotFound:
            return "用户画像不存在"
        case .relationshipNotFound(let id):
            return "关系不存在: \(id)"
        case .importFailed(let desc):
            return "导入失败: \(desc)"
        }
    }
}
