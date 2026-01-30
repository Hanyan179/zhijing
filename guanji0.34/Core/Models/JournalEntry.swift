import Foundation

public enum EntryType: String, Codable {
    case text
    case image
    case video
    case audio
    case file
    case mixed
}

public enum EntrySubType: String, Codable {
    case love_received
    case pending_question
    case normal
}

public enum EntryChronology: String, Codable {
    case past
    case present
    case future
}

public enum EntryCategory: String, Codable {
    case dream
    case health
    case emotion
    case work
    case social
    case media
    case life
}

public struct ContentBlock: Codable, Identifiable {
    public let id: String
    public let type: EntryType
    public let content: String
    public let url: String?
    public let duration: String?
}

public struct JournalEntry: Codable, Identifiable {
    public let id: String
    public let type: EntryType
    public let subType: EntrySubType?
    public let chronology: EntryChronology
    public let content: String?
    public let url: String?
    public let timestamp: String
    public let category: EntryCategory?
    public let metadata: Metadata?

    public struct Metadata: Codable {
        public let blocks: [ContentBlock]?
        public let reviewDate: String?
        public let createdDate: String?
        public let questionId: String?
        public let duration: String?
        public let sender: String?
    }
}
