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
    
    /// Update a static core field with history tracking
    public func updateStaticCoreField(
        fieldName: String,
        oldValue: String?,
        newValue: String?,
        updateBlock: (inout StaticCore) -> Void
    ) {
        var profile = load()
        
        // Create update record
        let record = ProfileUpdateRecord(
            fieldName: fieldName,
            oldValue: oldValue,
            newValue: newValue
        )
        
        // Apply update
        updateBlock(&profile.staticCore)
        
        // Add to history
        profile.staticCore.updateHistory.append(record)
        
        save(profile)
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

// MARK: - Migration Support

extension NarrativeUserProfileRepository {
    
    /// Migrate from legacy UserProfile format
    public func migrateFromLegacy(_ legacy: UserProfile) -> NarrativeUserProfile {
        let staticCore = StaticCore(
            gender: legacy.identity.kernel.gender,
            birthYearMonth: legacy.identity.kernel.birthDate,
            hometown: legacy.identity.kernel.hometown,
            currentCity: legacy.identity.kernel.currentCity,
            occupation: legacy.competence.kernel.occupation,
            industry: legacy.competence.kernel.industry,
            education: legacy.identity.kernel.education,
            selfTags: [],
            updateHistory: []
        )
        
        let profile = NarrativeUserProfile(
            id: legacy.id,
            createdAt: legacy.createdAt,
            updatedAt: Date(),
            staticCore: staticCore,
            recentPortrait: nil,
            relationshipIds: legacy.social.kernel.coreRelationshipIDs
        )
        
        return profile
    }
    
    /// Check if migration is needed
    public func needsMigration() -> Bool {
        let migrationKey = "has_migrated_narrative_profile"
        return !UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    /// Mark migration as complete
    public func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: "has_migrated_narrative_profile")
    }
}
