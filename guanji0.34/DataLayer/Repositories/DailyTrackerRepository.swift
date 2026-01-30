import Foundation

/// Repository for managing DailyTrackerRecord persistence
public final class DailyTrackerRepository {
    public static let shared = DailyTrackerRepository()
    
    private let fileName = "daily_tracker_records.json"
    private var cache: [DailyTrackerRecord] = []
    private var isLoaded = false
    
    private init() {}
    
    // MARK: - File URL
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    // MARK: - Public Methods
    
    /// Save a daily tracker record (overwrites if same date exists)
    public func save(_ record: DailyTrackerRecord) {
        loadIfNeeded()
        
        // Remove existing record for same date
        cache.removeAll { $0.date == record.date }
        cache.append(record)
        
        persistToDisk()
        
        // Notify observers
        NotificationCenter.default.post(name: Notification.Name("gj_tracker_updated"), object: nil)
    }
    
    /// Load record for a specific date
    public func load(for date: String) -> DailyTrackerRecord? {
        loadIfNeeded()
        return cache.first { $0.date == date }
    }
    
    /// Load all records
    public func loadAll() -> [DailyTrackerRecord] {
        loadIfNeeded()
        return cache
    }
    
    /// 获取距离当前时间最近的记录
    /// 用于机器人头像的动态显示
    public func loadLatest() -> DailyTrackerRecord? {
        loadIfNeeded()
        return cache.sorted { $0.updatedAt > $1.updatedAt }.first
    }
    
    /// Check if a record exists for today
    public func hasRecordForToday() -> Bool {
        return load(for: DateUtilities.today) != nil
    }
    
    /// Delete record for a specific date
    public func delete(for date: String) {
        loadIfNeeded()
        cache.removeAll { $0.date == date }
        persistToDisk()
        
        NotificationCenter.default.post(name: Notification.Name("gj_tracker_updated"), object: nil)
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
            cache = try JSONDecoder().decode([DailyTrackerRecord].self, from: data)
        } catch {
            print("DailyTrackerRepository: Failed to load - \(error)")
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
            print("DailyTrackerRepository: Failed to save - \(error)")
        }
    }
}


