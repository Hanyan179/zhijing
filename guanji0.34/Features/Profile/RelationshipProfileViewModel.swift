import Foundation
import Combine

// MARK: - Relationship Profile ViewModel

/// ViewModel for managing relationship profiles
/// Requirements: Epic 6
public class RelationshipProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var profiles: [RelationshipProfile] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// Profiles grouped by type
    public var profilesByType: [CompanionType: [RelationshipProfile]] {
        Dictionary(grouping: profiles, by: { $0.type })
    }
    
    // MARK: - Initialization
    
    public init() {
        loadMockData()
    }
    
    // MARK: - Data Loading
    
    /// Load mock data for development
    private func loadMockData() {
        isLoading = true
        // Use mock data from MockDataService
        profiles = MockDataService.relationshipProfiles
        isLoading = false
    }
    
    // MARK: - Filtering
    
    /// Get profiles for a specific type, optionally filtered by search text
    /// - Parameters:
    ///   - type: The companion type to filter by
    ///   - searchText: Optional search text to filter by name
    /// - Returns: Filtered array of profiles
    public func profilesForType(_ type: CompanionType, searchText: String = "") -> [RelationshipProfile] {
        let typeProfiles = profiles.filter { $0.type == type }
        
        if searchText.isEmpty {
            return typeProfiles
        }
        
        return typeProfiles.filter { profile in
            profile.displayName.localizedCaseInsensitiveContains(searchText) ||
            (profile.realName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            profile.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Search all profiles by text
    /// - Parameter searchText: Text to search for
    /// - Returns: Filtered array of profiles
    public func searchProfiles(_ searchText: String) -> [RelationshipProfile] {
        if searchText.isEmpty {
            return profiles
        }
        
        return profiles.filter { profile in
            profile.displayName.localizedCaseInsensitiveContains(searchText) ||
            (profile.realName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            profile.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
            (profile.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // MARK: - CRUD Operations (Placeholders)
    
    /// Create a new relationship profile
    /// - Parameter profile: The profile to create
    public func create(_ profile: RelationshipProfile) {
        // Placeholder: In future, persist to storage
        profiles.append(profile)
    }
    
    /// Update an existing relationship profile
    /// - Parameter profile: The profile to update
    public func update(_ profile: RelationshipProfile) {
        // Placeholder: In future, persist to storage
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
    }
    
    /// Delete a relationship profile
    /// - Parameter profile: The profile to delete
    public func delete(_ profile: RelationshipProfile) {
        // Placeholder: In future, persist to storage
        profiles.removeAll { $0.id == profile.id }
    }
    
    /// Delete a profile by ID
    /// - Parameter id: The ID of the profile to delete
    public func delete(id: String) {
        profiles.removeAll { $0.id == id }
    }
    
    /// Get a profile by ID
    /// - Parameter id: The profile ID
    /// - Returns: The profile if found
    public func getProfile(id: String) -> RelationshipProfile? {
        profiles.first { $0.id == id }
    }
}
