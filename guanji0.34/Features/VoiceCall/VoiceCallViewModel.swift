import Foundation
import SwiftUI
import Combine

/// ViewModel for Voice Call feature
/// Manages voice call session state and coordinates between SpeechService, TTSService, and AIService
/// Implements the call loop: listening → AI processing → speaking → listening
/// Requirements: 4.1, 4.2, 4.3, 4.4
@MainActor
public final class VoiceCallViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current voice call session
    @Published public private(set) var session = VoiceCallSession()
    
    /// Whether to show permission alert
    @Published public var showPermissionAlert = false
    
    /// Permission alert message
    @Published public var permissionAlertMessage: String = ""
    
    /// Error message to display
    @Published public var errorMessage: String?
    
    /// 当前音频电平 (0.0-1.0)，用于波形动画
    @Published public private(set) var audioLevel: Float = 0.0
    
    // MARK: - Dependencies
    
    private let speechService = SpeechService()
    private let ttsService = TTSService()
    private let aiService = AIService.shared
    private let repository = AIConversationRepository.shared
    
    // MARK: - Private State
    
    /// Accumulated AI response for streaming
    private var accumulatedResponse = ""
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag to prevent duplicate endCall execution
    private var hasEnded: Bool = false
    
    /// Flag to track if messages have been saved
    private var messagesSaved: Bool = false
    
    /// Existing conversation messages (loaded on start for context)
    /// Requirements: 4.1
    private var existingMessages: [AIMessage] = []
    
    /// Flag to track if background listening is active for voice interrupt
    /// Requirements: 2.1, 2.6
    private var isBackgroundListening: Bool = false
    
    // MARK: - Computed Properties
    
    /// Current call state
    public var state: CallState {
        session.state
    }
    
    /// Whether the call is active (not idle)
    public var isCallActive: Bool {
        session.state != .idle
    }
    
    /// Text to display based on current state
    public var displayText: String {
        switch session.state {
        case .idle:
            return ""
        case .listening:
            return session.recognizedText.isEmpty ? "正在聆听..." : session.recognizedText
        case .processing:
            // 流式返回时实时显示 AI 回复
            if !session.aiResponseText.isEmpty {
                return session.aiResponseText
            }
            return "AI 思考中..."
        case .speaking:
            return session.aiResponseText
        }
    }
    
    // MARK: - Initialization
    
    public init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe speech service recognized text
        speechService.$recognizedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.session.recognizedText = text
            }
            .store(in: &cancellables)
        
        // Observe speech service errors
        speechService.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleSpeechError(error)
            }
            .store(in: &cancellables)
        
        // Observe audio level for waveform animation
        speechService.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)
    }

    
    // MARK: - Public API
    
    /// Start a voice call
    /// - Parameter conversationId: Optional conversation ID to associate with
    /// Requirements: 1.2, 1.3, 1.4, 4.1
    public func startCall(conversationId: String?) {
        // Reset session
        session = VoiceCallSession(conversationId: conversationId)
        session.startTime = Date()
        errorMessage = nil
        
        // Reset idempotence flags
        hasEnded = false
        messagesSaved = false
        
        // Load existing conversation context if conversationId provided
        // Requirements: 4.1
        existingMessages = []
        if let id = conversationId,
           let conversation = repository.load(id: id) {
            existingMessages = conversation.sortedMessages
        }
        
        // Check and request permissions
        Task {
            let authorized = await speechService.requestAuthorization()
            
            if authorized {
                // Start listening
                startListening()
            } else {
                // Show permission alert
                handlePermissionDenied()
            }
        }
    }
    
    /// End the voice call
    /// Requirements: 4.1, 4.3
    public func endCall() {
        // Guard against duplicate calls
        guard !hasEnded else { return }
        hasEnded = true
        
        // Stop background listening if active
        stopBackgroundListening()
        
        // Stop any ongoing operations
        speechService.stopListening()
        ttsService.stop()
        aiService.cancelRequest()
        
        // Save messages to conversation if we have any (only once)
        if !messagesSaved {
            saveMessagesToConversation()
            messagesSaved = true
        }
        
        // Reset session
        session.state = .idle
        accumulatedResponse = ""
        isBackgroundListening = false
    }
    
    /// Interrupt AI speaking and resume listening
    /// Requirements: 2.2, 2.4
    public func interrupt() {
        guard session.state == .speaking else { return }
        
        // Stop background listening first
        stopBackgroundListening()
        
        // Stop TTS
        ttsService.stop()
        
        // Provide haptic feedback
        // Requirements: 2.4
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Resume listening
        startListening()
    }
    
    /// Interrupt with recognized text for seamless continuation
    /// Requirements: 2.2, 2.3
    private func interruptWithText(_ recognizedText: String) {
        guard session.state == .speaking else { return }
        
        // Stop background listening first
        stopBackgroundListening()
        
        // Stop TTS
        ttsService.stop()
        
        // Provide haptic feedback
        // Requirements: 2.4
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Continue with the recognized text as new input
        handleUserInput(recognizedText)
    }
    
    /// Open system Siri settings
    /// Requirements: 6.1, 6.2, 6.3
    public func openVoiceSettings() {
        TTSService.openSiriSettings()
    }
    
    // MARK: - Private Methods - Call Flow
    
    // MARK: Background Listening for Voice Interrupt
    
    /// Start background listening during speaking state to detect voice interrupt
    /// Requirements: 2.1, 2.6
    private func startBackgroundListening() {
        // Only start if we're in speaking state
        guard session.state == .speaking else { return }
        
        // Don't start if already listening
        guard !isBackgroundListening else { return }
        
        isBackgroundListening = true
        
        speechService.startListening { [weak self] recognizedText in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // If we detect any speech while AI is speaking, interrupt
                // Requirements: 2.2, 2.3
                if self.session.state == .speaking && !recognizedText.isEmpty {
                    self.interruptWithText(recognizedText)
                }
            }
        }
    }
    
    /// Stop background listening
    /// Requirements: 2.6
    private func stopBackgroundListening() {
        guard isBackgroundListening else { return }
        isBackgroundListening = false
        speechService.stopListening()
    }
    
    /// Start listening for user speech
    private func startListening() {
        session.state = .listening
        session.recognizedText = ""
        
        speechService.startListening { [weak self] recognizedText in
            Task { @MainActor [weak self] in
                self?.handleUserInput(recognizedText)
            }
        }
    }
    
    /// Handle user speech input after silence detection
    /// - Parameter text: The recognized text
    private func handleUserInput(_ text: String) {
        // 确保语音识别已完全停止
        speechService.stopListening()
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Empty input, resume listening
            startListening()
            return
        }
        
        // Save user message
        let userMessage = VoiceCallMessage(role: .user, content: text)
        session.messages.append(userMessage)
        
        // Transition to processing state
        session.state = .processing
        session.recognizedText = text
        
        // Send to AI
        sendToAI(text)
    }
    
    /// Send text to AI service
    /// - Parameter text: The user's message
    /// Requirements: 4.2, 4.4
    private func sendToAI(_ text: String) {
        accumulatedResponse = ""
        
        // Build message history: existing conversation messages + voice call messages
        // Requirements: 4.2, 4.4 - Include conversation history as context
        var allMessages: [AIMessage] = existingMessages
        
        // Append voice call messages (already in chronological order)
        let voiceMessages = session.messages.map { message -> AIMessage in
            let role: MessageRole = message.role == .user ? .user : .assistant
            return AIMessage(role: role, content: message.content)
        }
        allMessages.append(contentsOf: voiceMessages)
        
        aiService.sendMessage(
            messages: allMessages,
            model: "gemini-2.5-flash",
            enableThinking: false,
            onContentUpdate: { [weak self] content in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.accumulatedResponse = content
                    // 实时更新显示的 AI 回复文本
                    self.session.aiResponseText = content
                }
            },
            onReasoningUpdate: nil,
            onComplete: { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.handleAIResponse(result)
                }
            }
        )
    }
    
    /// Handle AI response
    /// - Parameter result: The AI service result
    private func handleAIResponse(_ result: Result<AIMessage, AIServiceError>) {
        print("[VoiceCall] handleAIResponse called")
        
        switch result {
        case .success(let message):
            let responseText = message.content
            print("[VoiceCall] AI response success, content length: \(responseText.count)")
            
            // 如果内容为空，使用累积的流式内容
            let finalText = responseText.isEmpty ? accumulatedResponse : responseText
            
            guard !finalText.isEmpty else {
                print("[VoiceCall] AI response is empty, resuming listening")
                errorMessage = "AI 没有返回内容"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.startListening()
                }
                return
            }
            
            // Save assistant message
            let assistantMessage = VoiceCallMessage(role: .assistant, content: finalText)
            session.messages.append(assistantMessage)
            
            // Update session and speak
            session.aiResponseText = finalText
            speakResponse(finalText)
            
        case .failure(let error):
            print("[VoiceCall] AI response failure: \(error.errorDescription ?? "unknown")")
            
            if case .cancelled = error {
                // User cancelled, just resume listening
                startListening()
                return
            }
            
            // 如果有累积的流式内容，使用它
            if !accumulatedResponse.isEmpty {
                print("[VoiceCall] Using accumulated response: \(accumulatedResponse.count) chars")
                let assistantMessage = VoiceCallMessage(role: .assistant, content: accumulatedResponse)
                session.messages.append(assistantMessage)
                session.aiResponseText = accumulatedResponse
                speakResponse(accumulatedResponse)
                return
            }
            
            // Show error and resume listening
            errorMessage = error.errorDescription
            
            // Resume listening after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.startListening()
            }
        }
    }
    
    /// Speak the AI response using TTS
    /// - Parameter text: The text to speak
    /// Requirements: 2.1, 2.5
    private func speakResponse(_ text: String) {
        session.state = .speaking
        
        // Start background listening to detect voice interrupt
        // Requirements: 2.1, 2.5
        startBackgroundListening()
        
        ttsService.speak(text) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Stop background listening when TTS completes
                self.stopBackgroundListening()
                
                // After speaking completes, resume normal listening
                self.startListening()
            }
        }
    }

    
    // MARK: - Private Methods - Error Handling
    
    /// Handle speech recognition errors
    /// - Parameter error: The voice call error
    private func handleSpeechError(_ error: VoiceCallError) {
        // 只在监听状态下处理错误，其他状态（processing/speaking）忽略
        guard session.state == .listening else { return }
        
        switch error {
        case .microphonePermissionDenied, .speechRecognitionPermissionDenied:
            handlePermissionDenied()
        case .speechRecognizerUnavailable:
            errorMessage = error.errorDescription
            // Try to resume after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.session.state == .listening {
                    self?.startListening()
                }
            }
        case .audioSessionError, .recognitionFailed:
            // 只显示真正的错误，不显示临时性错误
            if let desc = error.errorDescription, !desc.contains("no speech") {
                errorMessage = desc
            }
            // Resume listening after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.session.state == .listening {
                    self?.startListening()
                }
            }
        }
    }
    
    /// Handle permission denied scenario
    /// Requirements: 1.4
    private func handlePermissionDenied() {
        permissionAlertMessage = "需要麦克风和语音识别权限才能进行语音通话。请在设置中开启权限。"
        showPermissionAlert = true
        session.state = .idle
    }
    
    // MARK: - Private Methods - Conversation Persistence
    
    /// Save voice call messages to the associated conversation
    /// Requirements: 4.3
    private func saveMessagesToConversation() {
        guard !session.messages.isEmpty else { return }
        
        // Load or create conversation
        var conversation: AIConversation
        
        if let conversationId = session.conversationId,
           let existing = repository.load(id: conversationId) {
            conversation = existing
        } else {
            conversation = repository.createConversation()
            session.conversationId = conversation.id
        }
        
        // Add voice call messages to conversation
        for voiceMessage in session.messages {
            let role: MessageRole = voiceMessage.role == .user ? .user : .assistant
            let aiMessage = AIMessage(role: role, content: voiceMessage.content)
            conversation.addMessage(aiMessage)
        }
        
        // Generate title if needed
        if conversation.title == nil {
            conversation.generateTitle()
        }
        
        // Save conversation
        repository.save(conversation)
    }
}
