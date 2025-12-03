import ActivityKit

public struct DateWeatherAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var dateText: String
        public var symbolName: String
        public init(dateText: String, symbolName: String) {
            self.dateText = dateText
            self.symbolName = symbolName
        }
    }
    public init() {}
}

