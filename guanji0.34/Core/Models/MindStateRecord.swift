import Foundation

public struct MindStateRecord: Codable, Identifiable {
    public let id: String
    public let date: String  // Primary day index (format: "yyyy.MM.dd") - L1 DayIndex association
    public let valenceValue: Int
    public let labels: [String]
    public let influences: [String]
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        date: String = DateUtilities.today,
        valenceValue: Int,
        labels: [String],
        influences: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.valenceValue = valenceValue
        self.labels = labels
        self.influences = influences
        self.createdAt = createdAt
    }
    
    /// Computed property for explicit DayIndex association (alias for date)
    public var dayId: String {
        return date
    }
}
