import SwiftUI
import Combine

public final class InsightViewModel: ObservableObject {
    // Zone 1: Overview Stats (Always displayed)
    @Published public private(set) var overview: OverviewStats = OverviewStats(streak: 0, totalDays: 0, totalEntries: 0, totalWords: 0)
    
    // Zone 2: Feature Usage Stats (Conditional display)
    @Published public private(set) var featureUsage: FeatureUsageStats = FeatureUsageStats()
    @Published public private(set) var showZone2: Bool = false
    
    // Zone 3: Data Insight Stats (Conditional display based on thresholds)
    @Published public private(set) var dataInsight: DataInsightStats = DataInsightStats(
        hourDistribution: [],
        activityDistribution: [:],
        moodTrend: [],
        topLocations: [],
        loveSources: []
    )
    @Published public private(set) var showHourChart: Bool = false
    @Published public private(set) var showActivityChart: Bool = false
    @Published public private(set) var showMoodChart: Bool = false
    @Published public private(set) var showLocationRank: Bool = false
    @Published public private(set) var showLoveRank: Bool = false
    @Published public private(set) var showZone3: Bool = false
    
    // Loading state
    @Published public private(set) var isLoading: Bool = false
    
    // Visibility Thresholds
    private let hourChartThreshold = 10      // ≥10 entries
    private let activityChartThreshold = 5   // ≥5 tracker days
    private let moodChartThreshold = 7       // ≥7 mind records
    private let locationRankThreshold = 3    // ≥3 locations
    private let loveRankThreshold = 3        // ≥3 love logs
    
    // Notification subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Legacy properties (to be refactored in later tasks)
    @Published public private(set) var hourCounts: [Int] = Array(repeating: 0, count: 24)
    @Published public private(set) var chartItemsMood: [RingChartItem] = []
    @Published public private(set) var chartItemsEnergy: [RingChartItem] = []
    @Published public private(set) var dominantLabel: String = ""
    @Published public var analysisMode: String = "mood"
    @Published public var rankingMode: String = "people"
    @Published public private(set) var peopleRanking: [(name: String, count: Int, percent: Int)] = []
    @Published public private(set) var locationRanking: [(name: String, count: Int, percent: Int)] = []
    @Published public private(set) var topCategories: [String] = []

    public init() {
        setupNotifications()
        Task { @MainActor in
            await compute()
        }
    }

    @MainActor
    public func compute() async {
        isLoading = true
        
        // Perform computation on background thread
        let computedData = await Task.detached(priority: .userInitiated) { [weak self] () -> (OverviewStats, FeatureUsageStats, DataInsightStats) in
            guard let self = self else {
                return (OverviewStats(streak: 0, totalDays: 0, totalEntries: 0, totalWords: 0), FeatureUsageStats(), DataInsightStats(hourDistribution: [], activityDistribution: [:], moodTrend: [], topLocations: [], loveSources: []))
            }
            
            // Zone 1: Compute Overview Stats with real data
            let overview = self.computeOverview()
            
            // Zone 2: Compute Feature Usage Stats
            let featureUsage = self.computeFeatureUsage()
            
            // Zone 3: Compute Data Insight Stats
            let dataInsight = self.computeDataInsight()
            
            return (overview, featureUsage, dataInsight)
        }.value
        
        // Update published properties on main thread
        overview = computedData.0
        featureUsage = computedData.1
        showZone2 = featureUsage.hasAnyData
        dataInsight = computedData.2
        updateZone3Visibility()
        
        isLoading = false
        
        // Legacy computation (to be refactored in later tasks)
        let allDates = [ChronologyAnchor.TODAY_DATE, ChronologyAnchor.YESTERDAY_DATE, ChronologyAnchor.THREE_DAYS_AGO, ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
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
        hourCounts = hourCounter
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

    // MARK: - Notification Setup
    
    private func setupNotifications() {
        // Subscribe to timeline updates
        NotificationCenter.default.publisher(for: Notification.Name("gj_timeline_updated"))
            .sink { [weak self] _ in
                Task { await self?.compute() }
            }
            .store(in: &cancellables)
        
        // Subscribe to AI conversation updates
        NotificationCenter.default.publisher(for: Notification.Name("gj_ai_conversation_updated"))
            .sink { [weak self] _ in
                Task { await self?.compute() }
            }
            .store(in: &cancellables)
        
        // Subscribe to daily tracker updates
        NotificationCenter.default.publisher(for: Notification.Name("gj_tracker_updated"))
            .sink { [weak self] _ in
                Task { await self?.compute() }
            }
            .store(in: &cancellables)
        
        // Subscribe to love log updates
        NotificationCenter.default.publisher(for: LoveLogRepository.logsUpdatedNotification)
            .sink { [weak self] _ in
                Task { await self?.compute() }
            }
            .store(in: &cancellables)
        
        // Subscribe to relationship updates
        NotificationCenter.default.publisher(for: Notification.Name("gj_relationships_updated"))
            .sink { [weak self] _ in
                Task { await self?.compute() }
            }
            .store(in: &cancellables)
        
        // Note: MindStateRepository and QuestionRepository don't currently post notifications
        // If they are updated in the future to post notifications, add subscriptions here
    }
    
    // MARK: - Zone 1: Overview Computation
    
    nonisolated private func computeOverview() -> OverviewStats {
        let streak = computeStreak()
        let totalDays = computeTotalDays()
        let totalEntries = computeTotalEntries()
        let totalWords = computeTotalWords()
        
        return OverviewStats(
            streak: streak,
            totalDays: totalDays,
            totalEntries: totalEntries,
            totalWords: totalWords
        )
    }
    
    /// Compute consecutive days from today backward with at least one entry
    nonisolated private func computeStreak() -> Int {
        var streak = 0
        var currentDate = DateUtilities.today
        
        while true {
            let timeline = TimelineRepository.shared.getDailyTimeline(for: currentDate)
            let entryCount = countEntries(in: timeline)
            
            if entryCount > 0 {
                streak += 1
                // Move to previous day
                if let date = DateUtilities.parse(currentDate),
                   let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) {
                    currentDate = DateUtilities.format(previousDate)
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Count total days with at least one entry
    nonisolated private func computeTotalDays() -> Int {
        let allTimelines = TimelineRepository.shared.getAllTimelines()
        var daysWithEntries = 0
        
        for timeline in allTimelines {
            let entryCount = countEntries(in: timeline)
            if entryCount > 0 {
                daysWithEntries += 1
            }
        }
        
        return daysWithEntries
    }
    
    /// Count total number of journal entries across all days
    nonisolated private func computeTotalEntries() -> Int {
        let allTimelines = TimelineRepository.shared.getAllTimelines()
        var totalEntries = 0
        
        for timeline in allTimelines {
            totalEntries += countEntries(in: timeline)
        }
        
        return totalEntries
    }
    
    /// Sum all words (character count) from all journal entries
    nonisolated private func computeTotalWords() -> Int {
        let allTimelines = TimelineRepository.shared.getAllTimelines()
        var totalWords = 0
        
        for timeline in allTimelines {
            for item in timeline.items {
                let entries: [JournalEntry]
                switch item {
                case .scene(let s):
                    entries = s.entries
                case .journey(let j):
                    entries = j.entries
                }
                
                for entry in entries {
                    if let content = entry.content {
                        totalWords += content.count
                    }
                }
            }
        }
        
        return totalWords
    }
    
    /// Helper: Count entries in a timeline
    nonisolated private func countEntries(in timeline: DailyTimeline) -> Int {
        var count = 0
        for item in timeline.items {
            switch item {
            case .scene(let s):
                count += s.entries.count
            case .journey(let j):
                count += j.entries.count
            }
        }
        return count
    }
    
    // MARK: - Zone 2: Feature Usage Computation
    
    nonisolated private func computeFeatureUsage() -> FeatureUsageStats {
        let aiStats = computeAIStats()
        let trackerDays = computeTrackerDays()
        let mindRecords = computeMindRecords()
        let capsuleStats = computeCapsuleStats()
        let loveLogCount = computeLoveLogCount()
        let relationshipCount = computeRelationshipCount()
        
        return FeatureUsageStats(
            aiConversations: aiStats.conversations,
            aiMessages: aiStats.messages,
            trackerDays: trackerDays,
            mindRecords: mindRecords,
            capsuleTotal: capsuleStats.total,
            capsulePending: capsuleStats.pending,
            loveLogCount: loveLogCount,
            relationshipCount: relationshipCount
        )
    }
    
    /// Compute AI conversation and message counts
    nonisolated private func computeAIStats() -> (conversations: Int, messages: Int) {
        let conversations = AIConversationRepository.shared.loadAll()
        let conversationCount = conversations.count
        
        var messageCount = 0
        for conversation in conversations {
            messageCount += conversation.messages.count
        }
        
        return (conversations: conversationCount, messages: messageCount)
    }
    
    /// Compute days with DailyTrackerRecord
    nonisolated private func computeTrackerDays() -> Int {
        let records = DailyTrackerRepository.shared.loadAll()
        // Count unique dates
        let uniqueDates = Set(records.map { $0.date })
        return uniqueDates.count
    }
    
    /// Compute total MindStateRecord count
    nonisolated private func computeMindRecords() -> Int {
        let records = MindStateRepository().loadAll()
        return records.count
    }
    
    /// Compute capsule total and pending counts
    nonisolated private func computeCapsuleStats() -> (total: Int, pending: Int) {
        let questions = QuestionRepository.shared.getAll()
        let total = questions.count
        
        // Count pending capsules (delivery_date > today)
        let today = DateUtilities.today
        var pending = 0
        
        for question in questions {
            // Compare delivery_date with today
            // Format is "yyyy.MM.dd"
            if question.delivery_date > today {
                pending += 1
            }
        }
        
        return (total: total, pending: pending)
    }
    
    /// Compute LoveLog count
    nonisolated private func computeLoveLogCount() -> Int {
        return LoveLogRepository.shared.getCount()
    }
    
    /// Compute NarrativeRelationship count
    nonisolated private func computeRelationshipCount() -> Int {
        let relationships = NarrativeRelationshipRepository.shared.loadAll()
        return relationships.count
    }
    
    // MARK: - Zone 3: Data Insight Computation
    
    nonisolated private func computeDataInsight() -> DataInsightStats {
        let hourDistribution = computeHourDistribution()
        let activityDistribution = computeActivityDistribution()
        let moodTrend = computeMoodTrend()
        let topLocations = computeTopLocations()
        let loveSources = computeLoveSources()
        
        return DataInsightStats(
            hourDistribution: hourDistribution,
            activityDistribution: activityDistribution,
            moodTrend: moodTrend,
            topLocations: topLocations,
            loveSources: loveSources
        )
    }
    
    /// Compute hour distribution from JournalEntry.timestamp
    /// Returns array of 24 integers representing entry count for each hour
    nonisolated private func computeHourDistribution() -> [Int] {
        var hourCounts = Array(repeating: 0, count: 24)
        let allTimelines = TimelineRepository.shared.getAllTimelines()
        
        for timeline in allTimelines {
            for item in timeline.items {
                let entries: [JournalEntry]
                switch item {
                case .scene(let s):
                    entries = s.entries
                case .journey(let j):
                    entries = j.entries
                }
                
                for entry in entries {
                    // Parse timestamp format "HH:mm"
                    let components = entry.timestamp.split(separator: ":")
                    if let hourStr = components.first,
                       let hour = Int(hourStr),
                       (0..<24).contains(hour) {
                        hourCounts[hour] += 1
                    }
                }
            }
        }
        
        return hourCounts
    }
    
    /// Compute activity distribution from DailyTrackerRecord.activities
    /// Returns dictionary mapping activity type to count
    nonisolated private func computeActivityDistribution() -> [String: Int] {
        var activityCounts: [String: Int] = [:]
        let records = DailyTrackerRepository.shared.loadAll()
        
        for record in records {
            for activityContext in record.activities {
                let activityType = activityContext.activityType.rawValue
                activityCounts[activityType, default: 0] += 1
            }
        }
        
        return activityCounts
    }
    
    /// Compute mood trend from MindStateRecord.valenceValue (sorted by date)
    /// Returns array of tuples with date and valence value
    nonisolated private func computeMoodTrend() -> [(date: String, value: Int)] {
        let records = MindStateRepository().loadAll()
        
        // Sort by date
        let sortedRecords = records.sorted { $0.date < $1.date }
        
        // Map to (date, value) tuples
        return sortedRecords.map { (date: $0.date, value: $0.valenceValue) }
    }
    
    /// Compute top locations from Scene.location and Journey.origin/destination
    /// Returns array of tuples with location name and count, sorted by count descending
    nonisolated private func computeTopLocations() -> [(name: String, count: Int)] {
        var locationCounts: [String: Int] = [:]
        let allTimelines = TimelineRepository.shared.getAllTimelines()
        
        for timeline in allTimelines {
            for item in timeline.items {
                switch item {
                case .scene(let s):
                    // Count scene location
                    let locationName = s.location.displayText
                    locationCounts[locationName, default: 0] += 1
                    
                case .journey(let j):
                    // Count both origin and destination
                    let originName = j.origin.displayText
                    let destinationName = j.destination.displayText
                    locationCounts[originName, default: 0] += 1
                    locationCounts[destinationName, default: 0] += 1
                }
            }
        }
        
        // Sort by count descending and return top locations
        return locationCounts
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    /// Compute love sources from LoveLog.sender
    /// Returns array of tuples with sender name and count, sorted by count descending
    nonisolated private func computeLoveSources() -> [(name: String, count: Int)] {
        let logsBySender = LoveLogRepository.shared.getLogsBySender()
        
        // Convert to array of tuples and sort by count descending
        return logsBySender
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    /// Update Zone 3 visibility flags based on thresholds
    private func updateZone3Visibility() {
        // Check hour chart threshold (≥10 entries)
        let totalEntries = overview.totalEntries
        showHourChart = totalEntries >= hourChartThreshold
        
        // Check activity chart threshold (≥5 tracker days)
        showActivityChart = featureUsage.trackerDays >= activityChartThreshold
        
        // Check mood chart threshold (≥7 mind records)
        showMoodChart = featureUsage.mindRecords >= moodChartThreshold
        
        // Check location rank threshold (≥3 locations)
        showLocationRank = dataInsight.topLocations.count >= locationRankThreshold
        
        // Check love rank threshold (≥3 love logs)
        showLoveRank = featureUsage.loveLogCount >= loveRankThreshold
        
        // Show Zone 3 if any chart/rank is visible
        showZone3 = showHourChart || showActivityChart || showMoodChart || showLocationRank || showLoveRank
    }
    
    // MARK: - Legacy Helper Methods
    
    private func accumulate(entries: [JournalEntry], hourCounter: inout [Int], categoryCounter: inout [EntryCategory: Int]) {
        for e in entries {
            if let cat = e.category { categoryCounter[cat, default: 0] += 1 }
            let comps = e.timestamp.split(separator: ":")
            if let hStr = comps.first, let h = Int(hStr), (0..<24).contains(h) { hourCounter[h] += 1 }
        }
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
