import SwiftUI

public struct JournalRow: View {
    public let entry: JournalEntry
    public let questionEntries: [QuestionEntry]
    public let currentDateLabel: String
    public let todayDate: String
    public var resolveEntry: ((String) -> JournalEntry?)?
    public var getReplies: ((String) -> [JournalEntry])?
    public var onInitiateReply: ((String) -> Void)?
    public var onSubmitReply: ((String, String) -> Void)?
    public var onContextMenu: ((String, String, EntryType) -> Void)?
    public var onDelete: ((String) -> Void)?
    public var onJumpToDate: ((String) -> Void)?
    public let isHighlighted: Bool
    public let lang: Lang
    public var editNamespace: Namespace.ID? = nil
    public init(entry: JournalEntry, questionEntries: [QuestionEntry] = [], currentDateLabel: String, todayDate: String, resolveEntry: ((String) -> JournalEntry?)? = nil, getReplies: ((String) -> [JournalEntry])? = nil, onInitiateReply: ((String) -> Void)? = nil, onSubmitReply: ((String, String) -> Void)? = nil, onContextMenu: ((String, String, EntryType) -> Void)? = nil, onDelete: ((String) -> Void)? = nil, onJumpToDate: ((String) -> Void)? = nil, isHighlighted: Bool = false, lang: Lang, editNamespace: Namespace.ID? = nil) {
        self.entry = entry
        self.questionEntries = questionEntries
        self.currentDateLabel = currentDateLabel
        self.todayDate = todayDate
        self.resolveEntry = resolveEntry
        self.getReplies = getReplies
        self.onInitiateReply = onInitiateReply
        self.onSubmitReply = onSubmitReply
        self.onContextMenu = onContextMenu
        self.onDelete = onDelete
        self.onJumpToDate = onJumpToDate
        self.isHighlighted = isHighlighted
        self.lang = lang
        self.editNamespace = editNamespace
    }

    private var isTodayView: Bool { currentDateLabel == todayDate }

    @ViewBuilder
    public var body: some View {
        if !isTodayView && entry.chronology == .past {
            MoleculeEcho(content: entry.content ?? "", createdDate: entry.metadata?.createdDate ?? Localization.tr("futureLabel", lang: lang), lang: lang)
        } else if entry.subType == .love_received {
            MoleculeConnection(sender: entry.metadata?.sender ?? Localization.tr("someone", lang: lang), timestamp: entry.timestamp, message: Localization.tr("connectionMessage", lang: lang), isHighlighted: isHighlighted, lang: lang)
        } else if isTodayView && entry.chronology == .past {
            MoleculeReview(reviewDate: entry.metadata?.reviewDate ?? Localization.tr("past", lang: lang), isHighlighted: isHighlighted, onJump: { onJumpToDate?(entry.metadata?.reviewDate ?? "") }, lang: lang) {
                SpecialContentRenderer(entry: entry, textStyle: .system(size: 15))
            }
        } else if entry.chronology == .future {
            futureSection()
        } else {
            defaultEntryView
        }
    }

    @EnvironmentObject private var appState: AppState
    @State private var localDraft: String = ""
    @FocusState private var editingFocus: Bool
    @ViewBuilder private var defaultEntryView: some View {
        AtomContainer(isHighlighted: isHighlighted) {
            contextQuestionView()
            AtomHeader(category: entry.category, isMixed: entry.type == .mixed, lang: lang)
            SpecialContentRenderer(entry: entry, textStyle: .system(size: 16))
            AtomTimestamp(timestamp: entry.timestamp)
        }
        .contentShape(Rectangle()) // Make the whole area tappable for context menu
    }
    
    private func contextQuestion() -> QuestionEntry? {
        guard let id = entry.metadata?.questionId else { return nil }
        return questionEntries.first(where: { $0.id == id })
    }

    @ViewBuilder private func contextQuestionView() -> some View {
        if let cq = contextQuestion() {
            AtomContextReply(text: cq.system_prompt ?? Localization.tr("lockedMemory", lang: lang))
        } else {
            EmptyView()
        }
    }

    private func daysRemaining(target: String) -> Int {
        guard let targetDate = DateUtilities.parse(target) else { return 0 }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: targetDate)).day ?? 0
        return max(0, days)
    }

    private func futureSection() -> AnyView {
        let linkedQuestion = questionEntries.first(where: { $0.journal_now_id == entry.id })
        let recordedAnswerId = linkedQuestion?.journal_future_id
        var allReplies: [JournalEntry] = []
        if let q = linkedQuestion, let getter = getReplies { allReplies = getter(q.id) }
        if allReplies.isEmpty, let id = recordedAnswerId, let resolver = resolveEntry, let single = resolver(id) { allReplies.append(single) }
        
        let isAnswered = !allReplies.isEmpty || (recordedAnswerId != nil)
        let isSealed = entry.subType != .pending_question
        
        // Logic:
        // 1. If sealed AND no answers -> MoleculeSealed (Unopened)
        // 2. If sealed AND answered -> CapsuleCard (Replied, viewable)
        // 3. If not sealed -> CapsuleCard (Pending or Replied)
        
        if isSealed && !isAnswered {
            let days = daysRemaining(target: linkedQuestion?.delivery_date ?? "")
            return AnyView(MoleculeSealed(date: linkedQuestion?.delivery_date ?? Localization.tr("futureLabel", lang: lang), daysLeft: days, lang: lang))
        } else if let q = linkedQuestion {
            return AnyView(CapsuleCard(
                question: q,
                sourceEntry: entry,
                replies: allReplies,
                onInitiateReply: { if let id = linkedQuestion?.id { onInitiateReply?(id) } },
                onReply: { text in if let id = linkedQuestion?.id { onSubmitReply?(id, text) } },
                onJumpToDate: onJumpToDate,
                lang: lang
            ))
        } else {
            return AnyView(defaultEntryView)
        }
    }
}
