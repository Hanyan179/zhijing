import Foundation

// MARK: - Context Builder

/// Builds sanitized context data for AI knowledge extraction
/// Removes sensitive information (realName, hometown, currentCity, etc.)
public final class ContextBuilder {
    
    public static let shared = ContextBuilder()
    
    private let userProfileRepo = NarrativeUserProfileRepository.shared
    private let relationshipRepo = NarrativeRelationshipRepository.shared
    private let sanitizer = TextSanitizer()
    
    private init() {}
    
    // MARK: - Build Context from Request
    
    /// Build sanitized context based on server's context request
    public func buildContext(for request: ContextRequest) -> SanitizedContext {
        var userProfile: SanitizedUserProfile? = nil
        var relationships: [SanitizedRelationship] = []
        
        for item in request.requestedContexts {
            switch item.type {
            case .userProfile:
                userProfile = buildUserProfile()
            case .relationship:
                if let id = item.id, let rel = buildRelationship(id: id) {
                    relationships.append(rel)
                }
            }
        }
        
        return SanitizedContext(userProfile: userProfile, relationships: relationships)
    }
    
    // MARK: - Build User Profile
    
    /// Build sanitized user profile (removes sensitive fields)
    public func buildUserProfile() -> SanitizedUserProfile? {
        let profile = userProfileRepo.load()
        
        // Build sanitized static core (no hometown, currentCity)
        let staticCore = SanitizedStaticCore(
            nickname: profile.staticCore.nickname,
            gender: profile.staticCore.gender?.rawValue,
            birthYearMonth: profile.staticCore.birthYearMonth,
            occupation: profile.staticCore.occupation,
            industry: profile.staticCore.industry,
            education: profile.staticCore.education?.rawValue
        )
        
        // Build knowledge node summaries
        let nodeSummaries = profile.knowledgeNodes.map { node in
            KnowledgeNodeSummary(
                id: node.id,
                nodeType: node.nodeType,
                name: node.name,
                description: node.description,
                confidence: node.currentConfidence,
                tags: node.tags
            )
        }
        
        // Build AI preferences summary
        var aiPrefs: AIPreferencesSummary? = nil
        if let prefs = profile.aiPreferences, prefs.hasAnyPreference {
            aiPrefs = AIPreferencesSummary(
                preferredStyle: prefs.style.tone?.rawValue,
                topics: prefs.topics.favorites
            )
        }
        
        return SanitizedUserProfile(
            staticCore: staticCore,
            knowledgeNodes: nodeSummaries,
            aiPreferences: aiPrefs
        )
    }
    
    // MARK: - Build Relationship
    
    /// Build sanitized relationship (removes realName)
    public func buildRelationship(id: String) -> SanitizedRelationship? {
        guard let relationship = relationshipRepo.load(id: id) else {
            return nil
        }
        
        return sanitizeRelationship(relationship)
    }
    
    /// Build multiple sanitized relationships
    public func buildRelationships(ids: [String]) -> [SanitizedRelationship] {
        return ids.compactMap { buildRelationship(id: $0) }
    }
    
    /// Build all relationships (for full context export)
    public func buildAllRelationships() -> [SanitizedRelationship] {
        let relationships = relationshipRepo.loadAll()
        return relationships.map { sanitizeRelationship($0) }
    }
    
    // MARK: - Private Helpers
    
    private func sanitizeRelationship(_ relationship: NarrativeRelationship) -> SanitizedRelationship {
        // Build ref format
        let ref = "[REL_\(relationship.id):\(relationship.displayName)]"
        
        // Build attribute summaries
        let attributeSummaries = relationship.attributes.map { node in
            KnowledgeNodeSummary(
                id: node.id,
                nodeType: node.nodeType,
                name: node.name,
                description: node.description,
                confidence: node.currentConfidence,
                tags: node.tags
            )
        }
        
        // Build sanitized fact anchors
        var factAnchors: SanitizedFactAnchors? = nil
        if relationship.hasFactAnchors {
            factAnchors = SanitizedFactAnchors(
                firstMeetingDate: relationship.factAnchors.firstMeetingDate,
                sharedExperiences: relationship.factAnchors.sharedExperiences
            )
        }
        
        // Sanitize narrative (remove any real names)
        let sanitizedNarrative = sanitizer.sanitize(relationship.narrative)
        
        return SanitizedRelationship(
            id: relationship.id,
            ref: ref,
            type: relationship.type.rawValue,
            displayName: relationship.displayName,
            aliases: relationship.aliases,
            narrative: sanitizedNarrative,
            tags: relationship.tags,
            attributes: attributeSummaries,
            factAnchors: factAnchors
        )
    }
}
