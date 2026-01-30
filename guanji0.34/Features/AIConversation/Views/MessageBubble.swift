import SwiftUI
import Markdown

/// Chat message bubble for AI conversation
/// Displays user and AI messages with distinct visual styles
/// Supports rich Markdown rendering for AI responses
/// Enhanced with long-press menu and copy functionality
/// Requirements: 1.1-1.9, 3.1-3.4, 4.1, 4.6, 4.7, 4.8
public struct MessageBubble: View {
    let message: AIMessage
    let onRegenerate: (() -> Void)?
    
    /// Parsed Markdown document for AI messages
    @State private var parsedDocument: Document?
    /// Flag indicating if parsing is in progress
    @State private var isParsing: Bool = false
    /// Flag for copy feedback
    @State private var showCopied: Bool = false
    
    /// Audio cache for TTS playback
    @StateObject private var audioCache = MessageAudioCache.shared
    
    /// Threshold for async parsing (characters)
    private static let asyncParsingThreshold = 5000
    
    public init(
        message: AIMessage,
        onRegenerate: (() -> Void)? = nil
    ) {
        self.message = message
        self.onRegenerate = onRegenerate
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
                // Always show when reasoningContent exists, regardless of toggle state
                if !isUser, let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    ThinkingSection(content: reasoning)
                }
                
                // Main message content
                VStack(alignment: .leading, spacing: 8) {
                    // Attachments - use MessageBubbleAttachments for clickable images
                    if let attachments = message.attachments, !attachments.isEmpty {
                        MessageBubbleAttachments(
                            attachments: attachments,
                            isUserMessage: isUser
                        )
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
                
                // Timestamp and actions
                HStack(spacing: 8) {
                    Text(formatTime(message.timestamp))
                        .font(Typography.caption)
                        .foregroundColor(Colors.slate500)
                    
                    // Action buttons for AI messages
                    if !isUser {
                        messageActionsView
                    }
                }
            }
            .frame(maxWidth: isUser ? nil : .infinity, alignment: .leading)
            .contextMenu {
                contextMenuItems
            }
            
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
            // Colors.indigo 在暗色模式是白色背景，亮色模式是黑色背景
            // 文字颜色需要相反：暗色模式黑色，亮色模式白色
            Text(message.content)
                .font(Typography.body)
                .foregroundColor(Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark ? .black : .white
                }))
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
    
    // MARK: - Message Actions View
    
    @ViewBuilder
    private var messageActionsView: some View {
        HStack(spacing: 12) {
            // Copy button
            Button(action: copyMessage) {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(showCopied ? Colors.emerald : Colors.slate500)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.tr("AI.Message.Copy"))
            
            // Play audio button
            Button(action: playAudio) {
                if audioCache.loadingMessageId == message.id {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: audioCache.playingMessageId == message.id ? "stop.fill" : "speaker.wave.2")
                        .font(.caption)
                        .foregroundColor(audioCache.playingMessageId == message.id ? Colors.indigo : Colors.slate500)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("播放语音")
            
            // Regenerate button (if callback provided)
            if onRegenerate != nil {
                Button(action: { onRegenerate?() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(Colors.slate500)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.tr("AI.Message.Regenerate"))
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        // Copy action
        Button(action: copyMessage) {
            Label(Localization.tr("AI.Message.Copy"), systemImage: "doc.on.doc")
        }
        
        // Regenerate action (for AI messages only)
        if !isUser, let regenerate = onRegenerate {
            Button(action: regenerate) {
                Label(Localization.tr("AI.Message.Regenerate"), systemImage: "arrow.clockwise")
            }
        }
        
        // Copy with thinking (for AI messages with reasoning)
        if !isUser, let reasoning = message.reasoningContent, !reasoning.isEmpty {
            Button(action: copyWithThinking) {
                Label(Localization.tr("AI.Message.CopyWithThinking"), systemImage: "doc.on.doc.fill")
            }
        }
        
        // Play audio (for AI messages only)
        if !isUser {
            Button(action: playAudio) {
                if audioCache.playingMessageId == message.id {
                    Label("停止播放", systemImage: "stop.fill")
                } else if audioCache.hasCache(for: message.id) {
                    Label("播放语音", systemImage: "speaker.wave.2.fill")
                } else {
                    Label("生成语音", systemImage: "speaker.wave.2")
                }
            }
        }
    }
    
    // MARK: - Copy Actions
    
    private func copyMessage() {
        #if canImport(UIKit)
        UIPasteboard.general.string = message.content
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        // Show feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
    
    private func copyWithThinking() {
        guard let reasoning = message.reasoningContent else { return }
        
        let fullContent = """
        [Thinking]
        \(reasoning)
        
        [Response]
        \(message.content)
        """
        
        #if canImport(UIKit)
        UIPasteboard.general.string = fullContent
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
    
    // MARK: - Audio Playback
    
    private func playAudio() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        audioCache.playAudio(for: message.id, text: message.content)
    }
}

// MARK: - Audio Attachment (Legacy - kept for compatibility)

private struct AudioAttachmentView: View {
    let name: String?
    let duration: String?
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.title3)
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
                .font(.title)
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
                .font(.title3)
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
