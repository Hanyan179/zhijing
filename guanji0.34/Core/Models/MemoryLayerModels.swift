import Foundation

// MARK: - L2 Layer: Episodic Memory (Daily Summary)

/// Daily summary - AI analysis of daily events
public struct DailySummary: Codable, Identifiable {
    public let id: String
    public let date: String                     // YYYY-MM-DD
    
    // AI analysis results
    public var summary: String                  // 200-300 words
    public var keyEvents: [String]
    public var emotionalTone: String
    
    // Dimension analysis (on-demand extraction)
    public var dimensionAnalysis: [DimensionTag: DimensionAnalysis]
    
    // Related structured events
    public var eventRefs: [String]              // StructuredEvent IDs
    
    // Metadata
    public var aiModel: String
    public var confidence: Double               // 0-1
    public var tokenUsage: Int
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        date: String,
        summary: String = "",
        keyEvents: [String] = [],
        emotionalTone: String = "",
        dimensionAnalysis: [DimensionTag: DimensionAnalysis] = [:],
        eventRefs: [String] = [],
        aiModel: String = "",
        confidence: Double = 0.0,
        tokenUsage: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.summary = summary
        self.keyEvents = keyEvents
        self.emotionalTone = emotionalTone
        self.dimensionAnalysis = dimensionAnalysis
        self.eventRefs = eventRefs
        self.aiModel = aiModel
        self.confidence = confidence
        self.tokenUsage = tokenUsage
        self.createdAt = createdAt
    }
}

// MARK: - Dimension Analysis

public struct DimensionAnalysis: Codable {
    public let dimension: DimensionTag
    public var observations: [String]           // Observed facts
    public var changes: [String]                // Change points
    public var suggestedUpdates: [ProfileUpdate] // Suggested updates
    
    public init(
        dimension: DimensionTag,
        observations: [String] = [],
        changes: [String] = [],
        suggestedUpdates: [ProfileUpdate] = []
    ) {
        self.dimension = dimension
        self.observations = observations
        self.changes = changes
        self.suggestedUpdates = suggestedUpdates
    }
}

// MARK: - Profile Update

public struct ProfileUpdate: Codable {
    public let field: String                    // Field path (e.g., "personality.state.moodWeather")
    public let value: String                    // New value
    public let reason: String                   // Update reason
    
    public init(field: String, value: String, reason: String) {
        self.field = field
        self.value = value
        self.reason = reason
    }
}

// MARK: - L4 Layer: Evolution Log (Change Tracking)

/// Evolution log - tracks profile changes with AI commentary
public struct EvolutionLog: Codable, Identifiable {
    public let id: String
    public let date: String                     // YYYY-MM-DD
    
    // Change type
    public var changeType: ChangeType
    
    // Change content
    public var dimension: DimensionTag
    public var field: String                    // Field path
    public var oldValue: String?
    public var newValue: String
    
    // AI commentary
    public var aiComment: String                // Why the change
    public var isSignificant: Bool              // Is it important
    public var confidence: Double               // 0-1
    
    // Traceability
    public var triggeredBy: String              // DailySummary ID
    public var evidence: [String]               // StructuredEvent IDs
    
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        date: String,
        changeType: ChangeType,
        dimension: DimensionTag,
        field: String,
        oldValue: String? = nil,
        newValue: String,
        aiComment: String = "",
        isSignificant: Bool = false,
        confidence: Double = 0.0,
        triggeredBy: String = "",
        evidence: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.changeType = changeType
        self.dimension = dimension
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.aiComment = aiComment
        self.isSignificant = isSignificant
        self.confidence = confidence
        self.triggeredBy = triggeredBy
        self.evidence = evidence
        self.createdAt = createdAt
    }
}

// MARK: - Change Type

public enum ChangeType: String, Codable {
    case stateFluctuation   // State change
    case kernelEvolution    // Kernel change
    case newDiscovery       // New discovery (was empty)
    case correction         // Correction (fix error)
}

// MARK: - Milestone Log

/// Milestone log - significant life events
public struct MilestoneLog: Codable, Identifiable {
    public let id: String
    public let date: String                     // YYYY-MM-DD
    public let title: String
    public let description: String
    public let dimension: DimensionTag
    public var relatedLogs: [String]            // EvolutionLog IDs
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        date: String,
        title: String,
        description: String,
        dimension: DimensionTag,
        relatedLogs: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.dimension = dimension
        self.relatedLogs = relatedLogs
        self.createdAt = createdAt
    }
}
