import Foundation

// MARK: - L4 Layer: Knowledge Node (知识节点)
// Universal structure for storing user profile and relationship attributes
// Designed for extensibility without code changes

/// Universal knowledge node - core data structure for L4 layer
/// Used to store various dimensions of user profile and relationship profile
public struct KnowledgeNode: Codable, Identifiable {
    // ===== Unique Identifier =====
    public let id: String
    
    // ===== Node Type =====
    public let nodeType: String                   // Dimension type (extensible string, e.g., "skill", "value", "goal")
    public let nodeCategory: NodeCategory         // common (system predefined) | personal (user/AI created)
    
    // ===== Core Content =====
    public var name: String                       // Node name (e.g., "Swift Programming", "Family First")
    public var description: String?               // Description (optional)
    public var tags: [String]                     // User-defined tags
    
    // ===== Dynamic Attributes (Key-Value) =====
    public var attributes: [String: AttributeValue]
    
    // ===== Tracking Information =====
    public var tracking: NodeTracking
    
    // ===== Relations =====
    public var relations: [NodeRelation]
    
    // ===== Timestamps =====
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        nodeType: String,
        nodeCategory: NodeCategory = .common,
        name: String,
        description: String? = nil,
        tags: [String] = [],
        attributes: [String: AttributeValue] = [:],
        tracking: NodeTracking = NodeTracking(),
        relations: [NodeRelation] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nodeType = nodeType
        self.nodeCategory = nodeCategory
        self.name = name
        self.description = description
        self.tags = tags
        self.attributes = attributes
        self.tracking = tracking
        self.relations = relations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Node Category

/// Node classification
public enum NodeCategory: String, Codable {
    case common     // Common dimension: system predefined, all users may have
    case personal   // Personal unique: user or AI created unique dimension
}

// MARK: - Attribute Value

/// Attribute value - supports multiple data types
public enum AttributeValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([String])
    case date(Date)
    
    // MARK: - Convenience Accessors
    
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    public var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
    
    public var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }
    
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    public var arrayValue: [String]? {
        if case .array(let value) = self { return value }
        return nil
    }
    
    public var dateValue: Date? {
        if case .date(let value) = self { return value }
        return nil
    }
    
    // MARK: - Display Value
    
    public var displayValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(format: "%.2f", value)
        case .bool(let value): return value ? "Yes" : "No"
        case .array(let value): return value.joined(separator: ", ")
        case .date(let value):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: value)
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "int":
            let value = try container.decode(Int.self, forKey: .value)
            self = .int(value)
        case "double":
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case "bool":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .bool(value)
        case "array":
            let value = try container.decode([String].self, forKey: .value)
            self = .array(value)
        case "date":
            let value = try container.decode(Date.self, forKey: .value)
            self = .date(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode("int", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        case .array(let value):
            try container.encode("array", forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode("date", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Node Tracking

/// Node tracking information - records source, confidence, change history
public struct NodeTracking: Codable {
    // ===== Source Information =====
    public var source: NodeSource
    
    // ===== Timeline =====
    public var timeline: NodeTimeline
    
    // ===== Verification Status =====
    public var verification: NodeVerification
    
    // ===== Change History =====
    public var changeHistory: [NodeChange]
    
    public init(
        source: NodeSource = NodeSource(),
        timeline: NodeTimeline = NodeTimeline(),
        verification: NodeVerification = NodeVerification(),
        changeHistory: [NodeChange] = []
    ) {
        self.source = source
        self.timeline = timeline
        self.verification = verification
        self.changeHistory = changeHistory
    }
}

// MARK: - Node Source

/// Node source information
public struct NodeSource: Codable {
    public var type: SourceType
    public var confidence: Double?                // 0.0 ~ 1.0 (only for AI sources)
    public var extractedFrom: [SourceLink]        // Source link list
    
    public init(
        type: SourceType = .userInput,
        confidence: Double? = nil,
        extractedFrom: [SourceLink] = []
    ) {
        self.type = type
        self.confidence = confidence
        self.extractedFrom = extractedFrom
    }
}

// MARK: - Source Type

/// Source type enumeration
public enum SourceType: String, Codable {
    case userInput      // User manual input
    case aiExtracted    // AI extracted from raw data
    case aiInferred     // AI inferred
}

// MARK: - Node Timeline

/// Node timeline information
public struct NodeTimeline: Codable {
    public var firstDiscovered: Date              // First discovered/created
    public var lastUpdated: Date                  // Last updated
    public var lastConfirmed: Date?               // User last confirmed time
    
    public init(
        firstDiscovered: Date = Date(),
        lastUpdated: Date = Date(),
        lastConfirmed: Date? = nil
    ) {
        self.firstDiscovered = firstDiscovered
        self.lastUpdated = lastUpdated
        self.lastConfirmed = lastConfirmed
    }
}

// MARK: - Node Verification

/// Node verification status
public struct NodeVerification: Codable {
    public var confirmedByUser: Bool              // Whether user has confirmed
    public var needsReview: Bool                  // Whether needs user review
    
    public init(
        confirmedByUser: Bool = false,
        needsReview: Bool = false
    ) {
        self.confirmedByUser = confirmedByUser
        self.needsReview = needsReview
    }
}

// MARK: - Source Link

/// Source link - connects L4 knowledge node with L1 raw data
public struct SourceLink: Codable, Identifiable {
    public let id: String
    public var sourceType: String                 // diary | conversation | tracker | mindState
    public var sourceId: String                   // Specific record ID (JournalEntry.id, AIMessage.id, etc.)
    public var dayId: String                      // Belonging date (YYYY-MM-DD)
    public var snippet: String?                   // Related text snippet (for display)
    public var relevanceScore: Double?            // Relevance score 0.0 ~ 1.0
    public var extractedAt: Date                  // Extraction time
    
    public init(
        id: String = UUID().uuidString,
        sourceType: String,
        sourceId: String,
        dayId: String,
        snippet: String? = nil,
        relevanceScore: Double? = nil,
        extractedAt: Date = Date()
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.dayId = dayId
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.extractedAt = extractedAt
    }
}

// MARK: - Node Change

/// Node change record - tracks modification history
public struct NodeChange: Codable, Identifiable {
    public let id: String
    public var timestamp: Date
    public var changeType: NodeChangeType         // created | updated | confirmed | deleted
    public var field: String?                     // Changed field name (e.g., "name", "attributes.proficiency")
    public var oldValue: AttributeValue?          // Old value
    public var newValue: AttributeValue?          // New value
    public var reason: NodeChangeReason           // Change reason
    public var confidence: Double?                // Confidence after change
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        changeType: NodeChangeType,
        field: String? = nil,
        oldValue: AttributeValue? = nil,
        newValue: AttributeValue? = nil,
        reason: NodeChangeReason = .userEdit,
        confidence: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.changeType = changeType
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.reason = reason
        self.confidence = confidence
    }
}

// MARK: - Node Change Type

/// Node change type enumeration
public enum NodeChangeType: String, Codable {
    case created        // Created
    case updated        // Updated
    case confirmed      // User confirmed
    case deleted        // Deleted
}

// MARK: - Node Change Reason

/// Node change reason enumeration
public enum NodeChangeReason: String, Codable {
    case userEdit       // User manual edit
    case aiUpdate       // AI automatic update
    case correction     // Error correction
    case decay          // Confidence decay
    case enhancement    // Confidence enhancement (multiple mentions)
}

// MARK: - Node Relation

/// Node relation - describes relationships between nodes
public struct NodeRelation: Codable, Identifiable {
    public let id: String
    public var targetNodeId: String               // Related target node ID
    public var relationType: RelationType         // Relation type
    public var strength: Double?                  // Relation strength 0.0 ~ 1.0
    public var description: String?               // Relation description
    
    public init(
        id: String = UUID().uuidString,
        targetNodeId: String,
        relationType: RelationType,
        strength: Double? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.targetNodeId = targetNodeId
        self.relationType = relationType
        self.strength = strength
        self.description = description
    }
}

// MARK: - Relation Type

/// Relation type enumeration
public enum RelationType: String, Codable {
    case requires       // Dependency (e.g., Skill A requires Skill B)
    case conflictsWith  // Conflict (e.g., Value A conflicts with Value B)
    case supports       // Support (e.g., Goal A supports Value B)
    case relatedTo      // General relation
    case partOf         // Belonging (e.g., Sub-goal belongs to Main goal)
}


// MARK: - KnowledgeNode Extensions

extension KnowledgeNode {
    
    // MARK: - Common Node Types (User Profile)
    
    public static let userProfileNodeTypes: [String] = [
        "skill",        // 技能
        "value",        // 价值观
        "hobby",        // 兴趣爱好
        "goal",         // 目标
        "trait",        // 性格特质
        "fear",         // 恐惧担忧
        "fact",         // 核心事实
        "lifestyle",    // 生活方式
        "belief",       // 信念
        "preference"    // 偏好
    ]
    
    // MARK: - Common Node Types (Relationship)
    
    public static let relationshipNodeTypes: [String] = [
        "relationship_status",    // 关系状态
        "interaction_pattern",    // 互动模式
        "emotional_connection",   // 情感连接
        "shared_memory",          // 共同记忆
        "health_status",          // 健康状态
        "life_event"              // 人生事件
    ]
    
    // MARK: - Confidence Helpers
    
    /// Current confidence value (1.0 for user input, calculated for AI sources)
    public var currentConfidence: Double {
        tracking.source.confidence ?? 1.0
    }
    
    /// Check if this node needs user review
    public var needsReview: Bool {
        tracking.verification.needsReview
    }
    
    /// Check if this node is confirmed by user
    public var isConfirmed: Bool {
        tracking.verification.confirmedByUser
    }
    
    /// Check if this node is from AI
    public var isFromAI: Bool {
        tracking.source.type != .userInput
    }
    
    // MARK: - Confidence Decay Calculation
    
    /// Calculate decayed confidence based on days since last update
    /// - Decay cycle: 180 days
    /// - Max decay: 30%
    /// - User confirmed resets to 1.0
    public func calculateDecayedConfidence() -> Double {
        // User input doesn't decay
        guard tracking.source.type != .userInput else { return 1.0 }
        
        // User confirmed doesn't decay
        guard !tracking.verification.confirmedByUser else { return 1.0 }
        
        let originalConfidence = tracking.source.confidence ?? 0.8
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: tracking.timeline.lastUpdated, to: Date()).day ?? 0
        
        // Decay formula: original * (1 - days/180 * 0.3)
        let decayFactor = 1.0 - (Double(daysSinceUpdate) / 180.0 * 0.3)
        let decayed = originalConfidence * max(decayFactor, 0.7)  // Keep at least 70%
        
        return max(decayed, 0.1)  // Absolute minimum 0.1
    }
    
    // MARK: - Factory Methods
    
    /// Create a user-input node (confidence = 1.0)
    public static func createUserInput(
        nodeType: String,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:]
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            nodeCategory: .common,
            name: name,
            description: description,
            attributes: attributes,
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                verification: NodeVerification(confirmedByUser: true)
            )
        )
    }
    
    /// Create an AI-extracted node
    public static func createAIExtracted(
        nodeType: String,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:],
        confidence: Double,
        sourceLinks: [SourceLink] = []
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            nodeCategory: .common,
            name: name,
            description: description,
            attributes: attributes,
            tracking: NodeTracking(
                source: NodeSource(type: .aiExtracted, confidence: confidence, extractedFrom: sourceLinks),
                verification: NodeVerification(needsReview: confidence < 0.8)
            )
        )
    }
    
    /// Create a personal (custom) node
    public static func createPersonal(
        nodeType: String,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:]
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            nodeCategory: .personal,
            name: name,
            description: description,
            attributes: attributes,
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                verification: NodeVerification(confirmedByUser: true)
            )
        )
    }
    
    // MARK: - Mutation Helpers
    
    /// Confirm this node (sets confidence to 1.0)
    public mutating func confirm() {
        tracking.verification.confirmedByUser = true
        tracking.verification.needsReview = false
        tracking.timeline.lastConfirmed = Date()
        tracking.timeline.lastUpdated = Date()
        updatedAt = Date()
        
        // Add change record
        tracking.changeHistory.append(NodeChange(
            changeType: NodeChangeType.confirmed,
            reason: NodeChangeReason.userEdit,
            confidence: 1.0
        ))
    }
    
    /// Update an attribute value
    public mutating func updateAttribute(key: String, value: AttributeValue, reason: NodeChangeReason = .userEdit) {
        let oldValue = attributes[key]
        attributes[key] = value
        tracking.timeline.lastUpdated = Date()
        updatedAt = Date()
        
        // Add change record
        tracking.changeHistory.append(NodeChange(
            changeType: NodeChangeType.updated,
            field: "attributes.\(key)",
            oldValue: oldValue,
            newValue: value,
            reason: reason
        ))
    }
}

// MARK: - NarrativeUserProfile Extensions

extension NarrativeUserProfile {
    
    /// Get nodes by type
    public func nodes(ofType nodeType: String) -> [KnowledgeNode] {
        knowledgeNodes.filter { $0.nodeType == nodeType }
    }
    
    /// Get all skills
    public var skills: [KnowledgeNode] {
        nodes(ofType: "skill")
    }
    
    /// Get all values
    public var values: [KnowledgeNode] {
        nodes(ofType: "value")
    }
    
    /// Get all goals
    public var goals: [KnowledgeNode] {
        nodes(ofType: "goal")
    }
    
    /// Get all hobbies
    public var hobbies: [KnowledgeNode] {
        nodes(ofType: "hobby")
    }
    
    /// Get all traits
    public var traits: [KnowledgeNode] {
        nodes(ofType: "trait")
    }
    
    /// Get nodes that need review
    public var nodesNeedingReview: [KnowledgeNode] {
        knowledgeNodes.filter { $0.needsReview }
    }
    
    /// Get nodes from AI (not yet confirmed)
    public var unconfirmedAINodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.isFromAI && !$0.isConfirmed }
    }
}

// MARK: - NarrativeRelationship Extensions

extension NarrativeRelationship {
    
    /// Get attribute nodes by type
    public func attributeNodes(ofType nodeType: String) -> [KnowledgeNode] {
        attributes.filter { $0.nodeType == nodeType }
    }
    
    /// Get relationship status node
    public var relationshipStatus: KnowledgeNode? {
        attributes.first { $0.nodeType == "relationship_status" }
    }
    
    /// Get interaction pattern node
    public var interactionPattern: KnowledgeNode? {
        attributes.first { $0.nodeType == "interaction_pattern" }
    }
    
    /// Get health status nodes (for family members)
    public var healthStatuses: [KnowledgeNode] {
        attributeNodes(ofType: "health_status")
    }
    
    /// Get shared memories
    public var sharedMemories: [KnowledgeNode] {
        attributeNodes(ofType: "shared_memory")
    }
    
    /// Get life events
    public var lifeEvents: [KnowledgeNode] {
        attributeNodes(ofType: "life_event")
    }
    
    /// Get attribute nodes that need review
    public var attributesNeedingReview: [KnowledgeNode] {
        attributes.filter { $0.needsReview }
    }
}

// MARK: - Validation

public struct KnowledgeNodeValidator {
    
    public enum ValidationResult {
        case valid
        case invalid([String])
    }
    
    /// Validate node structure
    public static func validate(_ node: KnowledgeNode) -> ValidationResult {
        var errors: [String] = []
        
        // 1. id must exist and not empty
        if node.id.isEmpty {
            errors.append("id cannot be empty")
        }
        
        // 2. nodeType must be non-empty string
        if node.nodeType.isEmpty {
            errors.append("nodeType cannot be empty")
        }
        
        // 3. name must be non-empty string
        if node.name.isEmpty {
            errors.append("name cannot be empty")
        }
        
        // 4. confidence must be in 0.0 ~ 1.0 range if exists
        if let confidence = node.tracking.source.confidence {
            if confidence < 0.0 || confidence > 1.0 {
                errors.append("confidence must be between 0.0 and 1.0")
            }
        }
        
        // 5. timestamps must be valid
        if node.createdAt > node.updatedAt {
            errors.append("createdAt cannot be later than updatedAt")
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}
