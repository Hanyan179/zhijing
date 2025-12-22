import Foundation

// MARK: - SiliconFlow API Request Models

/// Chat completion request for SiliconFlow API (Qwen/QwQ-32B model)
public struct ChatCompletionRequest: Codable {
    public let model: String
    public let messages: [ChatMessage]
    public let stream: Bool
    public let maxTokens: Int
    public let enableThinking: Bool?
    public let thinkingBudget: Int?
    public let temperature: Double
    public let topP: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature
        case maxTokens = "max_tokens"
        case enableThinking = "enable_thinking"
        case thinkingBudget = "thinking_budget"
        case topP = "top_p"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(topP, forKey: .topP)
        
        // Only encode thinking parameters if they are present (not nil)
        // AND if the model actually supports them (QwQ-32B DOES NOT)
        if model != "Qwen/QwQ-32B" {
            if let enableThinking = enableThinking {
                try container.encode(enableThinking, forKey: .enableThinking)
            }
            if let thinkingBudget = thinkingBudget {
                try container.encode(thinkingBudget, forKey: .thinkingBudget)
            }
        }
    }
    
    public init(
        model: String = "Qwen/QwQ-32B",
        messages: [ChatMessage],
        stream: Bool = true,
        maxTokens: Int = 4096,
        enableThinking: Bool = false,
        thinkingBudget: Int = 2048,
        temperature: Double = 0.7,
        topP: Double = 0.9
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.maxTokens = maxTokens
        if enableThinking {
            self.enableThinking = true
            self.thinkingBudget = thinkingBudget
        } else {
            self.enableThinking = nil
            self.thinkingBudget = nil
        }
        self.temperature = temperature
        self.topP = topP
    }
    
    /// Message in chat completion request
    public struct ChatMessage: Codable {
        public let role: String
        public let content: String
        
        public init(role: String, content: String) {
            self.role = role
            self.content = content
        }
        
        /// Create from AIMessage
        public init(from message: AIMessage) {
            self.role = message.role.rawValue
            self.content = message.content
        }
    }
}


// MARK: - SiliconFlow API Response Models

/// Chat completion response from SiliconFlow API
public struct ChatCompletionResponse: Codable, Sendable {
    public let id: String
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [Choice]
    public let usage: Usage?
    
    public struct Choice: Codable, Sendable {
        public let index: Int?
        public let message: Message
        public let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
        
        public struct Message: Codable, Sendable {
            public let role: String
            public let content: String
            public let reasoningContent: String?
            
            enum CodingKeys: String, CodingKey {
                case role, content
                case reasoningContent = "reasoning_content"
            }
        }
    }
    
    public struct Usage: Codable, Sendable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Streaming Response Models

/// Stream chunk for Server-Sent Events (SSE) response
public struct StreamChunk: Codable {
    public let id: String
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [StreamChoice]
    
    public struct StreamChoice: Codable {
        public let index: Int?
        public let delta: Delta
        public let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
        
        public struct Delta: Codable {
            public let role: String?
            public let content: String?
            public let reasoningContent: String?
            
            enum CodingKeys: String, CodingKey {
                case role, content
                case reasoningContent = "reasoning_content"
            }
        }
    }
}

// MARK: - API Error Models

/// Error response from SiliconFlow API
public struct APIErrorResponse: Codable, Sendable {
    public let error: APIError
    
    public struct APIError: Codable, Sendable {
        public let message: String
        public let type: String?
        public let code: String?
    }
}

/// AI Service error types
public enum AIServiceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError(Error)
    case streamingError(String)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
