import SwiftUI

public struct CapsuleCard: View {
    public let question: QuestionEntry
    public let sourceEntry: JournalEntry?
    public let replies: [JournalEntry]
    public let onInitiateReply: () -> Void
    public var onReply: ((String) -> Void)?
    public var onJumpToDate: ((String) -> Void)?
    public var onCollapse: (() -> Void)?
    public let lang: Lang
    
    @State private var showDetail = false
    
    public init(question: QuestionEntry, sourceEntry: JournalEntry? = nil, replies: [JournalEntry], onInitiateReply: @escaping () -> Void, onReply: ((String) -> Void)? = nil, onJumpToDate: ((String) -> Void)? = nil, onCollapse: (() -> Void)? = nil, lang: Lang) {
        self.question = question
        self.sourceEntry = sourceEntry
        self.replies = replies
        self.onInitiateReply = onInitiateReply
        self.onReply = onReply
        self.onJumpToDate = onJumpToDate
        self.onCollapse = onCollapse
        self.lang = lang
    }
    
    private var isOverdue: Bool {
        guard replies.isEmpty else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        if let delivery = formatter.date(from: question.delivery_date) {
            return delivery < Date() && !Calendar.current.isDateInToday(delivery)
        }
        return false
    }

    private var statusLabel: String {
        if !replies.isEmpty {
            return Localization.tr("capsuleOpened", lang: lang) // "已回复"
        } else if isOverdue {
            return Localization.tr("capsuleOverdue", lang: lang) // "超期未回复"
        } else {
            return Localization.tr("capsuleCreated", lang: lang) // "待回复"
        }
    }
    
    private var statusIcon: String {
        if !replies.isEmpty { return "checkmark.circle.fill" }
        if isOverdue { return "exclamationmark.circle.fill" }
        return "envelope.open.fill"
    }
    
    private var statusColor: Color {
        if !replies.isEmpty { return Colors.green } // Green for completed
        if isOverdue { return Colors.red } // Red for overdue
        return Colors.indigo // Blue for pending
    }

    public var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Text(statusLabel)
                        //    .font(Typography.caption)
                        //    .fontWeight(.medium)
                        //    .foregroundColor(statusColor)
                        
                        if let prompt = question.system_prompt, !prompt.isEmpty {
                            Text(prompt)
                                .font(Typography.body)
                                .foregroundColor(Colors.slateText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text(Localization.tr("lockedMemory", lang: lang))
                                .font(Typography.caption)
                                .foregroundColor(Colors.systemGray)
                        }
                    }
                    
                    Spacer()
                    
                    if replies.isEmpty {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(Colors.indigo)
                            .padding(8)
                            .background(Colors.indigo.opacity(0.1))
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Colors.systemGray)
                    }
                }
                Divider().opacity(0.3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            CapsuleDetailSheet(
                question: question,
                sourceEntry: sourceEntry,
                replies: replies,
                onReply: { text in
                    if let onReply = onReply {
                        onReply(text)
                    } else {
                        onInitiateReply() 
                    }
                },
                onClose: { showDetail = false },
                lang: lang
            )
        }
    }
}
