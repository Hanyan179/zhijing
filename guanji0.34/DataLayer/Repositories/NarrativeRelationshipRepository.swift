import Foundation

/// Repository for managing NarrativeRelationship persistence
public final class NarrativeRelationshipRepository {
    public static let shared = NarrativeRelationshipRepository()
    
    private let fileName = "narrative_relationships.json"
    private var cache: [NarrativeRelationship] = []
    private var isLoaded = false
    
    private init() {}
    
    // MARK: - File URL
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    // MARK: - CRUD Operations
    
    /// Load all relationships
    public func loadAll() -> [NarrativeRelationship] {
        loadIfNeeded()
        return cache
    }
    
    /// Load a specific relationship by ID
    public func load(id: String) -> NarrativeRelationship? {
        loadIfNeeded()
        return cache.first { $0.id == id }
    }
    
    /// Load relationships by type
    public func loadByType(_ type: CompanionType) -> [NarrativeRelationship] {
        loadIfNeeded()
        return cache.filter { $0.type == type }
    }
    
    /// Save a relationship (creates or updates)
    public func save(_ relationship: NarrativeRelationship) {
        loadIfNeeded()
        
        var updated = relationship
        updated.updatedAt = Date()
        
        if let index = cache.firstIndex(where: { $0.id == relationship.id }) {
            cache[index] = updated
        } else {
            cache.append(updated)
            // Add to user profile
            NarrativeUserProfileRepository.shared.addRelationship(id: updated.id)
        }
        
        persistToDisk()
        notifyUpdate()
    }
    
    /// Delete a relationship
    public func delete(id: String) {
        loadIfNeeded()
        cache.removeAll { $0.id == id }
        persistToDisk()
        
        // Remove from user profile
        NarrativeUserProfileRepository.shared.removeRelationship(id: id)
        notifyUpdate()
    }
    
    // MARK: - Mention Operations
    
    /// Add a mention to a relationship
    public func addMention(
        relationshipId: String,
        sourceType: MentionSource,
        sourceId: String,
        contextSnippet: String
    ) {
        guard var relationship = load(id: relationshipId) else { return }
        
        let mention = RelationshipMention(
            sourceType: sourceType,
            sourceId: sourceId,
            contextSnippet: contextSnippet
        )
        
        relationship.mentions.append(mention)
        save(relationship)
    }
    
    /// Get recent mentions for a relationship
    public func getRecentMentions(relationshipId: String, days: Int = 30) -> [RelationshipMention] {
        guard let relationship = load(id: relationshipId) else { return [] }
        return relationship.recentMentions(days: days)
    }
    
    // MARK: - Fact Anchor Operations
    
    /// Add an anniversary to a relationship
    public func addAnniversary(
        relationshipId: String,
        name: String,
        date: String,
        year: Int? = nil
    ) {
        guard var relationship = load(id: relationshipId) else { return }
        
        let anniversary = Anniversary(name: name, date: date, year: year)
        relationship.factAnchors.anniversaries.append(anniversary)
        save(relationship)
    }
    
    /// Add a shared experience to a relationship
    public func addSharedExperience(relationshipId: String, experience: String) {
        guard var relationship = load(id: relationshipId) else { return }
        
        if !relationship.factAnchors.sharedExperiences.contains(experience) {
            relationship.factAnchors.sharedExperiences.append(experience)
            save(relationship)
        }
    }
    
    /// Update first meeting date
    public func updateFirstMeetingDate(relationshipId: String, date: String) {
        guard var relationship = load(id: relationshipId) else { return }
        relationship.factAnchors.firstMeetingDate = date
        save(relationship)
    }
    
    // MARK: - Query Operations
    
    /// Search relationships by name
    public func search(query: String) -> [NarrativeRelationship] {
        loadIfNeeded()
        let lowercased = query.lowercased()
        return cache.filter {
            $0.displayName.lowercased().contains(lowercased) ||
            ($0.realName?.lowercased().contains(lowercased) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    /// Get relationships with recent mentions
    public func getActiveRelationships(days: Int = 30) -> [NarrativeRelationship] {
        loadIfNeeded()
        return cache.filter { !$0.recentMentions(days: days).isEmpty }
            .sorted { $0.mentions.last?.date ?? Date.distantPast > $1.mentions.last?.date ?? Date.distantPast }
    }
    
    /// Force reload from disk
    public func reload() {
        isLoaded = false
        loadIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func loadIfNeeded() {
        guard !isLoaded else { return }
        
        guard let url = fileURL else {
            cache = []
            isLoaded = true
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            cache = try decoder.decode([NarrativeRelationship].self, from: data)
        } catch {
            print("NarrativeRelationshipRepository: Failed to load - \(error)")
            cache = []
        }
        
        isLoaded = true
    }
    
    private func persistToDisk() {
        guard let url = fileURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cache)
            try data.write(to: url, options: .atomic)
        } catch {
            print("NarrativeRelationshipRepository: Failed to save - \(error)")
        }
    }
    
    private func notifyUpdate() {
        NotificationCenter.default.post(
            name: Notification.Name("gj_relationships_updated"),
            object: nil
        )
    }
}


