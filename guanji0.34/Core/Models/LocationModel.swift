import Foundation

public struct AddressMapping: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let name: String
    public let icon: String?
    public let color: String?
}

public struct AddressFence: Codable, Identifiable {
    public let id: String
    public let mappingId: String
    public let lat: Double
    public let lng: Double
    public let radius: Double
    public let originalRawName: String
}

public enum LocationStatus: String, Codable {
    case no_permission
    case raw
    case mapped
}

public struct LocationSnapshot: Codable, Equatable {
    public let lat: Double
    public let lng: Double
}

public struct LocationVO: Codable, Equatable {
    public let status: LocationStatus
    public let mappingId: String?
    public let snapshot: LocationSnapshot
    public let displayText: String
    public let originalRawName: String?
    public let icon: String?
    public let color: String?
}

public enum TransportMode: String, Codable {
    case car
    case walk
    case subway
    case bicycle
}

public struct SceneGroup: Codable, Identifiable {
    public let type: String
    public let id: String
    public let timeRange: String
    public let location: LocationVO
    public let entries: [JournalEntry]
}

public struct JourneyBlock: Codable, Identifiable {
    public let type: String
    public let id: String
    public let origin: LocationVO
    public let destination: LocationVO
    public let mode: TransportMode
    public let entries: [JournalEntry]
}

public enum TimelineItem: Codable, Identifiable {
    case scene(SceneGroup)
    case journey(JourneyBlock)

    public var id: String {
        switch self {
        case .scene(let s): return s.id
        case .journey(let j): return j.id
        }
    }
}

/// Combined display item for timeline - includes both journal entries and AI conversations
/// Used for rendering timeline with AI conversations interspersed by time
public enum TimelineDisplayItem: Identifiable {
    case timelineItem(TimelineItem)
    case aiConversation(AIConversation)
    
    public var id: String {
        switch self {
        case .timelineItem(let item): return item.id
        case .aiConversation(let conv): return "ai_\(conv.id)"
        }
    }
    
    /// Get the timestamp for sorting - uses first entry time or conversation creation time
    /// For timeline items, we only compare the time portion (HH:mm) since all items
    /// in a day's timeline belong to the same day
    public var sortTimestamp: Date {
        switch self {
        case .timelineItem(let item):
            switch item {
            case .scene(let s):
                // Parse timeRange (format: "HH:mm") - use first entry's timestamp
                if let firstEntry = s.entries.first {
                    return parseTimeToMinutes(firstEntry.timestamp)
                }
                return parseTimeToMinutes(s.timeRange)
            case .journey(let j):
                return parseTimeToMinutes(j.entries.first?.timestamp ?? "")
            }
        case .aiConversation(let conv):
            // Extract only the time portion for fair comparison with timeline items
            return extractTimeOnly(from: conv.createdAt)
        }
    }
    
    /// Parse time string (HH:mm) to a reference Date for sorting
    /// Uses a fixed reference date (2000-01-01) to ensure consistent sorting
    private func parseTimeToMinutes(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return Date.distantPast }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Use a fixed reference date for consistent sorting
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? Date.distantPast
    }
    
    /// Extract only the time portion from a Date for fair comparison
    private func extractTimeOnly(from date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        
        // Use the same fixed reference date as parseTimeToMinutes
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? Date.distantPast
    }
}
