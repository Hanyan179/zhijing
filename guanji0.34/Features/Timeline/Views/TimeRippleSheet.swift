import SwiftUI

public struct TimeRippleSheet: View {
    public let questions: [QuestionEntry]
    public let onSelect: (QuestionEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(questions: [QuestionEntry], onSelect: @escaping (QuestionEntry) -> Void) {
        self.questions = questions
        self.onSelect = onSelect
    }
    
    private var sortedQuestions: [QuestionEntry] {
        questions.sorted { a, b in
            let rankA = statusRank(a)
            let rankB = statusRank(b)
            if rankA != rankB {
                return rankA < rankB // Lower rank value is higher priority
            }
            // Secondary sort: Creation time ascending (Earlier first)
            return a.created_at < b.created_at
        }
    }
    
    // Priority: Overdue (0) > Unreplied (1) > Replied (2) > Locked/Future (3)
    private func statusRank(_ q: QuestionEntry) -> Int {
        let isReplied = isQuestionReplied(q)
        let today = DateUtilities.today
        let delivery = q.delivery_date
        
        // 1. Locked / Future (Delivery > Today)
        // User calls this "Today's Question (Unopened)" if it was created today for future.
        if delivery > today {
            return 3
        }
        
        // 2. Replied
        if isReplied {
            return 2
        }
        
        // 3. Overdue (Delivery < Today AND Not Replied)
        if delivery < today {
            return 0
        }
        
        // 4. Unreplied / Due Today (Delivery == Today AND Not Replied)
        return 1
    }
    
    private func isQuestionReplied(_ q: QuestionEntry) -> Bool {
        // Check if legacy future ID exists or fetch replies from Repo
        if let futureId = q.journal_future_id, !futureId.isEmpty { return true }
        // We can't easily check Repo here synchronously without passing data in.
        // Ideally the ViewModel should pass this status.
        // For now, let's assume we need to check TimelineRepository
        let replies = TimelineRepository.shared.getReplies(for: q.id)
        return !replies.isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    if sortedQuestions.isEmpty {
                        Text(Localization.tr("noArtifacts"))
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(sortedQuestions) { q in
                            Button(action: {
                                onSelect(q)
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(q.system_prompt ?? Localization.tr("lockedMemory"))
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Colors.slateText)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        statusBadge(for: q)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                        Text(q.delivery_date) // Show delivery date as it's more relevant for overdue
                                            .font(.caption)
                                        
                                        Spacer()
                                    }
                                    .foregroundColor(Colors.slate500)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                } header: {
                    Text(Localization.tr("questionsForToday"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Localization.tr("timeRipple"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.tr("done")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func statusBadge(for q: QuestionEntry) -> some View {
        let rank = statusRank(q)
        // 0: Overdue, 1: Unreplied, 2: Replied, 3: Locked
        
        var text = ""
        var color = Color.gray
        
        switch rank {
        case 0:
            text = Localization.tr("replyOverdue")
            color = Colors.red
        case 1:
            text = Localization.tr("capsuleCreated") // "待回复"
            color = Colors.indigo
        case 2:
            text = Localization.tr("capsuleOpened") // "已回复"
            color = Colors.green
        case 3:
            text = Localization.tr("lockedMemory") // "未解锁"
            color = Colors.slate500
        default: break
        }
        
        return Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}
