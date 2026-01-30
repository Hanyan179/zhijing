import Foundation

public final class AIService: NSObject {
    public static let shared = AIService()
    
    private let claudeflareClient = ClaudeflareClient.shared
    
    private var currentTask: URLSessionDataTask?
    private var streamBuffer = ""
    private var accumulatedContent = ""
    private var accumulatedReasoning = ""
    
    private var onContentUpdate: ((String) -> Void)?
    private var onReasoningUpdate: ((String) -> Void)?
    private var onComplete: ((Result<AIMessage, AIServiceError>) -> Void)?
    private var onError: ((AIServiceError) -> Void)?
    
    private override init() {
        super.init()
    }
    
    /// Send message using new API with model tier
    /// - Parameters:
    ///   - messages: Array of AI messages
    ///   - modelTier: Model tier (fast, balanced, powerful)
    ///   - thinking: Whether to enable thinking mode
    ///   - onContentUpdate: Content update callback
    ///   - onReasoningUpdate: Reasoning update callback (optional)
    ///   - onComplete: Completion callback with result
    public func sendMessage(
        messages: [AIMessage],
        modelTier: ModelTier = .balanced,
        thinking: Bool = false,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        streamBuffer = ""
        accumulatedContent = ""
        accumulatedReasoning = ""
        self.onContentUpdate = onContentUpdate
        self.onReasoningUpdate = onReasoningUpdate
        self.onComplete = onComplete
        
        let chatMessages = messages.map { ChatMessage(from: $0) }
        
        claudeflareClient.chatWithNewAPI(
            messages: chatMessages,
            modelTier: modelTier,
            thinking: thinking,
            onContentUpdate: { [weak self] (content: String) in
                self?.accumulatedContent = content
                onContentUpdate(content)
            },
            onThinkingUpdate: { [weak self] (thinking: String) in
                self?.accumulatedReasoning = thinking
                onReasoningUpdate?(thinking)
            },
            onComplete: { [weak self] (result: Result<ChatUsage?, ClaudeflareError>) in
                guard let self = self else { return }
                
                switch result {
                case .success(let usage):
                    let message = AIMessage(
                        role: .assistant,
                        content: self.accumulatedContent,
                        reasoningContent: self.accumulatedReasoning.isEmpty ? nil : self.accumulatedReasoning
                    )
                    if let usage = usage {
                        print("[AIService] Completed with usage: input=\(usage.inputTokens), output=\(usage.outputTokens)")
                    }
                    onComplete(.success(message))
                    
                case .failure(let claudeflareError):
                    let aiError = AIServiceError(from: claudeflareError)
                    onComplete(.failure(aiError))
                }
                
                self.resetCallbacks()
            }
        )
    }
    
    /// Send message (legacy signature for compatibility)
    /// Internally uses the new API with balanced tier
    public func sendMessage(
        messages: [AIMessage],
        model: String = "gemini-2.5-flash",
        enableThinking: Bool = false,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        // Map legacy model parameter to model tier
        let modelTier: ModelTier = .balanced
        
        sendMessage(
            messages: messages,
            modelTier: modelTier,
            thinking: enableThinking,
            onContentUpdate: onContentUpdate,
            onReasoningUpdate: onReasoningUpdate,
            onComplete: onComplete
        )
    }
    
    public func cancelRequest() {
        claudeflareClient.cancelRequest()
        currentTask?.cancel()
        currentTask = nil
        resetCallbacks()
    }
    
    public var isConfigured: Bool {
        AuthService.shared.isAuthenticated && AuthService.shared.hasIdToken
    }
    
    // MARK: - New API Methods (POST /api/chat)
    
    /// Send message using new API with model tier
    /// - Parameters:
    ///   - messages: Array of AI messages
    ///   - modelTier: Model tier (fast, balanced, powerful)
    ///   - thinking: Whether to enable thinking mode
    ///   - onContentUpdate: Content update callback
    ///   - onReasoningUpdate: Reasoning/thinking update callback (optional)
    ///   - onComplete: Completion callback with result
    /// - Requirements: 5.5, 5.6
    public func sendMessageWithNewAPI(
        messages: [AIMessage],
        modelTier: ModelTier = .balanced,
        thinking: Bool = false,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        sendMessage(
            messages: messages,
            modelTier: modelTier,
            thinking: thinking,
            onContentUpdate: onContentUpdate,
            onReasoningUpdate: onReasoningUpdate,
            onComplete: onComplete
        )
    }
    
    private func resetCallbacks() {
        onContentUpdate = nil
        onReasoningUpdate = nil
        onComplete = nil
        onError = nil
    }
}


extension AIService {
    public func sendMessageWithRetry(
        messages: [AIMessage],
        modelTier: ModelTier = .balanced,
        thinking: Bool = false,
        maxRetries: Int = 3,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        var retryCount = 0
        
        func attempt() {
            sendMessage(
                messages: messages,
                modelTier: modelTier,
                thinking: thinking,
                onContentUpdate: onContentUpdate,
                onReasoningUpdate: onReasoningUpdate
            ) { result in
                switch result {
                case .success:
                    onComplete(result)
                case .failure(let error):
                    if case .cancelled = error {
                        onComplete(result)
                        return
                    }
                    if case .apiError = error {
                        onComplete(result)
                        return
                    }
                    retryCount += 1
                    if retryCount < maxRetries {
                        let delay = Double(retryCount) * 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            attempt()
                        }
                    } else {
                        onComplete(result)
                    }
                }
            }
        }
        attempt()
    }
}

extension AIServiceError {
    public init(from claudeflareError: ClaudeflareError) {
        switch claudeflareError {
        case .notConfigured:
            self = .apiError("Token not configured")
        case .networkError(let message):
            self = .networkError(NSError(domain: "ClaudeflareClient", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        case .authenticationError:
            self = .apiError("Authentication failed")
        case .serverError(let code):
            self = .apiError("Server error (\(code))")
        case .parseError(let message):
            self = .decodingError(NSError(domain: "SSE", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        case .cancelled:
            self = .cancelled
        case .invalidModel(let model):
            self = .apiError("Invalid model: \(model)")
        case .quotaExceeded:
            self = .apiError("Quota exceeded")
        }
    }
}
