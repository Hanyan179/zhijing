import Foundation

public final class TimelineRepository {
    public static let shared = TimelineRepository()
    
    // File URLs
    private let dailyTimelinesURL: URL
    
    // In-memory cache
    private var timelineCache: [String: DailyTimeline] = [:] // Date -> DailyTimeline
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseDir = docs.appendingPathComponent("TimelineData_v2", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        
        dailyTimelinesURL = baseDir.appendingPathComponent("daily_timelines.json")
        
        loadFromDisk()
        
        // Removed Mock Data Seeding
    }
    
    // MARK: - Public API
    
    /// Get the full DailyTimeline object for a specific date.
    /// If it doesn't exist, create a new skeleton.
    public func getDailyTimeline(for date: String) -> DailyTimeline {
        if let existing = timelineCache[date] {
            print("[TimelineRepo] getDailyTimeline(\(date)): found in cache, items count = \(existing.items.count)")
            return existing
        }
        
        print("[TimelineRepo] getDailyTimeline(\(date)): NOT in cache, creating new skeleton. Cache keys: \(timelineCache.keys.sorted())")
        
        // Create new skeleton
        let newId = "day_" + date.replacingOccurrences(of: ".", with: "")
        let newTimeline = DailyTimeline(id: newId, date: date)
        timelineCache[date] = newTimeline
        persistToDisk()
        return newTimeline
    }
    
    /// Save or update a DailyTimeline
    public func save(timeline: DailyTimeline) {
        var updatedTimeline = timeline
        updatedTimeline.updatedAt = Date()
        updatedTimeline.regenerateTags() // Auto-update tags
        
        timelineCache[updatedTimeline.date] = updatedTimeline
        persistToDisk()
        
        // Notify observers
        NotificationCenter.default.post(name: Notification.Name("gj_timeline_updated"), object: nil)
    }
    
    // Helper to just save items for legacy compatibility, wrapping them into the DailyTimeline
    public func saveItems(_ items: [TimelineItem], for date: String) {
        var timeline = getDailyTimeline(for: date)
        timeline.items = items
        save(timeline: timeline)
    }
    
    public func appendItem(_ item: TimelineItem, for date: String) {
        var timeline = getDailyTimeline(for: date)
        timeline.items.append(item)
        save(timeline: timeline)
    }
    
    public func updateEntry(_ entry: JournalEntry) {
        // Find which timeline has this entry and update it
        // This is expensive O(N) search across all days if we don't know the date.
        // Ideally we should know the date.
        // For now, let's assume we can find it in the current cache or iterate.
        
        // Optimization: Try to guess date from timestamp or require date in API.
        // But `timestamp` is HH:mm.
        
        for (_, var timeline) in timelineCache {
            var changed = false
            for (i, item) in timeline.items.enumerated() {
                switch item {
                case .scene(let s):
                    if let idx = s.entries.firstIndex(where: { $0.id == entry.id }) {
                        var newEntries = s.entries
                        newEntries[idx] = entry
                        let newScene = SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: newEntries)
                        timeline.items[i] = .scene(newScene)
                        changed = true
                    }
                case .journey(let j):
                    if let idx = j.entries.firstIndex(where: { $0.id == entry.id }) {
                        var newEntries = j.entries
                        newEntries[idx] = entry
                        let newJourney = JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, entries: newEntries)
                        timeline.items[i] = .journey(newJourney)
                        changed = true
                    }
                }
            }
            if changed {
                save(timeline: timeline)
                return // Found and updated
            }
        }
    }
    
    public func updateLocationName(itemId: String, newName: String, for date: String) {
        var timeline = getDailyTimeline(for: date)
        if let idx = timeline.items.firstIndex(where: { $0.id == itemId }) {
            let item = timeline.items[idx]
            switch item {
            case .scene(let s):
                let newLoc = LocationVO(status: s.location.status, mappingId: s.location.mappingId, snapshot: s.location.snapshot, displayText: newName, originalRawName: newName, icon: s.location.icon, color: s.location.color)
                timeline.items[idx] = .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: newLoc, entries: s.entries))
            case .journey: break
            }
            save(timeline: timeline)
        }
    }
    
    public func updateOriginName(itemId: String, newName: String, for date: String) {
        var timeline = getDailyTimeline(for: date)
        if let idx = timeline.items.firstIndex(where: { $0.id == itemId }) {
            let item = timeline.items[idx]
            switch item {
            case .journey(let j):
                let newOrigin = LocationVO(status: j.origin.status, mappingId: j.origin.mappingId, snapshot: j.origin.snapshot, displayText: newName, originalRawName: newName, icon: j.origin.icon, color: j.origin.color)
                timeline.items[idx] = .journey(JourneyBlock(type: j.type, id: j.id, origin: newOrigin, destination: j.destination, mode: j.mode, entries: j.entries))
            case .scene: break
            }
            save(timeline: timeline)
        }
    }
    
    public func updateJourneyDestination(itemId: String, newDestination: LocationVO, for date: String) {
        var timeline = getDailyTimeline(for: date)
        if let idx = timeline.items.firstIndex(where: { $0.id == itemId }) {
            if case .journey(let j) = timeline.items[idx] {
                let updatedJourney = JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: newDestination, mode: j.mode, entries: j.entries)
                timeline.items[idx] = .journey(updatedJourney)
                save(timeline: timeline)
            }
        }
    }
    
    // MARK: - Persistence Logic
    
    private func loadFromDisk() {
        if let data = try? Data(contentsOf: dailyTimelinesURL),
           let cache = try? JSONDecoder().decode([String: DailyTimeline].self, from: data) {
            self.timelineCache = cache
        }
    }
    
    private func persistToDisk() {
        // Capture a snapshot of the cache on the main thread to avoid race conditions
        let cacheSnapshot = self.timelineCache
        
        // Run on background thread to avoid UI freeze
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(cacheSnapshot)
                try data.write(to: self.dailyTimelinesURL)
            } catch {
                print("Timeline Persistence Error: \(error)")
            }
        }
    }
    
    // MARK: - Seeding
    
    // Mock seeding removed
    // private func seedMockData() { ... }
    
    // MARK: - History API
    
    public func getAllTimelines() -> [DailyTimeline] {
        return Array(timelineCache.values).sorted(by: { $0.date > $1.date })
    }
    
    public func getEntry(id: String) -> JournalEntry? {
        for timeline in timelineCache.values {
            for item in timeline.items {
                switch item {
                case .scene(let s):
                    if let entry = s.entries.first(where: { $0.id == id }) { return entry }
                case .journey(let j):
                    if let entry = j.entries.first(where: { $0.id == id }) { return entry }
                }
            }
        }
        return nil
    }
    
    public func getReplies(for questionId: String) -> [JournalEntry] {
        var replies: [JournalEntry] = []
        for timeline in timelineCache.values {
            for item in timeline.items {
                switch item {
                case .scene(let s):
                    replies.append(contentsOf: s.entries.filter { $0.metadata?.questionId == questionId })
                case .journey(let j):
                    replies.append(contentsOf: j.entries.filter { $0.metadata?.questionId == questionId })
                }
            }
        }
        return replies
    }
}
