import Foundation

// MARK: - Daily Table
// Stores the index of items for a specific date
public struct DailyTimelineRecord: Codable {
    public let date: String
    public let itemIds: [String] // IDs of Scene/Journey
    
    public init(date: String, itemIds: [String]) {
        self.date = date
        self.itemIds = itemIds
    }
}

// MARK: - Scene Table (DTO)
// Represents a Scene or Journey without full embedded entries (only IDs)
public struct SceneRecord: Codable {
    public let id: String
    public let type: String // "scene" or "journey"
    
    // Common fields
    public let timeRange: String? // For Scene
    public let duration: String?  // For Journey
    
    // Location Data
    public let location: LocationVO? // For Scene
    public let origin: LocationVO?      // For Journey
    public let destination: LocationVO? // For Journey
    public let transportMode: TransportMode? // For Journey
    
    // References to Atom Table
    public let entryIds: [String]
    
    public init(from item: TimelineItem) {
        switch item {
        case .scene(let s):
            self.id = s.id
            self.type = "scene"
            self.timeRange = s.timeRange
            self.location = s.location
            self.entryIds = s.entries.map { $0.id }
            
            self.duration = nil
            self.origin = nil
            self.destination = nil
            self.transportMode = nil
            
        case .journey(let j):
            self.id = j.id
            self.type = "journey"
            self.duration = nil  // Duration field removed in v0.34.1
            self.origin = j.origin
            self.destination = j.destination
            self.transportMode = j.mode
            self.entryIds = j.entries.map { $0.id }
            
            self.timeRange = nil
            self.location = nil
        }
    }
    
    public func toTimelineItem(entries: [JournalEntry]) -> TimelineItem? {
        // Reconstruct the item using the provided resolved entries
        if type == "scene" {
            guard let loc = location, let tr = timeRange else { return nil }
            let s = SceneGroup(type: "scene", id: id, timeRange: tr, location: loc, entries: entries)
            return .scene(s)
        } else if type == "journey" {
            guard let org = origin, let dest = destination, let mode = transportMode else { return nil }
            let j = JourneyBlock(type: "journey", id: id, origin: org, destination: dest, mode: mode, entries: entries)
            return .journey(j)
        }
        return nil
    }
}

// MARK: - Atom Table
// Directly uses JournalEntry since it's already the atom unit
public typealias AtomRecord = JournalEntry
