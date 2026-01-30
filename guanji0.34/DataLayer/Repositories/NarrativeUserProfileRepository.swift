import Foundation

/// Repository for managing NarrativeUserProfile persistence
public final class NarrativeUserProfileRepository {
    public static let shared = NarrativeUserProfileRepository()
    
    private let fileName = "narrative_user_profile.json"
    private var cache: NarrativeUserProfile?
    private var isLoaded = false
    
    private init() {}
    
    // MARK: - File URL
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    // MARK: - Public Methods
    
    /// Load the user profile (creates default if not exists)
    public func load() -> NarrativeUserProfile {
        loadIfNeeded()
        return cache ?? createDefault()
    }
    
    /// Save the user profile
    public func save(_ profile: NarrativeUserProfile) {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        cache = updatedProfile
        persistToDisk()
        
        NotificationCenter.default.post(
            name: Notification.Name("gj_user_profile_updated"),
            object: nil
        )
    }
    
    /// Add a relationship ID to the profile
    public func addRelationship(id: String) {
        var profile = load()
        if !profile.relationshipIds.contains(id) {
            profile.relationshipIds.append(id)
            save(profile)
        }
    }
    
    /// Remove a relationship ID from the profile
    public func removeRelationship(id: String) {
        var profile = load()
        profile.relationshipIds.removeAll { $0 == id }
        save(profile)
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
            cache = nil
            isLoaded = true
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            cache = try JSONDecoder().decode(NarrativeUserProfile.self, from: data)
        } catch {
            print("NarrativeUserProfileRepository: Failed to load - \(error)")
            cache = nil
        }
        
        isLoaded = true
    }
    
    private func persistToDisk() {
        guard let url = fileURL, let profile = cache else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(profile)
            try data.write(to: url, options: .atomic)
        } catch {
            print("NarrativeUserProfileRepository: Failed to save - \(error)")
        }
    }
    
    private func createDefault() -> NarrativeUserProfile {
        let profile = NarrativeUserProfile()
        cache = profile
        persistToDisk()
        return profile
    }
}


