import Foundation

public final class MindStateRepository {
    private let key = "mind_state_records"
    public init() {}
    
    public func save(_ record: MindStateRecord) {
        var all = loadAll()
        all.append(record)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    public func loadAll() -> [MindStateRecord] {
        guard let data = UserDefaults.standard.data(forKey: key), let list = try? JSONDecoder().decode([MindStateRecord].self, from: data) else { return [] }
        return list
    }
    
    public func load(for date: String) -> [MindStateRecord] { loadAll().filter { $0.date == date } }
    
    /// 获取距离当前时间最近的心情记录
    /// 用于机器人头像的动态显示
    public func loadLatest() -> MindStateRecord? {
        let all = loadAll()
        return all.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    /// 获取指定日期最近的心情记录
    public func loadLatest(for date: String) -> MindStateRecord? {
        let records = load(for: date)
        return records.sorted { $0.createdAt > $1.createdAt }.first
    }
}
