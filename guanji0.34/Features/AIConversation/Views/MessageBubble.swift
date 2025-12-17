import SwiftUI
import Markdown

/// Chat message bubble for AI conversation
/// Displays user and AI messages with distinct visual styles
/// Supports rich Markdown rendering for AI responses
/// Requirements: 1.1-1.9, 3.1-3.4, 4.1, 4.6, 4.7, 4.8
public struct MessageBubble: View {
    let message: AIMessage
    let showThinking: Bool
    
    /// Parsed Markdown document for AI messages
    @State private var parsedDocument: Document?
    /// Flag indicating if parsing is in progress
    @State private var isParsing: Bool = false
    
    /// Threshold for async parsing (characters)
    private static let asyncParsingThreshold = 5000
    
    public init(message: AIMessage, showThinking: Bool = true) {
        self.message = message
        self.showThinking = showThinking
    }
    
    private var isUser: Bool {
        message.role == .user
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                // Thinking section (for AI messages with reasoning)
                if !isUser, showThinking, let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    ThinkingSection(content: reasoning)
                }
                
                // Main message content
                VStack(alignment: .leading, spacing: 8) {
                    // Attachments
                    if let attachments = message.attachments, !attachments.isEmpty {
                        AttachmentsView(attachments: attachments)
                    }
                    
                    // Text content
                    if !message.content.isEmpty {
                        messageContentView
                    }
                }
                .padding(.horizontal, isUser ? 14 : 0)
                .padding(.vertical, isUser ? 10 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Group {
                        if isUser {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Colors.indigo)
                        }
                    }
                )
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(Typography.caption)
                    .foregroundColor(Colors.slate500)
            }
            .frame(maxWidth: isUser ? nil : .infinity, alignment: .leading)
            
            if !isUser {
                Spacer(minLength: 0)
            }
        }
        .task(id: message.content) {
            await parseMessageContent()
        }
    }
    
    // MARK: - Message Content View
    
    @ViewBuilder
    private var messageContentView: some View {
        if isUser {
            // User messages: plain text rendering
            Text(message.content)
                .font(Typography.body)
                .foregroundColor(.white)
                .textSelection(.enabled)
        } else if isParsing {
            // Show loading indicator during parsing
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text(Localization.tr("AI.Parsing"))
                    .font(Typography.caption)
                    .foregroundColor(Colors.slate500)
            }
        } else if let doc = parsedDocument {
            // AI messages: rich Markdown rendering
            RichTextRenderer(
                document: doc,
                isUserMessage: false
            )
        } else {
            // Fallback: plain text if parsing hasn't completed
            Text(message.content)
                .font(Typography.body)
                .foregroundColor(Colors.slateText)
                .textSelection(.enabled)
        }
    }
    
    // MARK: - Parsing
    
    /// Parse message content, using async for long messages
    private func parseMessageContent() async {
        // Skip parsing for user messages
        guard !isUser else { return }
        
        let content = message.content
        
        // For long messages, parse on background thread
        if content.count > Self.asyncParsingThreshold {
            isParsing = true
            parsedDocument = await Task.detached(priority: .userInitiated) {
                MarkdownParser.parse(content)
            }.value
            isParsing = false
        } else {
            // For short messages, parse synchronously
            parsedDocument = MarkdownParser.parse(content)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Attachments View

private struct AttachmentsView: View {
    let attachments: [MessageAttachment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                attachmentView(for: attachment)
            }
        }
    }
    
    @ViewBuilder
    private func attachmentView(for attachment: MessageAttachment) -> some View {
        switch attachment.type {
        case .image:
            ImageAttachmentView(url: attachment.url)
        case .audio:
            AudioAttachmentView(name: attachment.name, duration: attachment.duration)
        case .file:
            FileAttachmentView(name: attachment.name ?? "File")
        }
    }
}

// MARK: - Image Attachment

private struct ImageAttachmentView: View {
    let url: String
    
    var body: some View {
        if let fileURL = URL(string: url),
           let data = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 200)
                .cornerRadius(12)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.slateLight)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(Colors.slate500)
                )
        }
    }
}

// MARK: - Audio Attachment

private struct AudioAttachmentView: View {
    let name: String?
    let duration: String?
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundColor(Colors.indigo)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name ?? Localization.tr("AI.Audio"))
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
                
                if let duration = duration {
                    Text(duration)
                        .font(Typography.caption)
                        .foregroundColor(Colors.slate500)
                }
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Colors.indigo)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.cardBackground)
        )
    }
}

// MARK: - File Attachment

private struct FileAttachmentView: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.fill")
                .font(.system(size: 20))
                .foregroundColor(Colors.indigo)
            
            Text(name)
                .font(Typography.body)
                .foregroundColor(Colors.slateText)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.cardBackground)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            MessageBubble(message: AIMessage(
                role: .user,
                content: "Hello, how are you today?"
            ))
            
            MessageBubble(message: AIMessage(
                role: .assistant,
                content: "I'm doing well, thank you for asking! How can I help you today?",
                reasoningContent: "The user is greeting me, I should respond politely and offer assistance."
            ))
        }
        .padding()
    }
}
#endif
