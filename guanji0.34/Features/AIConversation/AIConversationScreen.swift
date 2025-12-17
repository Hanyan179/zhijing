import SwiftUI

/// Main screen for AI conversation
/// Displays chat messages with streaming support and empty state
/// Requirements: 4.1, 4.4, 4.5
public struct AIConversationScreen: View {
    @StateObject private var vm = AIConversationViewModel()
    @EnvironmentObject private var appState: AppState
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages or empty state
            if vm.messages.isEmpty && !vm.isStreaming {
                WelcomeView(onStarterTap: { starter in
                    vm.sendMessage(starter)
                })
            } else {
                messagesScrollView
            }
        }
        .onAppear {
            loadConversation()
        }
        .onChange(of: appState.currentConversationId) { newId in
            if let id = newId {
                vm.loadConversation(id: id)
            } else {
                vm.createNewConversation()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_submit_input"))) { notification in
            // Only handle input when in AI mode
            guard appState.currentMode == .ai else { return }
            
            if let userInfo = notification.userInfo,
               let text = userInfo["text"] as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                vm.sendMessage(text)
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.messages) { message in
                        MessageBubble(
                            message: message,
                            showThinking: vm.thinkingModeEnabled
                        )
                        .id(message.id)
                    }
                    
                    // Streaming response
                    if vm.isStreaming {
                        StreamingMessageBubble(
                            content: vm.streamingContent,
                            reasoningContent: vm.streamingReasoning,
                            showThinking: vm.thinkingModeEnabled
                        )
                        .id("streaming")
                    }
                    
                    // Error message
                    if let error = vm.errorMessage {
                        errorView(error)
                    }
                }
                .padding()
            }
            .onChange(of: vm.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: vm.streamingContent) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Colors.amber)
                
                Text(message)
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
            }
            
            Button(action: {
                vm.retryLastMessage()
            }) {
                Text(Localization.tr("Action.Retry"))
                    .font(Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Colors.indigo)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.amber.opacity(0.1))
        )
    }
    
    // MARK: - Helpers
    
    private func loadConversation() {
        if let id = appState.currentConversationId {
            vm.loadConversation(id: id)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if vm.isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = vm.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Welcome View

/// Empty state view with welcome message and conversation starters
/// Requirements: 4.4
public struct WelcomeView: View {
    let onStarterTap: (String) -> Void
    
    private let starters = [
        "AI.Starter.1",
        "AI.Starter.2",
        "AI.Starter.3",
        "AI.Starter.4"
    ]
    
    public init(onStarterTap: @escaping (String) -> Void) {
        self.onStarterTap = onStarterTap
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                // AI Icon
                ZStack {
                    Circle()
                        .fill(Colors.indigo.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(Colors.indigo)
                }
                
                // Welcome text
                VStack(spacing: 8) {
                    Text(Localization.tr("AI.Welcome.Title"))
                        .font(Typography.header)
                        .foregroundColor(Colors.slateText)
                    
                    Text(Localization.tr("AI.Welcome.Subtitle"))
                        .font(Typography.body)
                        .foregroundColor(Colors.slate600)
                        .multilineTextAlignment(.center)
                }
                
                // Conversation starters
                VStack(spacing: 12) {
                    ForEach(starters, id: \.self) { starterKey in
                        starterButton(Localization.tr(starterKey))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func starterButton(_ text: String) -> some View {
        Button(action: {
            onStarterTap(text)
        }) {
            HStack {
                Text(text)
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Colors.indigo)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Colors.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct AIConversationScreen_Previews: PreviewProvider {
    static var previews: some View {
        AIConversationScreen()
            .environmentObject(AppState())
    }
}
#endif
