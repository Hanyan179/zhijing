import SwiftUI

public struct BasicComponentsSection: View {
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("basicComponents"))
            
            // Standard System Buttons
            ShowcaseItem(label: "Native Buttons") {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button("Plain") {}
                        
                        Button("Bordered") {}
                            .buttonStyle(.bordered)
                        
                        Button("Prominent") {}
                            .buttonStyle(.borderedProminent)
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Label("Icon", systemImage: "star.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {}) {
                            Image(systemName: "heart.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
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
            ShowcaseItem(label: Localization.tr("componentMoleculeSealed")) { MoleculeSealed(date: ChronologyAnchor.TODAY_DATE, daysLeft: 365, lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("componentMoleculeConnection")) { MoleculeConnection(sender: "Mom", timestamp: "20:00", message: Localization.tr("connectionMessage", lang: appState.lang), lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("componentMoleculeReview")) {
                MoleculeReview(reviewDate: ChronologyAnchor.YESTERDAY_DATE, onJump: {}, lang: appState.lang) { Text("Yesterday's context...") }
            }
            if let ach = MockDataService.achievements.values.first { ShowcaseItem(label: Localization.tr("componentAchievementCard")) { AchievementCard(achievement: ach) } }
            ShowcaseItem(label: Localization.tr("onThisDay")) { ResonanceHub(stats: sampleResonanceStats()) }
        }
    }

    private func sampleResonanceStats() -> [ResonanceDateStat] {
        let todayYear = Int(ChronologyAnchor.TODAY_DATE.prefix(4)) ?? 0
        let targets = [ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
        var stats: [ResonanceDateStat] = []
        for d in targets {
            let year = Int(d.prefix(4)) ?? 0
            let items = MockDataService.getTimeline(for: d)
            var originals = 0
            var images = 0
            for item in items {
                switch item {
                case .scene(let s):
                    originals += s.entries.count
                    images += s.entries.filter { $0.type == .image }.count
                case .journey(let j):
                    originals += j.entries.count
                    images += j.entries.filter { $0.type == .image }.count
                }
            }
            var echoes = 0
            for (_, its) in MockDataService.timeline {
                for it in its {
                    switch it {
                    case .scene(let s): echoes += s.entries.filter { ($0.metadata?.reviewDate ?? "") == d }.count
                    case .journey(let j): echoes += j.entries.filter { ($0.metadata?.reviewDate ?? "") == d }.count
                    }
                }
            }
            let loveLogs = MockDataService.loveLogs.filter { $0.mentionTime == d }.count
            let capsules = MockDataService.questions.filter { $0.created_at == d }.count
            var title: String? = nil
            if let hit = MockDataService.achievements.values.first(where: { $0.lastUpdatedAt == d }) {
                let lang = appState.lang
                title = (lang == .zh ? hit.aiGeneratedTitle?.zh : hit.aiGeneratedTitle?.en)
            }
            let stat = ResonanceDateStat(date: d, year: year, title: title, originalCount: originals, imageCount: images, echoesCount: echoes, loveLogsCount: loveLogs, capsulesCount: capsules, todayYear: todayYear)
            if originals > 0 || echoes > 0 || loveLogs > 0 || capsules > 0 { stats.append(stat) }
        }
        return stats
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
                InputQuickActions(onGallery: {}, onCamera: {}, onRecord: {}, onTimeCapsule: {}, onMood: {}, onFile: {}, onMore: {})
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
    // We need a dummy TimelineViewModel for CapsuleDetailSheet previews
    private let dummyTimelineVM = TimelineViewModel()
    
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("statusComponents"))
            ShowcaseItem(label: Localization.tr("capsuleSealed")) { MoleculeSealed(date: ChronologyAnchor.TODAY_DATE, daysLeft: 120, prompt: Localization.tr("writeToFuture", lang: appState.lang), lang: appState.lang) }
            ShowcaseItem(label: Localization.tr("capsuleCreated")) {
                let q = MockDataService.questions.first!
                CapsuleCard(question: q, sourceEntry: MockDataService.getJournalEntry(id: q.journal_now_id), replies: [], onInitiateReply: {}, lang: appState.lang)
                    .environmentObject(dummyTimelineVM)
            }
            ShowcaseItem(label: Localization.tr("capsuleOpened")) {
                let q = MockDataService.questions.first!
                let src = MockDataService.getJournalEntry(id: q.journal_now_id)
                let replies = sampleReplies(for: q.id)
                CapsuleCard(question: q, sourceEntry: src, replies: replies, onInitiateReply: {}, lang: appState.lang)
                    .environmentObject(dummyTimelineVM)
            }
            ShowcaseItem(label: Localization.tr("capsuleReplyContinue")) {
                let q = MockDataService.questions.first!
                CapsuleCard(question: q, sourceEntry: MockDataService.getJournalEntry(id: q.journal_now_id), replies: sampleReplies(for: q.id), onInitiateReply: {}, lang: appState.lang)
                    .environmentObject(dummyTimelineVM)
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
