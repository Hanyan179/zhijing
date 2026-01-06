import Foundation

// MARK: - L4 Layer: Knowledge Node (知识节点)
// Universal structure for storing user profile and relationship attributes
// Designed for extensibility without code changes

/// Universal knowledge node - core data structure for L4 layer
///
/// Used to store various dimensions of user profile and relationship profile.
/// Supports the three-layer dimension architecture (Life OS):
/// - Level 1: 7 primary dimensions (self, material, achievements, experiences, spirit, relationships, ai_preferences)
/// - Level 2: 15 secondary dimensions (identity, physical, personality, etc.)
/// - Level 3: Dynamic sub-dimensions maintained by AI
///
/// ## Key Fields (Phase 2-4 Refactoring)
///
/// ### Source Links (`sourceLinks`)
/// Moved from `tracking.source.extractedFrom` to node level for:
/// - More intuitive data access
/// - Clearer multi-to-many relationship support
/// - Simplified tracking structure
///
/// ### Content Type (`contentType`)
/// Supports different content structures:
/// - `.aiTag`: AI-generated tags (name + description + sourceLinks)
/// - `.subsystem`: Structured data with fixed schema
/// - `.entityRef`: References to relationship entities
/// - `.nestedList`: Container nodes with child nodes
///
/// ### Related Entities (`relatedEntityIds`)
/// Links to relationship entities (NarrativeRelationship) for cross-referencing.
///
/// ### Nested Structure (`childNodeIds`, `parentNodeId`)
/// Supports hierarchical organization of knowledge nodes.
///
/// ## Migration Guide
///
/// ### Accessing Source Links
/// ```swift
/// // Old format (deprecated):
/// let links = node.tracking.source.extractedFrom
///
/// // New format:
/// let links = node.sourceLinks
/// ```
///
/// ### Using Dimension Path
/// ```swift
/// // Parse nodeType path
/// if let path = node.typePath {
///     print("Level 1: \(path.level1)")
///     print("Level 2: \(path.level2 ?? "none")")
/// }
///
/// // Check dimension
/// if node.matchesLevel1(.achievements) {
///     // Handle achievements dimension
/// }
/// ```
///
/// - SeeAlso: `NodeTypePath` for path parsing utilities
/// - SeeAlso: `DimensionHierarchy` for dimension definitions
/// - SeeAlso: `NodeContentType` for content type definitions
public struct KnowledgeNode: Identifiable {
    // ===== Unique Identifier =====
    public let id: String
    
    // ===== Node Type =====
    public let nodeType: String                   // Dimension type (hierarchical path, e.g., "self.personality.trait")
    public let contentType: NodeContentType       // 🆕 Content type (ai_tag, subsystem, entity_ref, nested_list)
    public let nodeCategory: NodeCategory         // common (system predefined) | personal (user/AI created)
    
    // ===== Core Content =====
    public var name: String                       // Node name (e.g., "Swift Programming", "Family First")
    public var description: String?               // Description (optional)
    public var tags: [String]                     // User-defined tags
    
    // ===== Dynamic Attributes (Key-Value) =====
    public var attributes: [String: AttributeValue]
    
    // ===== 🆕 Source Links (moved from tracking.source) =====
    /// Source links for traceability - connects L4 knowledge node with L1 raw data.
    ///
    /// This field was moved from `tracking.source.extractedFrom` in Phase 2 refactoring.
    /// The decoder automatically migrates old data from `tracking.source.extractedFrom`.
    ///
    /// - Note: For new code, always use this field instead of `tracking.source.extractedFrom`.
    public var sourceLinks: [SourceLink]
    
    // ===== 🆕 Related Entities =====
    /// Related entity IDs (for entity references).
    ///
    /// Links to `NarrativeRelationship` entities. Format: relationship ID strings.
    /// Used when `contentType` is `.entityRef` or when the node references people.
    public var relatedEntityIds: [String]
    
    // ===== 🆕 Nested Structure Support =====
    /// Child node IDs (for nested_list type).
    ///
    /// Only used when `contentType` is `.nestedList`.
    /// Child nodes should have their `parentNodeId` set to this node's ID.
    public var childNodeIds: [String]?
    
    /// Parent node ID.
    ///
    /// Set when this node is a child of another node with `contentType` = `.nestedList`.
    public var parentNodeId: String?
    
    // ===== Tracking Information =====
    public var tracking: NodeTracking
    
    // ===== Relations =====
    public var relations: [NodeRelation]
    
    // ===== Timestamps =====
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: String = UUID().uuidString,
        nodeType: String,
        contentType: NodeContentType = .aiTag,    // 🆕 Default to aiTag
        nodeCategory: NodeCategory = .common,
        name: String,
        description: String? = nil,
        tags: [String] = [],
        attributes: [String: AttributeValue] = [:],
        sourceLinks: [SourceLink] = [],           // 🆕 Default empty array
        relatedEntityIds: [String] = [],          // 🆕 Default empty array
        childNodeIds: [String]? = nil,            // 🆕 Default nil
        parentNodeId: String? = nil,              // 🆕 Default nil
        tracking: NodeTracking = NodeTracking(),
        relations: [NodeRelation] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nodeType = nodeType
        self.contentType = contentType
        self.nodeCategory = nodeCategory
        self.name = name
        self.description = description
        self.tags = tags
        self.attributes = attributes
        self.sourceLinks = sourceLinks
        self.relatedEntityIds = relatedEntityIds
        self.childNodeIds = childNodeIds
        self.parentNodeId = parentNodeId
        self.tracking = tracking
        self.relations = relations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - KnowledgeNode Codable (Backward Compatible)

extension KnowledgeNode: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case nodeType
        case contentType
        case nodeCategory
        case name
        case description
        case tags
        case attributes
        case sourceLinks
        case relatedEntityIds
        case childNodeIds
        case parentNodeId
        case tracking
        case relations
        case createdAt
        case updatedAt
    }
    
    /// Custom decoder for backward compatibility
    /// - New fields use default values when missing from old data
    /// - Automatically migrates tracking.source.extractedFrom to sourceLinks
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode existing fields
        id = try container.decode(String.self, forKey: .id)
        nodeType = try container.decode(String.self, forKey: .nodeType)
        nodeCategory = try container.decode(NodeCategory.self, forKey: .nodeCategory)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        attributes = try container.decodeIfPresent([String: AttributeValue].self, forKey: .attributes) ?? [:]
        tracking = try container.decodeIfPresent(NodeTracking.self, forKey: .tracking) ?? NodeTracking()
        relations = try container.decodeIfPresent([NodeRelation].self, forKey: .relations) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // 🆕 Decode new fields with default values for backward compatibility
        contentType = try container.decodeIfPresent(NodeContentType.self, forKey: .contentType) ?? .aiTag
        relatedEntityIds = try container.decodeIfPresent([String].self, forKey: .relatedEntityIds) ?? []
        childNodeIds = try container.decodeIfPresent([String].self, forKey: .childNodeIds)
        parentNodeId = try container.decodeIfPresent(String.self, forKey: .parentNodeId)
        
        // 🆕 Decode sourceLinks with migration from tracking.source.extractedFrom
        var decodedSourceLinks = try container.decodeIfPresent([SourceLink].self, forKey: .sourceLinks) ?? []
        
        // Auto-migrate: if sourceLinks is empty but tracking.source.extractedFrom has data, use that
        // Use withoutActuallyEscaping pattern to access deprecated field without triggering warning
        if decodedSourceLinks.isEmpty {
            let legacySourceLinks = tracking.source.legacyExtractedFrom
            if !legacySourceLinks.isEmpty {
                decodedSourceLinks = legacySourceLinks
            }
        }
        sourceLinks = decodedSourceLinks
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encode(id, forKey: .id)
        try container.encode(nodeType, forKey: .nodeType)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(nodeCategory, forKey: .nodeCategory)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(sourceLinks, forKey: .sourceLinks)
        try container.encode(relatedEntityIds, forKey: .relatedEntityIds)
        try container.encodeIfPresent(childNodeIds, forKey: .childNodeIds)
        try container.encodeIfPresent(parentNodeId, forKey: .parentNodeId)
        try container.encode(tracking, forKey: .tracking)
        try container.encode(relations, forKey: .relations)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
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
///
/// ## Migration Note (Phase 5)
/// The `extractedFrom` field has been deprecated and moved to `KnowledgeNode.sourceLinks`.
/// This change supports:
/// - More intuitive data access path
/// - Clearer multi-to-many relationship support
/// - Simplified `NodeSource` structure
///
/// During the transition period:
/// - Reading: The system automatically migrates `extractedFrom` to `KnowledgeNode.sourceLinks`
/// - Writing: New code should use `KnowledgeNode.sourceLinks` directly
///
/// See: `KnowledgeNode.init(from decoder:)` for automatic migration logic
public struct NodeSource: Codable {
    public var type: SourceType
    public var confidence: Double?                // 0.0 ~ 1.0 (only for AI sources)
    
    /// Source link list (internal storage)
    ///
    /// - Important: **DEPRECATED** - Use `KnowledgeNode.sourceLinks` instead.
    ///   This field is kept for backward compatibility during migration.
    ///   The decoder in `KnowledgeNode` automatically migrates this data to node-level `sourceLinks`.
    ///
    /// ## Migration Guide
    /// Before (old format):
    /// ```swift
    /// let links = node.tracking.source.extractedFrom
    /// ```
    ///
    /// After (new format):
    /// ```swift
    /// let links = node.sourceLinks
    /// ```
    @available(*, deprecated, message: "Use KnowledgeNode.sourceLinks instead. This field is kept for backward compatibility during migration.")
    public var extractedFrom: [SourceLink] {
        get { _extractedFrom }
        set { _extractedFrom = newValue }
    }
    
    /// Internal storage for extractedFrom - allows access without deprecation warning for migration code
    internal var _extractedFrom: [SourceLink]
    
    /// Internal accessor for migration code - provides access without deprecation warning
    /// Only use this in decoder migration logic
    internal var legacyExtractedFrom: [SourceLink] {
        _extractedFrom
    }
    
    public init(
        type: SourceType = .userInput,
        confidence: Double? = nil,
        extractedFrom: [SourceLink] = []
    ) {
        self.type = type
        self.confidence = confidence
        self._extractedFrom = extractedFrom
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case type
        case confidence
        case extractedFrom
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(SourceType.self, forKey: .type)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        _extractedFrom = try container.decodeIfPresent([SourceLink].self, forKey: .extractedFrom) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(_extractedFrom, forKey: .extractedFrom)
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

/// Source link - connects L4 knowledge node with L1 raw data.
///
/// Provides traceability from knowledge nodes back to their original sources
/// (diary entries, conversations, trackers, mind states).
///
/// ## Key Fields (Phase 3 Refactoring)
///
/// ### Related Entity IDs (`relatedEntityIds`)
/// Added in Phase 3 to support multi-to-many relationships.
/// Records which relationship entities (people) are mentioned in this source record.
///
/// ## Usage Examples
///
/// ### Creating a Source Link
/// ```swift
/// let link = SourceLink(
///     sourceType: "diary",
///     sourceId: "entry_123",
///     dayId: "2024-12-31",
///     snippet: "Today I learned Swift...",
///     relevanceScore: 0.85,
///     relatedEntityIds: ["REL_friend_001"]  // People mentioned
/// )
/// ```
///
/// ### Accessing from KnowledgeNode
/// ```swift
/// // New format (recommended):
/// for link in node.sourceLinks {
///     print("Source: \(link.sourceType) on \(link.dayId)")
/// }
///
/// // Old format (deprecated):
/// // for link in node.tracking.source.extractedFrom { ... }
/// ```
///
/// ## Backward Compatibility
/// The `relatedEntityIds` field uses an empty array as default when decoding
/// old data that doesn't have this field.
///
/// - SeeAlso: `KnowledgeNode.sourceLinks` for the recommended access path
/// - SeeAlso: `NodeSource.extractedFrom` (deprecated) for migration information
public struct SourceLink: Identifiable {
    public let id: String
    public var sourceType: String                 // diary | conversation | tracker | mindState
    public var sourceId: String                   // Specific record ID (JournalEntry.id, AIMessage.id, etc.)
    public var dayId: String                      // Belonging date (YYYY-MM-DD)
    public var snippet: String?                   // Related text snippet (for display)
    public var relevanceScore: Double?            // Relevance score 0.0 ~ 1.0
    
    /// Related entity IDs mentioned in this record.
    ///
    /// Added in Phase 3 refactoring to support multi-to-many relationships.
    /// Contains IDs of `NarrativeRelationship` entities that are mentioned
    /// in the source record.
    ///
    /// - Note: Uses empty array as default for backward compatibility with old data.
    public var relatedEntityIds: [String]
    
    public var extractedAt: Date                  // Extraction time
    
    public init(
        id: String = UUID().uuidString,
        sourceType: String,
        sourceId: String,
        dayId: String,
        snippet: String? = nil,
        relevanceScore: Double? = nil,
        relatedEntityIds: [String] = [],          // 🆕 Default empty array
        extractedAt: Date = Date()
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.dayId = dayId
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.relatedEntityIds = relatedEntityIds
        self.extractedAt = extractedAt
    }
}

// MARK: - SourceLink Codable (Backward Compatible)

extension SourceLink: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case sourceType
        case sourceId
        case dayId
        case snippet
        case relevanceScore
        case relatedEntityIds
        case extractedAt
    }
    
    /// Custom decoder for backward compatibility
    /// - relatedEntityIds uses empty array when missing from old data
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode existing fields
        id = try container.decode(String.self, forKey: .id)
        sourceType = try container.decode(String.self, forKey: .sourceType)
        sourceId = try container.decode(String.self, forKey: .sourceId)
        dayId = try container.decode(String.self, forKey: .dayId)
        snippet = try container.decodeIfPresent(String.self, forKey: .snippet)
        relevanceScore = try container.decodeIfPresent(Double.self, forKey: .relevanceScore)
        extractedAt = try container.decode(Date.self, forKey: .extractedAt)
        
        // 🆕 Decode relatedEntityIds with default empty array for backward compatibility
        relatedEntityIds = try container.decodeIfPresent([String].self, forKey: .relatedEntityIds) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encode(id, forKey: .id)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(sourceId, forKey: .sourceId)
        try container.encode(dayId, forKey: .dayId)
        try container.encodeIfPresent(snippet, forKey: .snippet)
        try container.encodeIfPresent(relevanceScore, forKey: .relevanceScore)
        try container.encode(relatedEntityIds, forKey: .relatedEntityIds)
        try container.encode(extractedAt, forKey: .extractedAt)
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
    
    // MARK: - Source Data Computed Properties (L4 Source Info Redesign)
    
    /// 关联原始次数 - 统计该知识点关联的原始数据条数
    /// - Returns: sourceLinks 数组的元素数量
    /// - Note: 用于替代原有的"置信度"显示，更直观地展示数据支撑
    public var mentionCount: Int {
        sourceLinks.count
    }
    
    /// 来源类型分布 - 按数据表类型分组统计
    /// - Returns: 字典，key 为 sourceType (diary/conversation/tracker/mindState)，value 为该类型的条数
    /// - Note: 用于显示"日记 X 条、AI对话 X 条"等分布信息
    public var sourceTypeDistribution: [String: Int] {
        Dictionary(grouping: sourceLinks, by: { $0.sourceType })
            .mapValues { $0.count }
    }
    
    /// 是否有来源数据
    /// - Returns: 如果 sourceLinks 不为空则返回 true
    public var hasSourceData: Bool {
        !sourceLinks.isEmpty
    }
    
    // MARK: - Common Node Types (User Profile) - Legacy Format
    // 保留旧格式用于向后兼容和迁移
    
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
    
    // MARK: - Common Node Types (User Profile) - Hierarchical Format
    // 新的层级路径格式常量
    
    public static let userProfileNodeTypesHierarchical: [String] = [
        "achievements.competencies.professional_skills",  // skill
        "spirit.ideology.values",                         // value
        "experiences.culture_entertainment",              // hobby
        "spirit.ideology.visions_dreams",                 // goal
        "self.personality.self_assessment",               // trait
        "spirit.mental_state.stressors",                  // fear
        "experiences.history.milestones",                 // fact
        "self.physical.dietary_habits",                   // lifestyle
        "self.personality.behavioral_preferences"         // preference
    ]
    
    // MARK: - Common Node Types (Relationship) - Legacy Format
    // 保留旧格式用于向后兼容和迁移
    
    public static let relationshipNodeTypes: [String] = [
        "relationship_status",    // 关系状态
        "interaction_pattern",    // 互动模式
        "emotional_connection",   // 情感连接
        "shared_memory",          // 共同记忆
        "health_status",          // 健康状态
        "life_event"              // 人生事件
    ]
    
    // MARK: - Common Node Types (Relationship) - Hierarchical Format
    // 新的层级路径格式常量
    
    public static let relationshipNodeTypesHierarchical: [String] = [
        "relationships.status",       // relationship_status
        "relationships.interaction",  // interaction_pattern
        "relationships.emotional",    // emotional_connection
        "relationships.memories",     // shared_memory
        "relationships.health",       // health_status
        "relationships.events"        // life_event
    ]
    
    // MARK: - NodeTypePath Extension Methods
    
    /// 解析 nodeType 路径
    /// 返回 NodeTypePath 对象，用于访问 level1, level2, level3 组件
    public var typePath: NodeTypePath? {
        NodeTypePath(nodeType: nodeType)
    }
    
    /// 获取 Level 1 维度
    /// 如果 nodeType 是有效的层级路径格式，返回对应的 Level1 枚举值
    public var level1Dimension: DimensionHierarchy.Level1? {
        typePath?.level1Dimension
    }
    
    /// 检查是否为有效的维度路径
    /// 验证 nodeType 是否符合三层维度架构的格式要求
    public var hasValidDimensionPath: Bool {
        typePath?.isValid() ?? false
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 维度
    /// - Parameter level1: 要匹配的一级维度
    /// - Returns: 如果 nodeType 以该维度开头则返回 true
    public func matchesLevel1(_ level1: DimensionHierarchy.Level1) -> Bool {
        nodeType.hasPrefix(level1.rawValue + ".") || nodeType == level1.rawValue
    }
    
    /// 检查 nodeType 是否匹配指定的 Level 1 和 Level 2 维度
    /// - Parameters:
    ///   - level1: 要匹配的一级维度
    ///   - level2: 要匹配的二级维度标识
    /// - Returns: 如果 nodeType 以该维度路径开头则返回 true
    public func matchesLevel2(_ level1: DimensionHierarchy.Level1, _ level2: String) -> Bool {
        let prefix = "\(level1.rawValue).\(level2)"
        return nodeType.hasPrefix(prefix + ".") || nodeType == prefix
    }
    
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
    /// - Parameters:
    ///   - nodeType: 节点类型（支持层级路径格式，如 "achievements.competencies.professional_skills"）
    ///   - contentType: 内容类型，默认为 .aiTag
    ///   - name: 节点名称
    ///   - description: 节点描述
    ///   - attributes: 动态属性
    /// - Returns: 新创建的 KnowledgeNode
    public static func createUserInput(
        nodeType: String,
        contentType: NodeContentType = .aiTag,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:]
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            contentType: contentType,
            nodeCategory: .common,
            name: name,
            description: description,
            attributes: attributes,
            sourceLinks: [],
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                verification: NodeVerification(confirmedByUser: true)
            )
        )
    }
    
    /// Create an AI-extracted node
    /// - Parameters:
    ///   - nodeType: 节点类型（支持层级路径格式）
    ///   - contentType: 内容类型，默认为 .aiTag
    ///   - name: 节点名称
    ///   - description: 节点描述
    ///   - attributes: 动态属性
    ///   - confidence: AI 置信度 (0.0 ~ 1.0)
    ///   - sourceLinks: 溯源链接列表（存储在节点级别）
    /// - Returns: 新创建的 KnowledgeNode
    public static func createAIExtracted(
        nodeType: String,
        contentType: NodeContentType = .aiTag,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:],
        confidence: Double,
        sourceLinks: [SourceLink] = []
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            contentType: contentType,
            nodeCategory: .common,
            name: name,
            description: description,
            attributes: attributes,
            sourceLinks: sourceLinks,  // 🆕 使用节点级 sourceLinks
            tracking: NodeTracking(
                source: NodeSource(type: .aiExtracted, confidence: confidence),  // 不再传递 extractedFrom，使用节点级 sourceLinks
                verification: NodeVerification(needsReview: confidence < 0.8)
            )
        )
    }
    
    /// Create a personal (custom) node
    /// - Parameters:
    ///   - nodeType: 节点类型（支持层级路径格式）
    ///   - contentType: 内容类型，默认为 .aiTag
    ///   - name: 节点名称
    ///   - description: 节点描述
    ///   - attributes: 动态属性
    /// - Returns: 新创建的 KnowledgeNode
    public static func createPersonal(
        nodeType: String,
        contentType: NodeContentType = .aiTag,
        name: String,
        description: String? = nil,
        attributes: [String: AttributeValue] = [:]
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            contentType: contentType,
            nodeCategory: .personal,
            name: name,
            description: description,
            attributes: attributes,
            sourceLinks: [],
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
    
    /// Get nodes by type prefix (supports hierarchical path matching)
    /// - Parameter prefix: 类型前缀，如 "achievements.competencies"
    /// - Returns: 所有 nodeType 以该前缀开头的节点
    public func nodes(withTypePrefix prefix: String) -> [KnowledgeNode] {
        knowledgeNodes.filter { $0.nodeType.hasPrefix(prefix) }
    }
    
    /// Get all skills
    /// 支持旧格式 "skill" 和新格式 "achievements.competencies" 前缀
    public var skills: [KnowledgeNode] {
        knowledgeNodes.filter { 
            $0.nodeType == "skill" || 
            $0.nodeType.hasPrefix("achievements.competencies")
        }
    }
    
    /// Get all values
    /// 支持旧格式 "value"/"belief" 和新格式 "spirit.ideology.values" 前缀
    public var values: [KnowledgeNode] {
        knowledgeNodes.filter { 
            $0.nodeType == "value" || 
            $0.nodeType == "belief" ||
            $0.nodeType.hasPrefix("spirit.ideology.values")
        }
    }
    
    /// Get all goals
    /// 支持旧格式 "goal" 和新格式 "spirit.ideology.visions_dreams" 前缀
    public var goals: [KnowledgeNode] {
        knowledgeNodes.filter { 
            $0.nodeType == "goal" || 
            $0.nodeType.hasPrefix("spirit.ideology.visions_dreams")
        }
    }
    
    /// Get all hobbies
    /// 支持旧格式 "hobby" 和新格式 "experiences.culture_entertainment" 前缀
    public var hobbies: [KnowledgeNode] {
        knowledgeNodes.filter { 
            $0.nodeType == "hobby" || 
            $0.nodeType.hasPrefix("experiences.culture_entertainment")
        }
    }
    
    /// Get all traits
    /// 支持旧格式 "trait" 和新格式 "self.personality" 前缀
    public var traits: [KnowledgeNode] {
        knowledgeNodes.filter { 
            $0.nodeType == "trait" || 
            $0.nodeType.hasPrefix("self.personality")
        }
    }
    
    /// Get all fears/stressors
    /// 支持旧格式 "fear" 和新格式 "spirit.mental_state.stressors" 前缀
    public var fears: [KnowledgeNode] {
        knowledgeNodes.filter {
            $0.nodeType == "fear" ||
            $0.nodeType.hasPrefix("spirit.mental_state.stressors")
        }
    }
    
    /// Get all facts/milestones
    /// 支持旧格式 "fact" 和新格式 "experiences.history.milestones" 前缀
    public var facts: [KnowledgeNode] {
        knowledgeNodes.filter {
            $0.nodeType == "fact" ||
            $0.nodeType.hasPrefix("experiences.history.milestones")
        }
    }
    
    /// Get all lifestyle nodes
    /// 支持旧格式 "lifestyle" 和新格式 "self.physical" 前缀
    public var lifestyles: [KnowledgeNode] {
        knowledgeNodes.filter {
            $0.nodeType == "lifestyle" ||
            $0.nodeType.hasPrefix("self.physical")
        }
    }
    
    /// Get all preferences
    /// 支持旧格式 "preference" 和新格式 "self.personality.behavioral_preferences" 前缀
    public var preferences: [KnowledgeNode] {
        knowledgeNodes.filter {
            $0.nodeType == "preference" ||
            $0.nodeType.hasPrefix("self.personality.behavioral_preferences")
        }
    }
    
    /// Get nodes that need review
    public var nodesNeedingReview: [KnowledgeNode] {
        knowledgeNodes.filter { $0.needsReview }
    }
    
    /// Get nodes from AI (not yet confirmed)
    public var unconfirmedAINodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.isFromAI && !$0.isConfirmed }
    }
    
    // MARK: - Level 1 Dimension Accessors
    
    /// Get all nodes under "self" dimension (本体)
    public var selfDimensionNodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.matchesLevel1(.self_) }
    }
    
    /// Get all nodes under "material" dimension (物质)
    public var materialDimensionNodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.matchesLevel1(.material) }
    }
    
    /// Get all nodes under "achievements" dimension (成就)
    public var achievementsDimensionNodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.matchesLevel1(.achievements) }
    }
    
    /// Get all nodes under "experiences" dimension (阅历)
    public var experiencesDimensionNodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.matchesLevel1(.experiences) }
    }
    
    /// Get all nodes under "spirit" dimension (精神)
    public var spiritDimensionNodes: [KnowledgeNode] {
        knowledgeNodes.filter { $0.matchesLevel1(.spirit) }
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

// MARK: - Data Source Type Icons (L4 Source Info Redesign)

/// 数据表来源类型图标和显示名称
///
/// 用于在 UI 中显示来源类型的图标和中文名称。
/// 支持的来源类型：
/// - diary: 日记
/// - conversation: AI对话
/// - tracker: 追踪器
/// - mindState: 心情记录
///
/// ## Usage Example
/// ```swift
/// let icon = DataSourceTypeIcons.icon(for: "diary")  // "book.fill"
/// let name = DataSourceTypeIcons.displayName(for: "diary")  // "日记"
/// ```
public struct DataSourceTypeIcons {
    
    /// 获取来源类型图标
    /// - Parameter sourceType: 来源类型字符串 (diary/conversation/tracker/mindState)
    /// - Returns: SF Symbol 图标名称
    public static func icon(for sourceType: String) -> String {
        switch sourceType {
        case "diary":
            return "book.fill"
        case "conversation":
            return "bubble.left.and.bubble.right.fill"
        case "tracker":
            return "checklist"
        case "mindState":
            return "heart.fill"
        default:
            return "doc.fill"
        }
    }
    
    /// 获取来源类型显示名称
    /// - Parameter sourceType: 来源类型字符串 (diary/conversation/tracker/mindState)
    /// - Returns: 中文显示名称
    public static func displayName(for sourceType: String) -> String {
        switch sourceType {
        case "diary":
            return "日记"
        case "conversation":
            return "AI对话"
        case "tracker":
            return "追踪器"
        case "mindState":
            return "心情记录"
        default:
            return "其他"
        }
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
