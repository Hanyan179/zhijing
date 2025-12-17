import Foundation

/// Repository for managing user-created activity tags
public final class ActivityTagRepository {
    public static let shared = ActivityTagRepository()
    
    private let fileName = "activity_tags.json"
    private var cache: [ActivityTag] = []
    private var isLoaded = false
    
    private init() {}
    
    // MARK: - File URL
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    // MARK: - Public Methods
    
    /// Get tags for a specific activity type, sorted by usage count (descending)
    public func getTags(for type: ActivityType) -> [ActivityTag] {
        loadIfNeeded()
        return cache
            .filter { $0.activityType == type }
            .sorted { $0.usageCount > $1.usageCount }
    }
    
    /// Get all tags, sorted by usage count (descending)
    public func getAllTags() -> [ActivityTag] {
        loadIfNeeded()
        return cache.sorted { $0.usageCount > $1.usageCount }
    }
    
    /// Save a new tag
    public func saveTag(_ tag: ActivityTag) {
        loadIfNeeded()
        
        // Check for duplicate text in same activity type
        if cache.contains(where: { $0.activityType == tag.activityType && $0.text == tag.text }) {
            return
        }
        
        cache.append(tag)
        persistToDisk()
    }
    
    /// Create and save a new tag
    public func createTag(text: String, for type: ActivityType) -> ActivityTag {
        let tag = ActivityTag(
            activityType: type,
            text: text,
            isSystemPreset: false,
            usageCount: 1,
            lastUsedAt: Date()
        )
        saveTag(tag)
        return tag
    }
    
    /// Increment usage count for a tag
    public func incrementUsage(tagId: String) {
        loadIfNeeded()
        
        if let index = cache.firstIndex(where: { $0.id == tagId }) {
            cache[index].usageCount += 1
            cache[index].lastUsedAt = Date()
            persistToDisk()
        }
    }
    
    /// Increment usage for multiple tags
    public func incrementUsage(tagIds: [String]) {
        loadIfNeeded()
        
        for tagId in tagIds {
            if let index = cache.firstIndex(where: { $0.id == tagId }) {
                cache[index].usageCount += 1
                cache[index].lastUsedAt = Date()
            }
        }
        
        persistToDisk()
    }
    
    /// Delete a tag
    public func deleteTag(id: String) {
        loadIfNeeded()
        cache.removeAll { $0.id == id }
        persistToDisk()
    }
    
    /// Check if a tag text exists for an activity type
    public func tagExists(text: String, for type: ActivityType) -> Bool {
        loadIfNeeded()
        return cache.contains { $0.activityType == type && $0.text == text }
    }
    
    /// Get tag by ID
    public func getTag(id: String) -> ActivityTag? {
        loadIfNeeded()
        return cache.first { $0.id == id }
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
            cache = try JSONDecoder().decode([ActivityTag].self, from: data)
        } catch {
            print("ActivityTagRepository: Failed to load - \(error)")
            cache = []
        }
        
        isLoaded = true
    }
    
    private func persistToDisk() {
        guard let url = fileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: url, options: .atomic)
        } catch {
            print("ActivityTagRepository: Failed to save - \(error)")
        }
    }
}
