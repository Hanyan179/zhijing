import SwiftUI

/// AI 对话摘要卡片 - 在日记流中显示的折叠状态
/// 
/// 显示对话标题或最后一条消息预览，点击可展开全屏对话
/// 左滑可删除对话
/// - Requirements: 4.4, 4.5, 4.7
public struct AIConversationSummaryCard: View {
    let conversation: AIConversation
    let onTap: () -> Void
    var onDelete: (() -> Void)?
    
    public init(conversation: AIConversation, onTap: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.conversation = conversation
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 对话预览
                conversationPreview
                
                // 底部：AI 标签 + 时间戳
                HStack {
                    Spacer()
                    // AI 标签
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundColor(Colors.indigo)
                        Text("AI")
                            .font(Typography.fontEngraved)
                            .foregroundColor(Colors.indigo)
                    }
                    
                    Text("·")
                        .font(Typography.fontEngraved)
                        .foregroundColor(Colors.systemGray)
                    
                    // 时间戳
                    Text(formattedTime)
                        .font(Typography.fontEngraved)
                        .foregroundColor(Colors.systemGray)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label(Localization.tr("delete"), systemImage: "trash")
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(Localization.tr("AI.SummaryCard.Hint"))
    }
    
    /// 格式化时间显示
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: conversation.createdAt)
    }
    
    private var conversationPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 对话标题
            Text(displayTitle)
                .font(.body)
                .foregroundColor(Colors.slateText)
                .lineLimit(1)
            
            // 最后一条消息预览
            if let preview = lastMessagePreview {
                Text(preview)
                    .font(.caption)
                    .foregroundColor(Colors.slate600)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 显示标题：优先使用对话标题，否则使用默认文本
    private var displayTitle: String {
        if let title = conversation.title, !title.isEmpty {
            return title
        }
        return Localization.tr("AI.Conversation.Untitled")
    }
    
    /// 最后一条消息预览
    private var lastMessagePreview: String? {
        guard let lastMessage = conversation.sortedMessages.last else {
            return nil
        }
        
        let content = lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty {
            return nil
        }
        
        // 截断过长的内容
        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content
    }
    
    /// 无障碍描述
    private var accessibilityDescription: String {
        var description = displayTitle
        if let preview = lastMessagePreview {
            description += ", \(preview)"
        }
        return description
    }
}

// MARK: - Preview

#if DEBUG
struct AIConversationSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 有标题和消息的对话
            AIConversationSummaryCard(
                conversation: AIConversation(
                    title: "关于最近的心情",
                    messages: [
                        AIMessage(role: .user, content: "最近感觉有点累"),
                        AIMessage(role: .assistant, content: "我理解你的感受，能告诉我更多吗？")
                    ]
                ),
                onTap: {},
                onDelete: {}
            )
            
            // 无标题的对话
            AIConversationSummaryCard(
                conversation: AIConversation(
                    messages: [
                        AIMessage(role: .user, content: "帮我分析一下今天的日记")
                    ]
                ),
                onTap: {},
                onDelete: {}
            )
            
            // 空对话
            AIConversationSummaryCard(
                conversation: AIConversation(),
                onTap: {},
                onDelete: {}
            )
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
#endif
