import SwiftUI
import Combine

public final class TimelineViewModel: ObservableObject {
    @Published public private(set) var items: [TimelineItem] = []
    @Published public var currentDate: String = ChronologyAnchor.TODAY_DATE
    @Published public var todayDataLoaded: Bool = false
    @Published public private(set) var onThisDay: [JournalEntry] = []

    public init() { load(date: currentDate) }

    public func load(date: String) {
        currentDate = date
        items = MockDataService.getTimeline(for: date)
        if date == ChronologyAnchor.TODAY_DATE { todayDataLoaded = true }
        computeOnThisDay()
    }

    public func handleTodaySubmit(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let entry = JournalEntry(id: UUID().uuidString, type: .text, subType: nil, chronology: .present, content: text, url: nil, timestamp: "\(DateFormatter.hourMinute.string(from: Date()))", category: .idea, metadata: nil)
        if let idx = items.firstIndex(where: { if case .scene(let s) = $0 { return s.id == "scene_today_work" } else { return false } }) {
            if case .scene(var s) = items[idx] { s = SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: s.entries + [entry]); items[idx] = .scene(s) }
        }
    }

    public func handleReply(questionId: String, replyText: String) {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let entry = JournalEntry(id: UUID().uuidString, type: .text, subType: nil, chronology: .present, content: replyText, url: nil, timestamp: "\(DateFormatter.hourMinute.string(from: Date()))", category: .emotion, metadata: JournalEntry.Metadata(blocks: nil, reviewDate: nil, createdDate: currentDate, questionId: questionId, duration: nil, sender: nil))
        if let idx = items.firstIndex(where: { if case .scene(let s) = $0 { return s.id == "scene_today_work" } else { return false } }) {
            if case .scene(var s) = items[idx] { s = SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: s.entries + [entry]); items[idx] = .scene(s) }
        }
    }

    public func createCapsule(mode: String, prompt: String, deliveryDate: Date, sealed: Bool) {
        let type: EntryType = {
            switch mode {
            case "image": return .image
            case "audio": return .audio
            default: return .text
            }
        }()
        let id = "capsule_" + UUID().uuidString
        let ts = DateFormatter.hourMinute.string(from: Date())
        let entry = JournalEntry(id: id,
                                 type: type,
                                 subType: sealed ? nil : .pending_question,
                                 chronology: .future,
                                 content: prompt.isEmpty ? nil : prompt,
                                 url: nil,
                                 timestamp: ts,
                                 category: .idea,
                                 metadata: JournalEntry.Metadata(blocks: nil,
                                                                reviewDate: nil,
                                                                createdDate: currentDate,
                                                                questionId: nil,
                                                                duration: nil,
                                                                sender: nil))
        if let idx = items.firstIndex(where: { if case .scene = $0 { return true } else { return false } }) {
            if case .scene(let s) = items[idx] {
                let newScene = SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: s.entries + [entry])
                items[idx] = .scene(newScene)
            }
        } else if let idx = items.firstIndex(where: { if case .journey = $0 { return true } else { return false } }) {
            if case .journey(let j) = items[idx] {
                let newJourney = JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, duration: j.duration, entries: j.entries + [entry])
                items[idx] = .journey(newJourney)
            }
        } else {
            let loc = MockDataService.buildLocation(rawName: "Yanping Road 123", lat: 31.2288, lng: 121.4450)
            let newScene = SceneGroup(type: "scene", id: "scene_\(UUID().uuidString)", timeRange: ts, location: loc, entries: [entry])
            items.append(.scene(newScene))
        }
    }

    private func computeOnThisDay() {
        var result: [JournalEntry] = []
        for d in [ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE] {
            for item in MockDataService.getTimeline(for: d) {
                switch item {
                case .scene(let s): result.append(contentsOf: s.entries)
                case .journey(let j): result.append(contentsOf: j.entries)
                }
            }
        }
        onThisDay = result
    }

    public func tagEntry(id: String, category: EntryCategory) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let updated = s.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: e.content, url: e.url, timestamp: e.timestamp, category: category, metadata: e.metadata) : e }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: updated))
            case .journey(let j):
                let updated = j.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: e.content, url: e.url, timestamp: e.timestamp, category: category, metadata: e.metadata) : e }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, duration: j.duration, entries: updated))
            }
        }
    }

    public func editEntryContent(id: String, newContent: String) {
        items = items.map { item in
            switch item {
            case .scene(let s):
                let updated = s.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: newContent, url: e.url, timestamp: e.timestamp, category: e.category, metadata: e.metadata) : e }
                return .scene(SceneGroup(type: s.type, id: s.id, timeRange: s.timeRange, location: s.location, entries: updated))
            case .journey(let j):
                let updated = j.entries.map { e in e.id == id ? JournalEntry(id: e.id, type: e.type, subType: e.subType, chronology: e.chronology, content: newContent, url: e.url, timestamp: e.timestamp, category: e.category, metadata: e.metadata) : e }
                return .journey(JourneyBlock(type: j.type, id: j.id, origin: j.origin, destination: j.destination, mode: j.mode, duration: j.duration, entries: updated))
            }
        }
    }
}

private extension DateFormatter {
    static let hourMinute: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()
}
