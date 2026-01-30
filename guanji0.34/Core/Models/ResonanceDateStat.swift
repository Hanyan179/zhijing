import Foundation

public struct ResonanceDateStat: Identifiable, Codable {
    public var id: String { date }
    public let date: String
    public let year: Int
    public let title: String?
    public let originalCount: Int
    public let imageCount: Int
    public let echoesCount: Int
    public let loveLogsCount: Int
    public let capsulesCount: Int
    public var yearsAgo: Int { max(0, todayYear - year) }
    private let todayYear: Int
    public init(date: String, year: Int, title: String?, originalCount: Int, imageCount: Int, echoesCount: Int, loveLogsCount: Int, capsulesCount: Int, todayYear: Int) {
        self.date = date
        self.year = year
        self.title = title
        self.originalCount = originalCount
        self.imageCount = imageCount
        self.echoesCount = echoesCount
        self.loveLogsCount = loveLogsCount
        self.capsulesCount = capsulesCount
        self.todayYear = todayYear
    }
}
