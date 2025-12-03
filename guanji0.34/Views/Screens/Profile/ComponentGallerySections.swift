import SwiftUI

public struct BasicComponentsSection: View {
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("basicComponents"))
            ShowcaseItem(label: Localization.tr("componentAtomHeader")) { AtomHeader(category: .emotion, lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("componentAtomTimestamp")) { AtomTimestamp(timestamp: "12:34") }
            ShowcaseItem(label: Localization.tr("componentAtomContextReply")) { AtomContextReply(text: Localization.tr("replyingTo", lang: appState.lang)) }
            // LocationBadge states
            ShowcaseItem(label: NSLocalizedString("componentLocationBadgeMapped", comment: "")) {
                LocationBadge(location: LocationVO(status: .mapped, mappingId: "map_home", snapshot: LocationSnapshot(lat: 31.22, lng: 121.44), displayText: "Home / 静安", originalRawName: "Yanping Road 123", icon: "home", color: "indigo"))
            }
            ShowcaseItem(label: NSLocalizedString("componentLocationBadgeRaw", comment: "")) {
                LocationBadge(location: LocationVO(status: .raw, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "Yanping Road 123", originalRawName: "Yanping Road 123", icon: nil, color: nil))
            }
            ShowcaseItem(label: NSLocalizedString("componentLocationBadgeNoPermission", comment: "")) {
                LocationBadge(location: LocationVO(status: .no_permission, mappingId: nil, snapshot: LocationSnapshot(lat: 0, lng: 0), displayText: "-", originalRawName: nil, icon: nil, color: nil))
            }
        }
    }
}

public struct CompositeComponentsSection: View {
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("compositeComponents"))
            ShowcaseItem(label: Localization.tr("componentMoleculeSealed")) { MoleculeSealed(date: ChronologyAnchor.TODAY_DATE, daysLeft: 365, prompt: Localization.tr("writeToFuture", lang: appState.lang), lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("componentMoleculeConnection")) { MoleculeConnection(sender: "Mom", timestamp: "20:00", message: Localization.tr("connectionMessage", lang: appState.lang), lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("componentMoleculeReview")) {
                MoleculeReview(reviewDate: ChronologyAnchor.YESTERDAY_DATE, onJump: {}, lang: appState.lang) { Text("Yesterday's context...") }
            }
            if let ach = MockDataService.achievements.values.first { ShowcaseItem(label: Localization.tr("componentAchievementCard")) { AchievementCard(achievement: ach) } }
            ShowcaseItem(label: Localization.tr("onThisDay")) { ResonanceHub(entries: sampleOnThisDay(), todayDate: ChronologyAnchor.TODAY_DATE) }
        }
    }

    private func sampleOnThisDay() -> [JournalEntry] {
        var result: [JournalEntry] = []
        for d in [ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE] {
            for item in MockDataService.getTimeline(for: d) {
                switch item { case .scene(let s): result.append(contentsOf: s.entries); case .journey(let j): result.append(contentsOf: j.entries) }
            }
        }
        return result
    }
}

public struct LayoutComponentsSection: View {
    @EnvironmentObject private var appState: AppState
    private let items = MockDataService.getTimeline(for: ChronologyAnchor.TODAY_DATE)
    private var sampleScene: SceneGroup? {
        for item in items { if case .scene(let s) = item { return s } }
        return nil
    }
    private var sampleJourney: JourneyBlock? {
        for item in items { if case .journey(let j) = item { return j } }
        return nil
    }
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("layoutComponents"))
            if let s = sampleScene {
                ShowcaseItem(label: Localization.tr("componentSceneBlock")) { SceneBlock(scene: s, questionEntries: MockDataService.questions, currentDateLabel: ChronologyAnchor.TODAY_DATE, todayDate: ChronologyAnchor.TODAY_DATE) }
            }
            if let j = sampleJourney {
                ShowcaseItem(label: Localization.tr("componentJourneyBlockView")) { JourneyBlockView(journey: j, questionEntries: MockDataService.questions, currentDateLabel: ChronologyAnchor.TODAY_DATE, todayDate: ChronologyAnchor.TODAY_DATE) }
            }
            if let e = sampleScene?.entries.first {
                ShowcaseItem(label: Localization.tr("componentJournalRow")) { JournalRow(entry: e, questionEntries: MockDataService.questions, currentDateLabel: ChronologyAnchor.TODAY_DATE, todayDate: ChronologyAnchor.TODAY_DATE, lang: appState.lang) }
            }
        }
    }
}

public struct InputsGallerySection: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("inputs"))
            ShowcaseItem(label: Localization.tr("componentInputQuickActions")) {
                InputQuickActions(onGallery: {}, onCamera: {}, onRecord: {}, onTimeCapsule: {}, onMood: {})
                    .padding(.horizontal, 16)
            }
            ShowcaseItem(label: Localization.tr("componentDockContainer")) {
                DockContainer(isMenuOpen: false, isReplyMode: false) {
                    TextField(Localization.tr("placeholder"), text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                    SubmitButton(hasText: true, onClick: {})
                }
            }
            ShowcaseItem(label: Localization.tr("componentRecordingBar")) { RecordingBar(isRecording: false, duration: 15, onStart: {}, onStop: {}, onCancel: {}) }
        }
    }
}

public struct ChartsGallerySection: View {
    private var ringItems: [RingChartItem] { [RingChartItem(value: 40, color: .blue), RingChartItem(value: 30, color: .orange), RingChartItem(value: 20, color: .green)] }
    private var hourCounts: [Int] { (0..<24).map { i in Int(max(0, (sin(Double(i) * 0.3) + 1.0) * 5)) } }
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("charts"))
            ShowcaseItem(label: Localization.tr("componentOverviewCard")) { OverviewCard(streak: 3, totalDays: 10, totalEntries: 24) }
            ShowcaseItem(label: Localization.tr("componentRingChart")) { RingChart(items: ringItems, dominantLabel: Localization.tr("happy")) }
            ShowcaseItem(label: Localization.tr("componentHeatmapGrid")) { HeatmapGrid(hourCounts: hourCounts) }
        }
    }
}

public struct MediaGallerySection: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("media"))
            ShowcaseItem(label: Localization.tr("componentImageEntry")) { ImageEntry(src: "https://images.unsplash.com/photo-1517701604599-bb29b5dd73ad?q=80&w=1000&auto=format&fit=crop") }
            ShowcaseItem(label: Localization.tr("componentAudioEntry")) { AudioEntry(duration: "00:15", content: Localization.tr("voice")) }
        }
    }
}

public struct ListsGallerySection: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("lists"))
            ShowcaseItem(label: Localization.tr("componentListRow")) { ListRow(iconName: "gear", label: Localization.tr("system")) }
            ShowcaseItem(label: Localization.tr("componentToggleSwitch")) { ToggleSwitch(checked: .constant(true)) }
        }
    }
}
public struct StatusComponentsSection: View {
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("statusComponents"))
            ShowcaseItem(label: Localization.tr("capsuleSealed")) { MoleculeSealed(date: ChronologyAnchor.TODAY_DATE, daysLeft: 120, prompt: Localization.tr("writeToFuture", lang: appState.lang), lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("capsuleCreated")) {
                let q = MockDataService.questions.first!
                CapsuleCard(question: q, sourceEntry: MockDataService.getJournalEntry(id: q.journal_now_id), replies: [], onInitiateReply: {}, lang: appState.lang)
            }
            ShowcaseItem(label: Localization.tr("capsuleOpened")) {
                let q = MockDataService.questions.first!
                let src = MockDataService.getJournalEntry(id: q.journal_now_id)
                let replies = sampleReplies(for: q.id)
                CapsuleCard(question: q, sourceEntry: src, replies: replies, onInitiateReply: {}, lang: appState.lang)
            }
            ShowcaseItem(label: Localization.tr("capsuleReplyContinue")) {
                let q = MockDataService.questions.first!
                CapsuleCard(question: q, sourceEntry: MockDataService.getJournalEntry(id: q.journal_now_id), replies: sampleReplies(for: q.id), onInitiateReply: {}, lang: appState.lang)
            }
        }
    }

    private func sampleReplies(for questionId: String) -> [JournalEntry] {
        let all = [ChronologyAnchor.TODAY_DATE]
        var acc: [JournalEntry] = []
        for d in all {
            for item in MockDataService.getTimeline(for: d) {
                switch item { case .scene(let s): acc.append(contentsOf: s.entries); case .journey(let j): acc.append(contentsOf: j.entries) }
            }
        }
        return acc.filter { $0.metadata?.questionId == questionId || ($0.category == .emotion) }.prefix(2).map { $0 }
    }
}
