import SwiftUI
import Combine

public final class InsightViewModel: ObservableObject {
    @Published public private(set) var streak: Int = 0
    @Published public private(set) var totalDays: Int = 0
    @Published public private(set) var totalEntries: Int = 0
    @Published public private(set) var hourCounts: [Int] = Array(repeating: 0, count: 24)
    @Published public private(set) var chartItemsMood: [RingChartItem] = []
    @Published public private(set) var chartItemsEnergy: [RingChartItem] = []
    @Published public private(set) var dominantLabel: String = ""
    @Published public var analysisMode: String = "mood"
    @Published public var rankingMode: String = "people"
    @Published public private(set) var peopleRanking: [(name: String, count: Int, percent: Int)] = []
    @Published public private(set) var locationRanking: [(name: String, count: Int, percent: Int)] = []
    @Published public private(set) var topCategories: [String] = []

    public init() { compute() }

    public func compute() {
        let allDates = [ChronologyAnchor.TODAY_DATE, ChronologyAnchor.YESTERDAY_DATE, ChronologyAnchor.THREE_DAYS_AGO, ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
        // Total days & entries
        totalDays = allDates.count
        var entriesCount = 0
        var categoryCounter: [EntryCategory: Int] = [:]
        var peopleCounts: [String: Int] = [:]
        var locationCounts: [String: Int] = [:]
        var hourCounter = Array(repeating: 0, count: 24)
        for d in allDates {
            for item in MockDataService.getTimeline(for: d) {
                switch item {
                case .scene(let s):
                    entriesCount += s.entries.count
                    accumulate(entries: s.entries, hourCounter: &hourCounter, categoryCounter: &categoryCounter)
                    locationCounts[s.location.displayText, default: 0] += 1
                case .journey(let j):
                    entriesCount += j.entries.count
                    accumulate(entries: j.entries, hourCounter: &hourCounter, categoryCounter: &categoryCounter)
                    let locName = "\(j.origin.displayText) -> \(j.destination.displayText)"
                    locationCounts[locName, default: 0] += 1
                }
            }
        }
        totalEntries = entriesCount
        hourCounts = hourCounter
        // Streak: consecutive days ending today with at least one entry
        streak = computeStreak(dates: [ChronologyAnchor.TODAY_DATE, ChronologyAnchor.YESTERDAY_DATE, ChronologyAnchor.THREE_DAYS_AGO])
        // Mood chart: map categories to buckets
        chartItemsMood = buildMoodChart(from: categoryCounter)
        chartItemsEnergy = buildEnergyChart(from: categoryCounter)
        dominantLabel = dominantLabelFrom(chartItemsMood)
        // People scanning keywords
        let keywords = ["Mom", "妈妈", "Sarah", "Alex", "老友"]
        scanPeopleCounts(from: categoryCounter, peopleCounts: &peopleCounts, keywords: keywords)
        // Build rankings
        peopleRanking = buildRanking(from: peopleCounts)
        locationRanking = buildRanking(from: locationCounts)
        // Top categories keywords
        topCategories = topCategoryLabels(from: categoryCounter)
    }

    private func accumulate(entries: [JournalEntry], hourCounter: inout [Int], categoryCounter: inout [EntryCategory: Int]) {
        for e in entries {
            if let cat = e.category { categoryCounter[cat, default: 0] += 1 }
            let comps = e.timestamp.split(separator: ":")
            if let hStr = comps.first, let h = Int(hStr), (0..<24).contains(h) { hourCounter[h] += 1 }
        }
    }

    private func computeStreak(dates: [String]) -> Int {
        var s = 0
        for d in dates {
            let timeline = TimelineRepository.shared.getDailyTimeline(for: d)
            let items = timeline.items
            let count = items.reduce(0) { acc, item in
                switch item { case .scene(let s): return acc + s.entries.count; case .journey(let j): return acc + j.entries.count }
            }
            if count > 0 { s += 1 } else { break }
        }
        return s
    }

    private func buildMoodChart(from counter: [EntryCategory: Int]) -> [RingChartItem] {
        let total = max(1, counter.values.reduce(0, +))
        func item(_ value: Int, _ color: Color) -> RingChartItem { RingChartItem(value: Double(value) / Double(total) * 100.0, color: color) }
        return [
            item(counter[.dream] ?? 0, .blue),
            item(counter[.emotion] ?? 0, .orange),
            item(counter[.health] ?? 0, .green),
            item(counter[.work] ?? 0, .gray)
        ].filter { $0.value > 0 }
    }

    private func buildEnergyChart(from counter: [EntryCategory: Int]) -> [RingChartItem] {
        let total = max(1, counter.values.reduce(0, +))
        func value(_ v: Int) -> Double { Double(v) / Double(total) * 100.0 }
        let high = (counter[.work] ?? 0) + (counter[.social] ?? 0)
        let low = (counter[.dream] ?? 0) + (counter[.media] ?? 0)
        let flow = (counter[.health] ?? 0) + (counter[.emotion] ?? 0)
        return [
            RingChartItem(value: value(high), color: .red),
            RingChartItem(value: value(low), color: .green),
            RingChartItem(value: value(flow), color: .blue)
        ].filter { $0.value > 0 }
    }

    private func dominantLabelFrom(_ items: [RingChartItem]) -> String {
        guard let maxItem = items.max(by: { $0.value < $1.value }) else { return NSLocalizedString("other", comment: "") }
        // Map color back to label roughly
        switch maxItem.color {
            case .blue: return NSLocalizedString("calm", comment: "")
            case .orange: return NSLocalizedString("happy", comment: "")
            case .green: return NSLocalizedString("high", comment: "")
            case .gray: return NSLocalizedString("low", comment: "")
            default: return NSLocalizedString("other", comment: "")
        }
    }

    private func scanPeopleCounts(from counter: [EntryCategory: Int], peopleCounts: inout [String: Int], keywords: [String]) {
        let allDates = [ChronologyAnchor.TODAY_DATE, ChronologyAnchor.YESTERDAY_DATE, ChronologyAnchor.THREE_DAYS_AGO, ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
        for d in allDates {
            let timeline = TimelineRepository.shared.getDailyTimeline(for: d)
            for item in timeline.items {
                let entries: [JournalEntry]
                switch item { case .scene(let s): entries = s.entries; case .journey(let j): entries = j.entries }
                for e in entries {
                    let content = e.content ?? ""
                    for k in keywords { if content.contains(k) { peopleCounts[k, default: 0] += 1 } }
                }
            }
        }
        // Mock loveLogs usage removed for now as we don't have repo for it yet
        // for (_, log) in ["love": MockDataService.loveLogs].enumerated() {
        //    for l in log.value { let name = (l.sender == "Me") ? l.receiver : l.sender; peopleCounts[name, default: 0] += 1 }
        // }
    }

    private func buildRanking(from counts: [String: Int]) -> [(name: String, count: Int, percent: Int)] {
        let maxVal = max(1, counts.values.max() ?? 1)
        return counts.map { (k, v) in (name: k, count: v, percent: Int(round(Double(v) / Double(maxVal) * 100))) }
            .sorted { $0.count > $1.count }
    }

    private func topCategoryLabels(from counter: [EntryCategory: Int]) -> [String] {
        let sorted = counter.sorted { $0.value > $1.value }.prefix(5)
        return sorted.map { Icons.categoryLabel($0.key) }
    }
}
