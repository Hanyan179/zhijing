import Foundation
import SwiftUI
import Combine

/// ViewModel for AI Conversation feature
/// Manages conversation state, messages, and coordinates between AIService and AIConversationRepository
/// Requirements: 4.1, 4.2, 4.3
public final class AIConversationViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current conversation
    @Published public var conversation: AIConversation?
    
    /// Messages in current conversation (sorted chronologically)
    @Published public var messages: [AIMessage] = []
    
    /// Whether AI is currently streaming a response
    @Published public var isStreaming: Bool = false
    
    /// Current streaming content (partial response)
    @Published public var streamingContent: String = ""
    
    /// Current streaming reasoning content
    @Published public var streamingReasoning: String = ""
    
    /// Error message to display
    @Published public var errorMessage: String?
    
    /// Whether thinking mode is enabled
    @Published public var thinkingModeEnabled: Bool = false
    
    /// Input text for new message
    @Published public var inputText: String = ""
    
    // MARK: - Dependencies
    
    private let repository = AIConversationRepository.shared
    private let aiService = AIService.shared
    
    // MARK: - Initialization
    
    public init() {
        // Load thinking mode preference
        thinkingModeEnabled = UserDefaults.standard.bool(forKey: "ai_thinking_mode_enabled")
    }
    
    // MARK: - Public API
    
    /// Load an existing conversation by ID
    /// - Parameter id: The conversation ID
    /// - Requirements: 2.4
    public func loadConversation(id: String) {
        guard let loaded = repository.load(id: id) else {
            errorMessage = "Failed to load conversation"
            return
        }
        
        conversation = loaded
        messages = loaded.sortedMessages
        errorMessage = nil
    }
    
    /// Create a new conversation associated with the current day
    /// - Requirements: 2.5, 7.1
    public func createNewConversation() {
        let newConversation = repository.createConversation()
        conversation = newConversation
        messages = []
        errorMessage = nil
    }
    
    /// Send a user message and get AI response
    /// - Parameter content: The message content
    /// - Requirements: 4.2, 4.3
    public func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isStreaming else { return }
        
        // Ensure we have a conversation
        if conversation == nil {
            createNewConversation()
        }
        
        guard var currentConversation = conversation else { return }
        
        // Create and add user message immediately
        let userMessage = AIMessage(
            role: .user,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        currentConversation.addMessage(userMessage)
        repository.save(currentConversation)
        
        // Update local state
        conversation = currentConversation
        messages = currentConversation.sortedMessages
        inputText = ""
        
        // Auto-generate title if this is the first message
        if currentConversation.title == nil {
            currentConversation.generateTitle()
            repository.save(currentConversation)
            conversation = currentConversation
        }
        
        // Start streaming response
        startStreamingResponse()
    }
    
    /// Retry the last failed request
    public func retryLastMessage() {
        guard !isStreaming else { return }
        startStreamingResponse()
    }
    
    /// Cancel the current streaming request
    public func cancelStreaming() {
        aiService.cancelRequest()
        isStreaming = false
        streamingContent = ""
        streamingReasoning = ""
    }
    
    /// Toggle thinking mode
    public func toggleThinkingMode() {
        thinkingModeEnabled.toggle()
        UserDefaults.standard.set(thinkingModeEnabled, forKey: "ai_thinking_mode_enabled")
    }
    
    /// Delete current conversation
    public func deleteConversation() {
        guard let id = conversation?.id else { return }
        repository.delete(id: id)
        conversation = nil
        messages = []
    }
    
    // MARK: - Private Methods
    
    private func startStreamingResponse() {
        guard let currentConversation = conversation else { return }
        
        isStreaming = true
        streamingContent = ""
        streamingReasoning = ""
        errorMessage = nil
        
        // Build message history for API
        let messageHistory = currentConversation.sortedMessages
        
        aiService.sendMessage(
            messages: messageHistory,
            enableThinking: thinkingModeEnabled,
            onContentUpdate: { [weak self] content in
                DispatchQueue.main.async {
                    self?.streamingContent = content
                }
            },
            onReasoningUpdate: { [weak self] reasoning in
                DispatchQueue.main.async {
                    self?.streamingReasoning = reasoning
                }
            },
            onComplete: { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleStreamingComplete(result)
                }
            }
        )
    }
    
    private func handleStreamingComplete(_ result: Result<AIMessage, AIServiceError>) {
        isStreaming = false
        
        switch result {
        case .success(let aiMessage):
            // Add AI response to conversation
            guard var currentConversation = conversation else { return }
            
            currentConversation.addMessage(aiMessage)
            repository.save(currentConversation)
            
            // Update local state
            conversation = currentConversation
            messages = currentConversation.sortedMessages
            streamingContent = ""
            streamingReasoning = ""
            
        case .failure(let error):
            if case .cancelled = error {
                // User cancelled, no error message needed
                return
            }
            errorMessage = error.errorDescription
        }
    }
}
