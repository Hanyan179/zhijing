import Foundation
import Combine

// MARK: - Narrative Relationship ViewModel

/// ViewModel for managing narrative relationship profiles (no scores)
/// Replaces RelationshipProfileViewModel with narrative-based approach
public class NarrativeRelationshipViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var relationships: [NarrativeRelationship] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let repository = NarrativeRelationshipRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Relationships grouped by type
    public var relationshipsByType: [CompanionType: [NarrativeRelationship]] {
        Dictionary(grouping: relationships, by: { $0.type })
    }
    
    /// Relationships with recent mentions (active relationships)
    public var activeRelationships: [NarrativeRelationship] {
        relationships.filter { !$0.recentMentions(days: 30).isEmpty }
            .sorted { $0.mentions.last?.date ?? Date.distantPast > $1.mentions.last?.date ?? Date.distantPast }
    }
    
    /// Total mention count across all relationships
    public var totalMentionCount: Int {
        relationships.reduce(0) { $0 + $1.mentionCount }
    }
    
    // MARK: - Initialization
    
    public init() {
        loadData()
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: Notification.Name("gj_relationships_updated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    public func loadData() {
        isLoading = true
        relationships = repository.loadAll()
        isLoading = false
    }
    
    // MARK: - Filtering
    
    /// Get relationships for a specific type
    public func relationshipsForType(_ type: CompanionType, searchText: String = "") -> [NarrativeRelationship] {
        let typeRelationships = relationships.filter { $0.type == type }
        
        if searchText.isEmpty {
            return typeRelationships
        }
        
        return typeRelationships.filter { relationship in
            relationship.displayName.localizedCaseInsensitiveContains(searchText) ||
            (relationship.realName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            relationship.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Search all relationships
    public func search(_ searchText: String) -> [NarrativeRelationship] {
        if searchText.isEmpty {
            return relationships
        }
        
        return repository.search(query: searchText)
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new relationship
    public func create(_ relationship: NarrativeRelationship) {
        repository.save(relationship)
        loadData()
    }
    
    /// Update an existing relationship
    public func update(_ relationship: NarrativeRelationship) {
        repository.save(relationship)
        loadData()
    }
    
    /// Delete a relationship
    public func delete(_ relationship: NarrativeRelationship) {
        repository.delete(id: relationship.id)
        loadData()
    }
    
    /// Delete by ID
    public func delete(id: String) {
        repository.delete(id: id)
        loadData()
    }
    
    /// Get relationship by ID
    public func getRelationship(id: String) -> NarrativeRelationship? {
        repository.load(id: id)
    }
    
    // MARK: - Narrative Operations
    
    /// Update narrative description
    public func updateNarrative(relationshipId: String, narrative: String?) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        relationship.narrative = narrative
        update(relationship)
    }
    
    /// Add a tag
    public func addTag(relationshipId: String, tag: String) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        guard !tag.isEmpty, !relationship.tags.contains(tag) else { return }
        relationship.tags.append(tag)
        update(relationship)
    }
    
    /// Remove a tag
    public func removeTag(relationshipId: String, tag: String) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        relationship.tags.removeAll { $0 == tag }
        update(relationship)
    }
    
    // MARK: - Fact Anchor Operations
    
    /// Add anniversary
    public func addAnniversary(relationshipId: String, name: String, date: String, year: Int? = nil) {
        repository.addAnniversary(relationshipId: relationshipId, name: name, date: date, year: year)
        loadData()
    }
    
    /// Remove anniversary
    public func removeAnniversary(relationshipId: String, anniversaryId: String) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        relationship.factAnchors.anniversaries.removeAll { $0.id == anniversaryId }
        update(relationship)
    }
    
    /// Add shared experience
    public func addSharedExperience(relationshipId: String, experience: String) {
        repository.addSharedExperience(relationshipId: relationshipId, experience: experience)
        loadData()
    }
    
    /// Remove shared experience
    public func removeSharedExperience(relationshipId: String, experience: String) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        relationship.factAnchors.sharedExperiences.removeAll { $0 == experience }
        update(relationship)
    }
    
    /// Update first meeting date
    public func updateFirstMeetingDate(relationshipId: String, date: String?) {
        guard var relationship = getRelationship(id: relationshipId) else { return }
        relationship.factAnchors.firstMeetingDate = date
        update(relationship)
    }
    
    // MARK: - Mention Operations
    
    /// Get mentions for a relationship
    public func getMentions(relationshipId: String) -> [RelationshipMention] {
        getRelationship(id: relationshipId)?.mentions ?? []
    }
    
    /// Get recent mentions
    public func getRecentMentions(relationshipId: String, days: Int = 30) -> [RelationshipMention] {
        repository.getRecentMentions(relationshipId: relationshipId, days: days)
    }
    
    /// Add a mention (called by system when diary/tracker mentions this person)
    public func addMention(
        relationshipId: String,
        sourceType: MentionSource,
        sourceId: String,
        contextSnippet: String
    ) {
        repository.addMention(
            relationshipId: relationshipId,
            sourceType: sourceType,
            sourceId: sourceId,
            contextSnippet: contextSnippet
        )
        loadData()
    }
    
    // MARK: - Display Helpers
    
    /// Format mention count for display
    public func displayMentionCount(_ relationship: NarrativeRelationship) -> String {
        let count = relationship.mentionCount
        if count == 0 {
            return Localization.tr("Relationship.NoMentions")
        }
        return String(format: Localization.tr("Relationship.MentionCount"), count)
    }
    
    /// Format recent activity for display
    public func displayRecentActivity(_ relationship: NarrativeRelationship) -> String? {
        guard let lastMention = relationship.mentions.last else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let timeAgo = formatter.localizedString(for: lastMention.date, relativeTo: Date())
        
        return "\(timeAgo): \(lastMention.contextSnippet)"
    }
}
