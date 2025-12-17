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
}
