import Foundation

// MARK: - Claudeflare Gateway Client

/// Client for communicating with new-api AI Gateway
/// - Note: Handles HTTP requests, SSE streaming, and error handling
/// - Uses cookie-based authentication from AuthService
public final class ClaudeflareClient: NSObject {
    
    // MARK: - Singleton
    
    public static let shared = ClaudeflareClient()
    
    // MARK: - Configuration
    
    /// Gateway base URL (Legacy new-api - kept for TTS)
    private let gatewayURL = "https://api.jiangzefang.store"
    
    /// jing-backend API base URL (New API)
    /// - Requirements: 4.1
    private let jingBackendURL = "https://api.jingever.com"
    
    /// New chat endpoint (POST /api/chat)
    /// - Requirements: 4.1
    private let newChatEndpoint = "/api/chat"
    
    // MARK: - State
    
    /// Cookie storage (shared with AuthService)
    private let cookieStorage: HTTPCookieStorage
    
    /// Current URLSession data task
    private var currentTask: URLSessionDataTask?
    
    /// Current URLSession for streaming
    private var currentSession: URLSession?
    
    /// Buffer for incoming SSE data
    private var streamBuffer = ""
    
    /// Accumulated content from streaming response
    private var accumulatedContent = ""
    
    /// Accumulated thinking content from streaming response
    private var accumulatedThinking = ""
    
    /// Flag indicating if request was cancelled
    private var isCancelled = false
    
    /// Last event type for multi-line data handling
    private var lastEventType: String?
    
    /// Flag to track if we've seen a data line in current event (for SSE newline handling)
    private var hasDataInCurrentEvent = false
    
    // MARK: - Callbacks
    
    private var onContentUpdate: ((String) -> Void)?
    private var onThinkingUpdate: ((String) -> Void)?
    private var onComplete: ((Result<String, ClaudeflareError>) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        self.cookieStorage = HTTPCookieStorage.shared
        super.init()
    }
    
    // MARK: - Public API
    
    /// Cancel the current request
    public func cancelRequest() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
        currentSession?.invalidateAndCancel()
        currentSession = nil
        
        // Notify completion with cancelled error
        DispatchQueue.main.async { [weak self] in
            self?.onComplete?(.failure(.cancelled))
            self?.resetState()
        }
    }
    
    // MARK: - New API Chat (POST /api/chat)
    
    /// 新 API 聊天请求回调类型
    public typealias NewChatCompletion = (Result<ChatUsage?, ClaudeflareError>) -> Void
    
    /// 发送聊天消息到新 API (POST /api/chat)
    /// 使用 Bearer idToken 认证 (从 AuthService 获取)
    /// - Parameters:
    ///   - messages: 对话消息数组
    ///   - modelTier: 模型档次 (fast, balanced, powerful)
    ///   - thinking: 是否启用思考模式
    ///   - onContentUpdate: 内容更新回调（累积内容）
    ///   - onThinkingUpdate: 思考内容更新回调（累积思考内容，仅 thinking=true 时有值）
    ///   - onComplete: 完成回调，返回 usage 统计或错误
    /// - Requirements: 4.1, 4.2, 4.3, 4.4
    public func chatWithNewAPI(
        messages: [ChatMessage],
        modelTier: ModelTier = .balanced,
        thinking: Bool = false,
        onContentUpdate: @escaping (String) -> Void,
        onThinkingUpdate: ((String) -> Void)? = nil,
        onComplete: @escaping NewChatCompletion
    ) {
        // 存储请求参数用于 401 重试
        // - Requirements: 2.7
        pendingNewAPIRequest = PendingNewAPIRequest(
            messages: messages,
            modelTier: modelTier,
            thinking: thinking,
            onContentUpdate: onContentUpdate,
            onThinkingUpdate: onThinkingUpdate,
            onComplete: onComplete
        )
        
        // 执行请求
        executeNewAPIRequest(
            messages: messages,
            modelTier: modelTier,
            thinking: thinking,
            onContentUpdate: onContentUpdate,
            onThinkingUpdate: onThinkingUpdate,
            onComplete: onComplete,
            isRetry: false
        )
    }
    
    /// 执行新 API 请求（内部方法）
    /// - Requirements: 4.1, 4.2, 4.3, 4.4, 2.7
    private func executeNewAPIRequest(
        messages: [ChatMessage],
        modelTier: ModelTier,
        thinking: Bool,
        onContentUpdate: @escaping (String) -> Void,
        onThinkingUpdate: ((String) -> Void)?,
        onComplete: @escaping NewChatCompletion,
        isRetry: Bool
    ) {
        // Check for ID Token (Cognito OAuth)
        // - Requirements: 4.1
        guard AuthService.shared.hasIdToken, let idToken = AuthService.shared.idToken else {
            print("[ClaudeflareClient] chatWithNewAPI: No ID Token available")
            DispatchQueue.main.async {
                onComplete(.failure(.authenticationError))
            }
            return
        }
        
        // Reset state
        resetState()
        self.onContentUpdate = onContentUpdate
        self.onThinkingUpdate = onThinkingUpdate
        
        // Store completion handler with usage support
        self.newAPICompletion = onComplete
        self.isNewAPIRequest = true
        self.isNewAPIRetry = isRetry
        
        print("[ClaudeflareClient] Starting new API chat request to \(jingBackendURL + newChatEndpoint), modelTier=\(modelTier.rawValue), thinking=\(thinking), isRetry=\(isRetry)")
        
        // Build HTTP request for new API
        guard let request = buildNewAPIRequest(
            messages: messages,
            modelTier: modelTier,
            thinking: thinking,
            idToken: idToken
        ) else {
            DispatchQueue.main.async {
                onComplete(.failure(.parseError("Failed to build request")))
            }
            return
        }
        
        // Create streaming session with delegate
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        currentSession = session
        
        let task = session.dataTask(with: request)
        currentTask = task
        task.resume()
    }
    
    /// 处理 401 错误，尝试刷新 Token 并重试
    /// - Requirements: 2.7
    private func handleNewAPI401Error() {
        guard let pending = pendingNewAPIRequest, !isNewAPIRetry else {
            // 已经是重试请求，不再重试
            print("[ClaudeflareClient] 401 error on retry, giving up")
            DispatchQueue.main.async { [weak self] in
                self?.newAPICompletion?(.failure(.authenticationError))
                self?.resetCallbacks()
            }
            return
        }
        
        print("[ClaudeflareClient] 401 error, attempting token refresh...")
        
        // 尝试刷新 Token
        Task { @MainActor in
            do {
                try await AuthService.shared.refreshTokens()
                print("[ClaudeflareClient] Token refreshed, retrying request...")
                
                // 用新 Token 重试请求
                self.executeNewAPIRequest(
                    messages: pending.messages,
                    modelTier: pending.modelTier,
                    thinking: pending.thinking,
                    onContentUpdate: pending.onContentUpdate,
                    onThinkingUpdate: pending.onThinkingUpdate,
                    onComplete: pending.onComplete,
                    isRetry: true
                )
            } catch {
                print("[ClaudeflareClient] Token refresh failed: \(error)")
                pending.onComplete(.failure(.authenticationError))
            }
        }
    }
    
    /// 构建新 API 请求
    /// - Requirements: 4.1, 4.2, 4.3, 4.4
    private func buildNewAPIRequest(
        messages: [ChatMessage],
        modelTier: ModelTier,
        thinking: Bool,
        idToken: String
    ) -> URLRequest? {
        // Build URL
        let fullURL = jingBackendURL + newChatEndpoint
        guard let url = URL(string: fullURL) else {
            print("[ClaudeflareClient] buildNewAPIRequest: Invalid URL: \(fullURL)")
            return nil
        }
        
        print("[ClaudeflareClient] buildNewAPIRequest: URL = \(fullURL)")
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        // - Requirements: 4.1 (Bearer idToken authentication)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        // Build request body
        // - Requirements: 4.2, 4.3, 4.4
        let chatRequest = NewChatRequest(
            messages: messages,
            modelTier: modelTier,
            thinking: thinking
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
            
            #if DEBUG
            if let bodyData = request.httpBody,
               let jsonString = String(data: bodyData, encoding: .utf8) {
                print("[ClaudeflareClient] New API request body: \(jsonString)")
            }
            #endif
        } catch {
            print("[ClaudeflareClient] Failed to encode new API request: \(error)")
            return nil
        }
        
        return request
    }
    
    // MARK: - New API State
    
    /// 待处理的新 API 请求（用于 401 重试）
    private struct PendingNewAPIRequest {
        let messages: [ChatMessage]
        let modelTier: ModelTier
        let thinking: Bool
        let onContentUpdate: (String) -> Void
        let onThinkingUpdate: ((String) -> Void)?
        let onComplete: NewChatCompletion
    }
    
    /// 待处理的新 API 请求
    private var pendingNewAPIRequest: PendingNewAPIRequest?
    
    /// 是否是新 API 重试请求
    private var isNewAPIRetry: Bool = false
    
    /// 新 API 完成回调
    private var newAPICompletion: NewChatCompletion?
    
    /// 是否是新 API 请求
    private var isNewAPIRequest: Bool = false
    
    /// 新 API 使用统计
    private var newAPIUsage: ChatUsage?
    
    // MARK: - TTS API (直接调用豆包语音合成)
    
    /// 豆包 TTS 配置
    private struct DoubaoTTSConfig {
        static let endpoint = "https://openspeech.bytedance.com/api/v1/tts"
        static let appId = "5198056637"
        static let token = "cSg5cY4qaonwaLxHMBXjf6_1wlqm9dSE"
        static let cluster = "volcano_tts"
        static let defaultVoice = "zh_female_shuangkuaisisi_moon_bigtts"
    }
    
    /// Generate speech from text using Doubao TTS API
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - voice: Voice to use (default: doubao voice)
    ///   - completion: Callback with audio data or error
    public func textToSpeech(
        text: String,
        voice: String? = nil,
        completion: @escaping (Result<Data, ClaudeflareError>) -> Void
    ) {
        print("[ClaudeflareClient] textToSpeech: Starting Doubao TTS request")
        
        guard let url = URL(string: DoubaoTTSConfig.endpoint) else {
            print("[ClaudeflareClient] textToSpeech: Invalid URL")
            DispatchQueue.main.async {
                completion(.failure(.parseError("Invalid URL")))
            }
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer;\(DoubaoTTSConfig.token)", forHTTPHeaderField: "Authorization")
        
        // Build Doubao TTS request body
        let requestId = UUID().uuidString
        let body: [String: Any] = [
            "app": [
                "appid": DoubaoTTSConfig.appId,
                "token": DoubaoTTSConfig.token,
                "cluster": DoubaoTTSConfig.cluster
            ],
            "user": ["uid": "ios_client"],
            "audio": [
                "voice_type": voice ?? DoubaoTTSConfig.defaultVoice,
                "encoding": "mp3"
            ],
            "request": [
                "reqid": requestId,
                "text": text,
                "text_type": "plain",
                "operation": "query"
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("[ClaudeflareClient] textToSpeech: Failed to encode request body")
            DispatchQueue.main.async {
                completion(.failure(.parseError("Failed to encode request")))
            }
            return
        }
        
        print("[ClaudeflareClient] textToSpeech: Sending request, text length: \(text.count)")
        
        // Create session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ClaudeflareClient] textToSpeech: Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ClaudeflareClient] textToSpeech: Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError("Invalid response")))
                }
                return
            }
            
            print("[ClaudeflareClient] textToSpeech: HTTP status = \(httpResponse.statusCode)")
            
            guard let data = data else {
                print("[ClaudeflareClient] textToSpeech: No data received")
                DispatchQueue.main.async {
                    completion(.failure(.parseError("No data received")))
                }
                return
            }
            
            // Parse Doubao response
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("[ClaudeflareClient] textToSpeech: Invalid JSON response")
                    DispatchQueue.main.async {
                        completion(.failure(.parseError("Invalid response format")))
                    }
                    return
                }
                
                let code = json["code"] as? Int ?? 0
                let message = json["message"] as? String ?? "Unknown error"
                
                // code 3000 = success
                guard code == 3000 else {
                    print("[ClaudeflareClient] textToSpeech: API error: code=\(code), message=\(message)")
                    DispatchQueue.main.async {
                        completion(.failure(.parseError("TTS错误: \(message)")))
                    }
                    return
                }
                
                // Decode base64 audio data
                guard let base64Data = json["data"] as? String,
                      let audioData = Data(base64Encoded: base64Data) else {
                    print("[ClaudeflareClient] textToSpeech: Failed to decode audio data")
                    DispatchQueue.main.async {
                        completion(.failure(.parseError("Failed to decode audio")))
                    }
                    return
                }
                
                print("[ClaudeflareClient] textToSpeech: Success, audio size: \(audioData.count) bytes")
                DispatchQueue.main.async {
                    completion(.success(audioData))
                }
            } catch {
                print("[ClaudeflareClient] textToSpeech: JSON parse error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.parseError("Failed to parse response")))
                }
            }
        }.resume()
    }

    
    // MARK: - State Management
    
    private func resetState() {
        streamBuffer = ""
        accumulatedContent = ""
        accumulatedThinking = ""
        isCancelled = false
        lastEventType = nil
        hasDataInCurrentEvent = false
        onContentUpdate = nil
        onThinkingUpdate = nil
        onComplete = nil
        // Reset new API state
        newAPICompletion = nil
        isNewAPIRequest = false
        newAPIUsage = nil
        isNewAPIRetry = false
        // Note: Don't reset pendingNewAPIRequest here as it's needed for retry
    }
    
    private func resetCallbacks() {
        onContentUpdate = nil
        onThinkingUpdate = nil
        onComplete = nil
        newAPICompletion = nil
        pendingNewAPIRequest = nil
    }
}


// MARK: - URLSessionDataDelegate for Streaming

extension ClaudeflareClient: URLSessionDataDelegate {
    
    /// Handle HTTP response
    /// - Requirements: 7.2, 7.3
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ClaudeflareClient] Invalid response type")
            completionHandler(.allow)
            return
        }
        
        let statusCode = httpResponse.statusCode
        print("[ClaudeflareClient] Received HTTP response: \(statusCode)")
        
        // Check for error status codes
        // Requirements: 7.2, 7.3
        if statusCode == 401 {
            // Authentication error
            // - Requirements: 2.7 (401 自动刷新重试)
            if self.isNewAPIRequest && !self.isNewAPIRetry {
                // 尝试刷新 Token 并重试
                self.handleNewAPI401Error()
                completionHandler(.cancel)
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isNewAPIRequest {
                    self.newAPICompletion?(.failure(.authenticationError))
                } else {
                    self.onComplete?(.failure(.authenticationError))
                }
                self.resetCallbacks()
            }
            completionHandler(.cancel)
            return
        }
        
        if statusCode == 429 {
            // Quota exceeded
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isNewAPIRequest {
                    self.newAPICompletion?(.failure(.quotaExceeded))
                } else {
                    self.onComplete?(.failure(.quotaExceeded))
                }
                self.resetCallbacks()
            }
            completionHandler(.cancel)
            return
        }
        
        if statusCode >= 400 {
            // Server error (4xx/5xx)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isNewAPIRequest {
                    self.newAPICompletion?(.failure(.serverError(statusCode)))
                } else {
                    self.onComplete?(.failure(.serverError(statusCode)))
                }
                self.resetCallbacks()
            }
            completionHandler(.cancel)
            return
        }
        
        completionHandler(.allow)
    }
    
    /// Handle incoming data chunks
    /// - Requirements: 4.1, 4.2, 4.3
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !isCancelled else { return }
        
        guard let chunk = String(data: data, encoding: .utf8) else {
            return
        }
        
        // Add to buffer and process
        streamBuffer += chunk
        processStreamBuffer()
    }
    
    /// Handle task completion
    /// - Requirements: 7.1, 7.4
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Don't process if already cancelled
            if self.isCancelled {
                print("[ClaudeflareClient] Request was cancelled")
                return
            }
            
            if let error = error {
                print("[ClaudeflareClient] Request failed: \(error.localizedDescription)")
                // Check if cancelled
                if (error as NSError).code == NSURLErrorCancelled {
                    if self.isNewAPIRequest {
                        self.newAPICompletion?(.failure(.cancelled))
                    } else {
                        self.onComplete?(.failure(.cancelled))
                    }
                } else {
                    // Network error
                    // Requirements: 7.1
                    if self.isNewAPIRequest {
                        self.newAPICompletion?(.failure(.networkError(error.localizedDescription)))
                    } else {
                        self.onComplete?(.failure(.networkError(error.localizedDescription)))
                    }
                }
            } else {
                // Success - return accumulated content
                print("[ClaudeflareClient] Request completed successfully, content length: \(self.accumulatedContent.count)")
                if self.isNewAPIRequest {
                    // 新 API 返回 usage 统计
                    self.newAPICompletion?(.success(self.newAPIUsage))
                } else {
                    self.onComplete?(.success(self.accumulatedContent))
                }
            }
            
            self.resetCallbacks()
        }
    }
    
    // MARK: - SSE Processing
    
    /// Process the stream buffer and extract content
    /// Handles new API SSE format
    /// - Requirements: 4.2, 4.3, 4.5, 4.6, 4.7
    private func processStreamBuffer() {
        // Split buffer into lines
        let lines = streamBuffer.components(separatedBy: "\n")
        var processedUpTo = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Empty line marks end of an SSE event
            if trimmedLine.isEmpty {
                processedUpTo = index + 1
                continue
            }
            
            // Parse data line (data: {...})
            if trimmedLine.hasPrefix("data:") {
                let dataContent = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                
                // Handle [DONE] marker
                if dataContent == "[DONE]" {
                    processedUpTo = index + 1
                    continue
                }
                
                // Skip empty data
                if dataContent.isEmpty {
                    processedUpTo = index + 1
                    continue
                }
                
                // Parse JSON chunk
                if let jsonData = dataContent.data(using: .utf8) {
                    // Process new API format
                    // - Requirements: 4.5, 4.6, 4.7
                    processNewAPISSEEvent(jsonData: jsonData)
                }
                
                processedUpTo = index + 1
                continue
            }
            
            // Skip event: and id: lines
            if trimmedLine.hasPrefix("event:") || trimmedLine.hasPrefix("id:") {
                processedUpTo = index + 1
                continue
            }
        }
        
        // Keep unprocessed data in buffer
        if processedUpTo > 0 && processedUpTo < lines.count {
            streamBuffer = lines[processedUpTo...].joined(separator: "\n")
        } else if processedUpTo == lines.count {
            streamBuffer = ""
        }
    }
    
    /// 处理新 API SSE 事件
    /// 格式: {"content": "...", "done": false} 或 {"thinking": "...", "done": false} 或 {"content": "", "done": true, "usage": {...}}
    /// - Requirements: 4.5, 4.6, 4.7
    private func processNewAPISSEEvent(jsonData: Data) {
        do {
            let event = try JSONDecoder().decode(ChatSSEEvent.self, from: jsonData)
            
            // 处理错误事件
            // - Requirements: 4.7
            if let error = event.error {
                let errorCode = event.errorCode ?? "UNKNOWN"
                print("[ClaudeflareClient] New API error: \(error), code: \(errorCode)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, !self.isCancelled else { return }
                    self.newAPICompletion?(.failure(.networkError("\(error) (\(errorCode))")))
                    self.resetCallbacks()
                }
                return
            }
            
            // 提取思考内容
            if let thinking = event.thinking, !thinking.isEmpty {
                accumulatedThinking += thinking
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, !self.isCancelled else { return }
                    self.onThinkingUpdate?(self.accumulatedThinking)
                }
            }
            
            // 提取内容
            // - Requirements: 4.5
            if let content = event.content, !content.isEmpty {
                accumulatedContent += content
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, !self.isCancelled else { return }
                    self.onContentUpdate?(self.accumulatedContent)
                }
            }
            
            // 处理完成事件，提取 usage 统计
            // - Requirements: 4.6
            if event.done {
                if let usage = event.usage {
                    newAPIUsage = usage
                    print("[ClaudeflareClient] New API done, usage: input=\(usage.inputTokens), output=\(usage.outputTokens), total=\(usage.totalTokens)")
                }
            }
        } catch {
            #if DEBUG
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[ClaudeflareClient] Failed to parse new API SSE JSON: \(error), data: \(jsonString.prefix(100))")
            }
            #endif
        }
    }
    
    /// Extract error message from JSON error data
    /// - Parameter jsonString: JSON string like {"code":"AI_ERROR","message":"服务繁忙"}
    /// - Returns: The message value, or the original string if parsing fails
    private func extractErrorMessage(from jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else {
            return jsonString
        }
        return message
    }
}

// MARK: - Error Mapping Utilities

extension ClaudeflareClient {
    
    /// Map HTTP status code to ClaudeflareError
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Corresponding ClaudeflareError
    /// - Requirements: 7.2, 7.3
    public static func mapStatusCodeToError(_ statusCode: Int) -> ClaudeflareError {
        switch statusCode {
        case 401:
            return .authenticationError
        case 429:
            return .quotaExceeded
        case 400..<500:
            return .serverError(statusCode)
        case 500..<600:
            return .serverError(statusCode)
        default:
            return .serverError(statusCode)
        }
    }
}
