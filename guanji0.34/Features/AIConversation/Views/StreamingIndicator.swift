import SwiftUI
import Markdown

/// Animated typing indicator shown while AI is generating response
/// Requirements: 10.2
public struct StreamingIndicator: View {
    @State private var animationPhase: Int = 0
    
    private let dotCount = 3
    private let animationDuration: Double = 0.6
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(Colors.slate500)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Colors.slateLight)
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(dotCount), repeats: true) { _ in
            withAnimation(.easeInOut(duration: animationDuration / Double(dotCount))) {
                animationPhase = (animationPhase + 1) % dotCount
            }
        }
    }
}

// MARK: - Streaming Message Bubble

/// Message bubble that shows streaming content as it arrives
/// Supports incremental Markdown parsing during streaming
/// Requirements: 3.1-3.4
public struct StreamingMessageBubble: View {
    let content: String
    let reasoningContent: String?
    
    /// Parsed document for incremental rendering
    @State private var parsedDocument: Document?
    /// Flag indicating if syntax is complete
    @State private var isSyntaxComplete: Bool = true
    /// Previous content length for change detection
    @State private var previousContentLength: Int = 0
    
    public init(content: String, reasoningContent: String? = nil) {
        self.content = content
        self.reasoningContent = reasoningContent
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Streaming thinking section - always show if reasoning content exists
            if let reasoning = reasoningContent, !reasoning.isEmpty {
                StreamingThinkingSection(content: reasoning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Streaming content
            if !content.isEmpty {
                streamingContentView
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Show typing indicator when no content yet
                TypingDotsView()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Colors.slateLight)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: content) { newContent in
            parseIncrementally(newContent)
        }
        .onAppear {
            parseIncrementally(content)
        }
    }
    
    // MARK: - Streaming Content View
    
    @ViewBuilder
    private var streamingContentView: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Show rich content if syntax is complete, otherwise plain text
            if isSyntaxComplete, let doc = parsedDocument {
                RichTextRenderer(
                    document: doc,
                    isUserMessage: false
                )
            } else {
                // Plain text for incomplete syntax
                Text(content)
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
                    .textSelection(.enabled)
            }
            
            // Cursor animation
            CursorView()
        }
    }
    
    // MARK: - Incremental Parsing
    
    /// Parse content incrementally, handling incomplete syntax gracefully
    private func parseIncrementally(_ newContent: String) {
        guard !newContent.isEmpty else {
            parsedDocument = nil
            isSyntaxComplete = true
            return
        }
        
        // Use incremental parsing to detect incomplete syntax
        let (doc, isComplete) = MarkdownParser.parseIncremental(newContent)
        
        // Update state
        parsedDocument = doc
        isSyntaxComplete = isComplete
        previousContentLength = newContent.count
    }
}

// MARK: - Cursor View

private struct CursorView: View {
    @State private var isVisible: Bool = true
    
    var body: some View {
        Rectangle()
            .fill(Colors.indigo)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Typing Dots View

private struct TypingDotsView: View {
    @State private var animationPhase: Int = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Colors.slate500)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StreamingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreamingIndicator()
            
            StreamingMessageBubble(
                content: "I'm thinking about your question...",
                reasoningContent: "Analyzing the context..."
            )
            
            StreamingMessageBubble(content: "")
        }
        .padding()
    }
}
#endif
