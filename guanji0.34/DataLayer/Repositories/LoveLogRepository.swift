import Foundation

/// Repository for managing LoveLog persistence
/// Follows singleton pattern consistent with other repositories
public final class LoveLogRepository {
    public static let shared = LoveLogRepository()
    
    private let fileURL: URL
    private var logs: [String: LoveLog] = [:]
    
    /// Notification posted when love logs are updated
    public static let logsUpdatedNotification = Notification.Name("gj_love_logs_updated")
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("TimelineData", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("love_logs.json")
        load()
    }
    
    // MARK: - Persistence
    
    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let dict = try? JSONDecoder().decode([String: LoveLog].self, from: data) {
            logs = dict
        }
    }
    
    private func save() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            if let data = try? JSONEncoder().encode(self.logs) {
                try? data.write(to: self.fileURL)
            }
        }
    }
    
    private func notifyUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.logsUpdatedNotification, object: nil)
        }
    }
    
    // MARK: - Public API
    
    /// Get all love logs
    public func getAllLogs() -> [LoveLog] {
        return Array(logs.values).sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Get a specific log by ID
    public func get(id: String) -> LoveLog? {
        return logs[id]
    }
    
    /// Add a new love log
    public func addLog(_ log: LoveLog) {
        logs[log.id] = log
        save()
        notifyUpdate()
    }
    
    /// Delete a love log
    public func deleteLog(id: String) {
        logs.removeValue(forKey: id)
        save()
        notifyUpdate()
    }
    
    /// Get total count of logs
    public func getCount() -> Int {
        return logs.count
    }
    
    // MARK: - Statistics
    
    /// Get logs grouped by sender with counts (for statistics)
    public func getLogsBySender() -> [String: Int] {
        var result: [String: Int] = [:]
        for log in logs.values {
            let sender = log.sender
            result[sender, default: 0] += 1
        }
        return result
    }
    
    /// Get logs grouped by receiver with counts
    public func getLogsByReceiver() -> [String: Int] {
        var result: [String: Int] = [:]
        for log in logs.values {
            let receiver = log.receiver
            result[receiver, default: 0] += 1
        }
        return result
    }
}
