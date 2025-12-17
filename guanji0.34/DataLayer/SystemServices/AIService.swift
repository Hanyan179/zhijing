import Foundation

/// AI Service for SiliconFlow API integration with Qwen/QwQ-32B model
/// Supports streaming responses and thinking mode
public final class AIService: NSObject {
    public static let shared = AIService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    private let defaultModel = "Qwen/QwQ-32B"
    
    /// API Key stored in UserDefaults (should be set by user in settings)
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "siliconflow_api_key") ?? ""
    }
    
    // MARK: - State
    
    private var currentTask: URLSessionDataTask?
    private var streamBuffer = ""
    private var accumulatedContent = ""
    private var accumulatedReasoning = ""
    
    // MARK: - Callbacks
    
    private var onContentUpdate: ((String) -> Void)?
    private var onReasoningUpdate: ((String) -> Void)?
    private var onComplete: ((Result<AIMessage, AIServiceError>) -> Void)?
    private var onError: ((AIServiceError) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    /// Send a message and receive streaming response
    /// - Parameters:
    ///   - messages: Conversation history including the new user message
    ///   - enableThinking: Whether to request reasoning_content from the model
    ///   - onContentUpdate: Called when new content is received (streaming)
    ///   - onReasoningUpdate: Called when new reasoning content is received (streaming)
    ///   - onComplete: Called when the response is complete
    public func sendMessage(
        messages: [AIMessage],
        enableThinking: Bool = false,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        // Reset state
        streamBuffer = ""
        accumulatedContent = ""
        accumulatedReasoning = ""
        self.onContentUpdate = onContentUpdate
        self.onReasoningUpdate = onReasoningUpdate
        self.onComplete = onComplete
        
        // Build request
        let chatMessages = messages.map { ChatCompletionRequest.ChatMessage(from: $0) }
        let request = ChatCompletionRequest(
            model: defaultModel,
            messages: chatMessages,
            stream: true,
            enableThinking: enableThinking
        )
        
        guard let httpRequest = buildHTTPRequest(with: request) else {
            onComplete(.failure(.invalidResponse))
            return
        }
        
        // Create streaming session
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        currentTask = session.dataTask(with: httpRequest)
        currentTask?.resume()
    }
    
    /// Send a message without streaming (single response)
    /// - Parameters:
    ///   - messages: Conversation history including the new user message
    ///   - enableThinking: Whether to request reasoning_content from the model
    ///   - completion: Called with the complete response
    public func sendMessageSync(
        messages: [AIMessage],
        enableThinking: Bool = false,
        completion: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        let chatMessages = messages.map { ChatCompletionRequest.ChatMessage(from: $0) }
        let request = ChatCompletionRequest(
            model: defaultModel,
            messages: chatMessages,
            stream: false,
            enableThinking: enableThinking
        )
        
        guard let httpRequest = buildHTTPRequest(with: request) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let task = URLSession.shared.dataTask(with: httpRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            // Debug logging
            if let str = String(data: data, encoding: .utf8) {
                print("[AIService] Response: \(str)")
            }
            
            // Check for API error
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                DispatchQueue.main.async {
                    completion(.failure(.apiError(errorResponse.error.message)))
                }
                return
            }
            
            // Parse response
            do {
                let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard let choice = response.choices.first else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                let message = AIMessage(
                    role: .assistant,
                    content: choice.message.content,
                    reasoningContent: choice.message.reasoningContent
                )
                
                DispatchQueue.main.async {
                    completion(.success(message))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    /// Cancel the current request
    public func cancelRequest() {
        currentTask?.cancel()
        currentTask = nil
        onComplete?(.failure(.cancelled))
        resetCallbacks()
    }
    
    /// Check if API key is configured
    public var isConfigured: Bool {
        !apiKey.isEmpty
    }
    
    /// Set API key
    public func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "siliconflow_api_key")
    }
    
    // MARK: - Private Helpers
    
    private func buildHTTPRequest(with request: ChatCompletionRequest) -> URLRequest? {
        guard let url = URL(string: baseURL) else { return nil }
        
        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        httpRequest.timeoutInterval = 60
        
        do {
            httpRequest.httpBody = try JSONEncoder().encode(request)
            return httpRequest
        } catch {
            return nil
        }
    }
    
    private func resetCallbacks() {
        onContentUpdate = nil
        onReasoningUpdate = nil
        onComplete = nil
        onError = nil
    }
}





// MARK: - URLSessionDataDelegate for Streaming

extension AIService: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            print("[AIService] Status Code: \(httpResponse.statusCode)")
            
            // If error, we might want to capture the body to show the error
            if !(200...299).contains(httpResponse.statusCode) {
                print("[AIService] Error response received")
            }
        }
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        
        // Debug error responses
        if chunk.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
             print("[AIService] Possible error body: \(chunk)")
        }
        
        streamBuffer += chunk
        processStreamBuffer()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    self.onComplete?(.failure(.cancelled))
                } else {
                    self.onComplete?(.failure(.networkError(error)))
                }
            } else {
                // Create final message from accumulated content
                let message = AIMessage(
                    role: .assistant,
                    content: self.accumulatedContent,
                    reasoningContent: self.accumulatedReasoning.isEmpty ? nil : self.accumulatedReasoning
                )
                self.onComplete?(.success(message))
            }
            
            self.resetCallbacks()
        }
    }
    
    private func processStreamBuffer() {
        // SSE format: data: {...}\n\n
        let lines = streamBuffer.components(separatedBy: "\n")
        var processedUpTo = 0
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix(":") {
                processedUpTo = index + 1
                continue
            }
            
            // Check for stream end
            if trimmed == "data: [DONE]" {
                processedUpTo = index + 1
                continue
            }
            
            // Parse data line
            if trimmed.hasPrefix("data: ") {
                let jsonString = String(trimmed.dropFirst(6))
                
                if let jsonData = jsonString.data(using: .utf8),
                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) {
                    processStreamChunk(chunk)
                }
                
                processedUpTo = index + 1
            }
        }
        
        // Keep unprocessed data in buffer
        if processedUpTo > 0 && processedUpTo < lines.count {
            streamBuffer = lines[processedUpTo...].joined(separator: "\n")
        } else if processedUpTo == lines.count {
            streamBuffer = ""
        }
    }
    
    private func processStreamChunk(_ chunk: StreamChunk) {
        guard let choice = chunk.choices.first else { return }
        
        // Accumulate content
        if let content = choice.delta.content {
            accumulatedContent += content
            DispatchQueue.main.async { [weak self] in
                self?.onContentUpdate?(self?.accumulatedContent ?? "")
            }
        }
        
        // Accumulate reasoning content
        if let reasoning = choice.delta.reasoningContent {
            accumulatedReasoning += reasoning
            DispatchQueue.main.async { [weak self] in
                self?.onReasoningUpdate?(self?.accumulatedReasoning ?? "")
            }
        }
    }
}

// MARK: - Retry Support

extension AIService {
    
    /// Retry the last failed request
    /// - Parameters:
    ///   - messages: Conversation history
    ///   - enableThinking: Whether to enable thinking mode
    ///   - maxRetries: Maximum number of retry attempts
    ///   - onContentUpdate: Content update callback
    ///   - onReasoningUpdate: Reasoning update callback
    ///   - onComplete: Completion callback
    public func sendMessageWithRetry(
        messages: [AIMessage],
        enableThinking: Bool = false,
        maxRetries: Int = 3,
        onContentUpdate: @escaping (String) -> Void,
        onReasoningUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping (Result<AIMessage, AIServiceError>) -> Void
    ) {
        var retryCount = 0
        
        func attempt() {
            sendMessage(
                messages: messages,
                enableThinking: enableThinking,
                onContentUpdate: onContentUpdate,
                onReasoningUpdate: onReasoningUpdate
            ) { result in
                switch result {
                case .success:
                    onComplete(result)
                case .failure(let error):
                    // Don't retry on cancellation or API errors
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
                        // Exponential backoff
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
