import SwiftUI

public struct SceneBlock: View {
    public let scene: SceneGroup
    public let questionEntries: [QuestionEntry]
    public let currentDateLabel: String
    public let todayDate: String
    public let focusEntryId: String?
    @EnvironmentObject private var appState: AppState
    public var onTagEntry: ((String, EntryCategory?) -> Void)? = nil
    public var onStartEdit: ((String) -> Void)? = nil
    public var onEditLocation: (() -> Void)? = nil
    public var onSubmitReply: ((String, String) -> Void)? = nil // New
    public var editNamespace: Namespace.ID? = nil
    
    public init(scene: SceneGroup, questionEntries: [QuestionEntry] = [], currentDateLabel: String, todayDate: String, focusEntryId: String? = nil, onTagEntry: ((String, EntryCategory?) -> Void)? = nil, onStartEdit: ((String) -> Void)? = nil, onEditLocation: (() -> Void)? = nil, onSubmitReply: ((String, String) -> Void)? = nil, editNamespace: Namespace.ID? = nil) {
        self.scene = scene
        self.questionEntries = questionEntries
        self.currentDateLabel = currentDateLabel
        self.todayDate = todayDate
        self.focusEntryId = focusEntryId
        self.onTagEntry = onTagEntry
        self.onStartEdit = onStartEdit
        self.onEditLocation = onEditLocation
        self.onSubmitReply = onSubmitReply
        self.editNamespace = editNamespace
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            SceneHeader(scene: scene, 
                        isEditing: appState.pendingLocation?.snapshot.lat == scene.location.snapshot.lat,
                        onEditLocation: onEditLocation)
                .padding(.bottom, 12)
            
            // Entries
            VStack(spacing: 24) {
                // Filter out replies from TimelineScreen display
                ForEach(scene.entries.filter { ($0.metadata?.questionId ?? "").isEmpty }) { e in
                    JournalRow(
                        entry: e,
                        questionEntries: questionEntries,
                        currentDateLabel: currentDateLabel,
                        todayDate: todayDate,
                        resolveEntry: { id in
                            // Real lookup
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
                    },
                    getReplies: { qid in
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
                    },
                    onInitiateReply: { qid in
                        if let q = questionEntries.first(where: { $0.id == qid }) {
                            NotificationCenter.default.post(name: Notification.Name("gj_initiate_reply"), object: nil, userInfo: ["id": qid, "text": q.system_prompt ?? ""]) }
                    },
                    onSubmitReply: onSubmitReply,
                    onDelete: { id in
                        NotificationCenter.default.post(name: Notification.Name("gj_delete_entry"), object: nil, userInfo: ["id": id])
                    },
                    isHighlighted: (e.id == focusEntryId),
                    lang: appState.lang,
                    editNamespace: editNamespace
                )
                    .id(e.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if currentDateLabel == todayDate {
                            // 删除按钮
                            Button(role: .destructive, action: { 
                                NotificationCenter.default.post(name: Notification.Name("gj_delete_entry"), object: nil, userInfo: ["id": e.id])
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
            }
            .padding(.vertical, 12)
        }
    }
}
