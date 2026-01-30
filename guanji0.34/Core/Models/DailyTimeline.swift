import Foundation

/// 每日主表 (Master Table for the Day)
/// 所有的子表（场景、旅程、原子）都挂载在这个表下
public struct DailyTimeline: Codable, Identifiable {
    /// 唯一标识，格式：day_YYYYMMDD
    public let id: String
    
    /// 日期字符串 (yyyy.MM.dd)
    public let date: String
    
    /// 天气描述
    public var weather: String?
    
    /// 创建时间
    public let createdAt: Date
    
    /// 更新时间
    public var updatedAt: Date
    
    /// 标题
    public var title: String?
    
    /// 时间节点表 (Timeline Items: Scenes & Journeys)
    public var items: [TimelineItem]
    
    /// 原子表中类型的去重总和
    public var tags: [EntryCategory]
    
    public init(id: String, date: String, weather: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), title: String? = nil, items: [TimelineItem] = [], tags: [EntryCategory] = []) {
        self.id = id
        self.date = date
        self.weather = weather
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.items = items
        self.tags = tags
    }
    
    /// 辅助方法：重新计算 Tags
    public mutating func regenerateTags() {
        var newTags: Set<EntryCategory> = []
        for item in items {
            let entries: [JournalEntry]
            switch item {
            case .scene(let s): entries = s.entries
            case .journey(let j): entries = j.entries
            }
            for entry in entries {
                if let cat = entry.category {
                    newTags.insert(cat)
                }
            }
        }
        self.tags = Array(newTags)
    }
}
