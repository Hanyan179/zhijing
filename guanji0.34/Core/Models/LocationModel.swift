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
    public let duration: String
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
