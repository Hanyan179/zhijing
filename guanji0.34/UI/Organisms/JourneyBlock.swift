import SwiftUI

public struct JourneyBlockView: View {
    public let journey: JourneyBlock
    public let questionEntries: [QuestionEntry]
    public let currentDateLabel: String
    public let todayDate: String
    public let focusEntryId: String?
    @EnvironmentObject private var appState: AppState
    public var onTagEntry: ((String, EntryCategory?) -> Void)? = nil
    public var onStartEdit: ((String) -> Void)? = nil
    public var onEditDestination: (() -> Void)? = nil
    public var onSubmitReply: ((String, String) -> Void)? = nil // New
    public var editNamespace: Namespace.ID? = nil
    
    public init(journey: JourneyBlock, questionEntries: [QuestionEntry] = [], currentDateLabel: String, todayDate: String, focusEntryId: String? = nil, onTagEntry: ((String, EntryCategory?) -> Void)? = nil, onStartEdit: ((String) -> Void)? = nil, onEditDestination: (() -> Void)? = nil, onSubmitReply: ((String, String) -> Void)? = nil, editNamespace: Namespace.ID? = nil) {
        self.journey = journey
        self.questionEntries = questionEntries
        self.currentDateLabel = currentDateLabel
        self.todayDate = todayDate
        self.focusEntryId = focusEntryId
        self.onTagEntry = onTagEntry
        self.onStartEdit = onStartEdit
        self.onEditDestination = onEditDestination
        self.onSubmitReply = onSubmitReply
        self.editNamespace = editNamespace
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            // Filter out replies from TimelineScreen display
            ForEach(journey.entries.filter { ($0.metadata?.questionId ?? "").isEmpty }) { e in
                entryRow(e)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var headerView: some View {
        JourneyHeaderChip(mode: journey.mode,
                          destination: journey.destination,
                          onTapDestination: {
            if journey.destination.status == .raw {
                appState.pendingLocation = journey.destination
                appState.showPlaceNaming = true
            }
        },
                          onLongPressDestination: onEditDestination)
    }
    
    private func entryRow(_ e: JournalEntry) -> some View {
        JournalRow(
            entry: e,
            questionEntries: questionEntries,
            currentDateLabel: currentDateLabel,
            todayDate: todayDate,
            resolveEntry: findEntry,
            getReplies: findReplies,
            onInitiateReply: initiateReply,
            onSubmitReply: onSubmitReply,
            onDelete: deleteEntry,
            isHighlighted: (e.id == focusEntryId),
            lang: appState.lang,
            editNamespace: editNamespace
        )
        .id(e.id)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if currentDateLabel == todayDate {
                // 删除按钮
                Button(role: .destructive, action: {
                    deleteEntry(id: e.id)
                }) {
                    Label(Localization.tr("delete"), systemImage: "trash")
                }
                
                // 编辑按钮
                if let onEdit = onStartEdit {
                    Button { onEdit(e.id) } label: { 
                        Label(Localization.tr("edit"), systemImage: "pencil") 
                    }
                    .tint(Colors.indigo)
                }
            }
        }
    }
    
    private func findEntry(id: String) -> JournalEntry? {
        let timelines = TimelineRepository.shared.getAllTimelines()
        for t in timelines {
            for item in t.items {
                switch item {
                case .scene(let s): if let hit = s.entries.first(where: { $0.id == id }) { return hit }
                case .journey(let j): if let hit = j.entries.first(where: { $0.id == id }) { return hit }
                }
            }
        }
        return nil
    }
    
    private func findReplies(qid: String) -> [JournalEntry] {
        var replies: [JournalEntry] = []
        let timelines = TimelineRepository.shared.getAllTimelines()
        for t in timelines {
            for item in t.items {
                switch item {
                case .scene(let s): replies.append(contentsOf: s.entries.filter { ($0.metadata?.questionId ?? "") == qid })
                case .journey(let j): replies.append(contentsOf: j.entries.filter { ($0.metadata?.questionId ?? "") == qid })
                }
            }
        }
        return replies
    }
    
    private func initiateReply(qid: String) {
        if let q = questionEntries.first(where: { $0.id == qid }) {
            NotificationCenter.default.post(name: Notification.Name("gj_initiate_reply"), object: nil, userInfo: ["id": qid, "text": q.system_prompt ?? ""])
        }
    }
    
    private func deleteEntry(id: String) {
        NotificationCenter.default.post(name: Notification.Name("gj_delete_entry"), object: nil, userInfo: ["id": id])
    }
}
