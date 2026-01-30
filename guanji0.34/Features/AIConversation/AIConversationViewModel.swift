import Foundation
import SwiftUI
import Combine

/// ViewModel for AI Conversation feature
/// Manages conversation state, messages, and coordinates between AIService and AIConversationRepository
/// Supports model selection and thinking mode via Claudeflare Gateway
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
    
    /// Current streaming reasoning/thinking content
    @Published public var streamingReasoning: String = ""
    
    /// Error message to display
    @Published public var errorMessage: String?
    
    /// Whether thinking mode is enabled
    @Published public var thinkingModeEnabled: Bool = false
    
    /// Selected model tier (new API)
    /// - Requirements: 5.1, 5.5
    @Published public var selectedModelTier: ModelTier = .balanced
    
    /// Selected AI model (legacy, kept for compatibility during migration)
    @Published public var selectedModel: String = "gemini-2.5-flash"
    
    /// Input text for new message
    @Published public var inputText: String = ""
    
    /// Attachment manager for handling multimodal input
    @Published public var attachmentManager = AttachmentManager()
    
    /// Whether to show model selector sheet
    @Published public var showModelSelector: Bool = false
    
    /// Whether to show attachment menu
    @Published public var showAttachmentMenu: Bool = false
    
    // MARK: - Dependencies
    
    private let repository = AIConversationRepository.shared
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        // Load preferences
        loadPreferences()
        
        // Listen for thinking mode changes from InputDock
        NotificationCenter.default.publisher(for: Notification.Name("gj_thinking_mode_changed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let enabled = notification.userInfo?["enabled"] as? Bool {
                    self?.thinkingModeEnabled = enabled
                    self?.savePreferences()
                }
            }
            .store(in: &cancellables)
        
        // Listen for model tier changes from InputDock
        NotificationCenter.default.publisher(for: Notification.Name("gj_model_tier_changed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let tierRaw = notification.userInfo?["tier"] as? String,
                   let tier = ModelTier(rawValue: tierRaw) {
                    self?.selectedModelTier = tier
                    self?.savePreferences()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Preferences
    
    /// Load preferences from UserDefaults
    /// - Requirements: 5.1, 5.2
    private func loadPreferences() {
        // Load model tier (new API)
        if let tierRaw = UserDefaults.standard.string(forKey: "ai_selected_model_tier"),
           let tier = ModelTier(rawValue: tierRaw) {
            selectedModelTier = tier
        } else {
            selectedModelTier = .balanced
        }
        
        // Load thinking mode
        thinkingModeEnabled = UserDefaults.standard.bool(forKey: "ai_thinking_mode_enabled")
        
        // Legacy: keep selectedModel for backward compatibility
        selectedModel = UserDefaults.standard.string(forKey: "ai_selected_model") ?? "gemini-2.5-flash"
        
        // Sync thinking mode state to InputDock
        NotificationCenter.default.post(
            name: Notification.Name("gj_thinking_mode_sync"),
            object: nil,
            userInfo: ["enabled": thinkingModeEnabled]
        )
        
        // Sync model tier state to InputDock
        NotificationCenter.default.post(
            name: Notification.Name("gj_model_tier_sync"),
            object: nil,
            userInfo: ["tier": selectedModelTier.rawValue]
        )
    }
    
    /// Save preferences to UserDefaults
    /// - Requirements: 5.5, 5.6
    private func savePreferences() {
        UserDefaults.standard.set(thinkingModeEnabled, forKey: "ai_thinking_mode_enabled")
        UserDefaults.standard.set(selectedModelTier.rawValue, forKey: "ai_selected_model_tier")
        // Legacy: keep selectedModel for backward compatibility
        UserDefaults.standard.set(selectedModel, forKey: "ai_selected_model")
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
    
    /// Save current conversation and create a new one
    /// Called when user taps "new conversation" button
    /// - Requirements: 4.9, 5.1
    public func saveAndCreateNewConversation() {
        // Save current conversation if it exists and has messages
        if let currentConversation = conversation, !currentConversation.messages.isEmpty {
            repository.save(currentConversation)
        }
        
        // Create new conversation
        createNewConversation()
    }
    
    /// Send a user message and get AI response
    /// - Parameter content: The message content
    /// - Requirements: 4.2, 4.3
    public func sendMessage(_ content: String) {
        sendMessageWithAttachments(content, attachments: [])
    }
    
    /// Send a user message with attachments and get AI response
    /// - Parameters:
    ///   - content: The message content
    ///   - attachments: Array of indexed attachments
    /// - Requirements: 6.1, 6.4, 6.5
    public func sendMessageWithAttachments(_ content: String, attachments: [IndexedAttachment]) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty else { return }
        guard !isStreaming else { return }
        
        // Ensure we have a conversation
        if conversation == nil {
            createNewConversation()
        }
        
        guard var currentConversation = conversation else { return }
        
        // Convert IndexedAttachments to MessageAttachments for storage
        // Store full-resolution image as data URL for local display (not thumbnail)
        // Requirements: 2.1, 2.2, 2.3
        let messageAttachments: [MessageAttachment]? = attachments.isEmpty ? nil : attachments.map { indexed in
            // For images, convert full base64Data to data URL for display
            // Use the original image data, not the thumbnail, for clear display
            if indexed.attachment.type == .image,
               let base64Data = indexed.base64Data {
                let dataURL = "data:image/jpeg;base64,\(base64Data)"
                return MessageAttachment(
                    id: indexed.attachment.id,
                    type: indexed.attachment.type,
                    url: dataURL,
                    name: indexed.attachment.name,
                    duration: indexed.attachment.duration
                )
            }
            // For file attachments, also store as data URL for later retrieval
            if indexed.attachment.type == .file,
               let base64Data = indexed.base64Data,
               let fileName = indexed.attachment.name {
                let fileExtension = (fileName as NSString).pathExtension
                let mimeType = AttachmentType.mimeType(for: fileExtension)
                let dataURL = "data:\(mimeType);base64,\(base64Data)"
                return MessageAttachment(
                    id: indexed.attachment.id,
                    type: indexed.attachment.type,
                    url: dataURL,
                    name: indexed.attachment.name,
                    duration: indexed.attachment.duration
                )
            }
            // For other attachments, keep original
            return indexed.attachment
        }
        
        // Create and add user message immediately
        let userMessage = AIMessage(
            role: .user,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            attachments: messageAttachments
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
        
        // Start streaming response with attachments
        startStreamingResponse(with: attachments)
    }
    
    /// Send message using pending attachments from attachment manager
    /// - Parameter content: The message content
    public func sendMessageWithPendingAttachments(_ content: String) {
        let readyAttachments = attachmentManager.getReadyAttachments()
        sendMessageWithAttachments(content, attachments: readyAttachments)
        
        // Clear attachments after sending
        Task { @MainActor in
            attachmentManager.clearAll()
        }
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
    /// - Requirements: 5.2, 5.6
    public func toggleThinkingMode() {
        thinkingModeEnabled.toggle()
        savePreferences()
    }
    
    /// Set the selected model tier
    /// - Parameter tier: Model tier (fast, balanced, powerful)
    /// - Requirements: 5.1, 5.5
    public func setModelTier(_ tier: ModelTier) {
        selectedModelTier = tier
        savePreferences()
    }
    
    /// Set the selected model (legacy, kept for compatibility)
    /// - Parameter model: Model identifier
    public func setModel(_ model: String) {
        selectedModel = model
        // Disable thinking mode if model doesn't support it
        if !AIModel.supportsThinking(model) {
            thinkingModeEnabled = false
        }
        savePreferences()
    }
    
    /// Set thinking mode enabled state
    /// - Parameter enabled: Whether to enable thinking mode
    /// - Requirements: 5.2, 5.6
    public func setThinkingMode(_ enabled: Bool) {
        thinkingModeEnabled = enabled
        savePreferences()
        
        // Sync to InputDock
        NotificationCenter.default.post(
            name: Notification.Name("gj_thinking_mode_sync"),
            object: nil,
            userInfo: ["enabled": enabled]
        )
    }
    
    /// Delete current conversation
    public func deleteConversation() {
        guard let id = conversation?.id else { return }
        repository.delete(id: id)
        conversation = nil
        messages = []
    }
    
    /// Regenerate a specific AI message
    /// Removes the message and all subsequent messages, then requests a new response
    /// - Parameter message: The AI message to regenerate
    public func regenerateMessage(_ message: AIMessage) {
        guard !isStreaming else { return }
        guard message.role == .assistant else { return }
        guard var currentConversation = conversation else { return }
        
        // Find the index of the message to regenerate
        guard let messageIndex = currentConversation.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        
        // Remove this message and all subsequent messages
        currentConversation.messages.removeSubrange(messageIndex...)
        
        // Save the updated conversation
        repository.save(currentConversation)
        
        // Update local state
        conversation = currentConversation
        messages = currentConversation.sortedMessages
        
        // Start a new streaming response
        startStreamingResponse()
    }
    
    // MARK: - Private Methods
    
    private func startStreamingResponse(with attachments: [IndexedAttachment] = []) {
        guard let currentConversation = conversation else { return }
        
        isStreaming = true
        streamingContent = ""
        streamingReasoning = ""
        errorMessage = nil
        
        // Build message history for API
        let messageHistory = currentConversation.sortedMessages
        
        #if DEBUG
        print("[AIConversationViewModel] startStreamingResponse: modelTier=\(selectedModelTier.rawValue), thinking=\(thinkingModeEnabled)")
        #endif
        
        // Use new API with model tier
        // Note: Attachments are not supported in the new API yet
        if !attachments.isEmpty {
            // TODO: Implement attachment support in new API
            print("[AIConversationViewModel] Warning: Attachments not supported in new API, ignoring attachments")
        }
        
        // New API with model tier
        // - Requirements: 5.5, 5.6
        aiService.sendMessageWithNewAPI(
            messages: messageHistory,
            modelTier: selectedModelTier,
            thinking: thinkingModeEnabled,
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
