import Foundation

// MARK: - Model Tier (New API)

/// 模型档次 (新 API)
/// - Requirements: 4.2, 4.3
public enum ModelTier: String, Codable, CaseIterable, Sendable {
    /// 快速模型 - 响应最快，适合简单任务
    case fast = "fast"
    /// 平衡模型 - 速度和质量平衡
    case balanced = "balanced"
    /// 强力模型 - 最高质量，适合复杂任务
    case powerful = "powerful"
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .fast: return "快速"
        case .balanced: return "平衡"
        case .powerful: return "强力"
        }
    }
    
    /// 描述
    public var description: String {
        switch self {
        case .fast: return "响应最快，适合简单任务"
        case .balanced: return "速度和质量平衡"
        case .powerful: return "最高质量，适合复杂任务"
        }
    }
}

// MARK: - New Chat API Models

/// 新 API 聊天请求 (POST /api/chat)
/// - Requirements: 4.1, 4.2, 4.3, 4.4
public struct NewChatRequest: Codable, Sendable {
    /// 对话消息数组
    public let messages: [ChatMessage]
    /// 模型档次
    public let modelTier: String
    /// 是否启用思考模式
    public let thinking: Bool
    
    enum CodingKeys: String, CodingKey {
        case messages
        case modelTier = "model_tier"
        case thinking
    }
    
    public init(messages: [ChatMessage], modelTier: ModelTier = .balanced, thinking: Bool = false) {
        self.messages = messages
        self.modelTier = modelTier.rawValue
        self.thinking = thinking
    }
}

/// SSE 事件 (新 API 响应格式)
/// - Requirements: 4.5, 4.6, 4.7
public struct ChatSSEEvent: Codable, Sendable, Equatable {
    /// 内容片段
    public let content: String?
    /// 思考内容（仅 thinking=true 时有值）
    public let thinking: String?
    /// 是否完成
    public let done: Bool
    /// 使用统计（仅在 done=true 时有值）
    public let usage: ChatUsage?
    /// 错误消息
    public let error: String?
    /// 错误码
    public let errorCode: String?
    
    enum CodingKeys: String, CodingKey {
        case content, thinking, done, usage, error
        case errorCode = "error_code"
    }
    
    public init(
        content: String? = nil,
        thinking: String? = nil,
        done: Bool = false,
        usage: ChatUsage? = nil,
        error: String? = nil,
        errorCode: String? = nil
    ) {
        self.content = content
        self.thinking = thinking
        self.done = done
        self.usage = usage
        self.error = error
        self.errorCode = errorCode
    }
}

/// 使用统计 (新 API)
/// - Requirements: 4.6
public struct ChatUsage: Codable, Sendable, Equatable {
    /// 输入 token 数
    public let inputTokens: Int
    /// 输出 token 数
    public let outputTokens: Int
    /// 总 token 数
    public let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
    
    public init(inputTokens: Int, outputTokens: Int, totalTokens: Int) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
    }
}

// MARK: - Claudeflare Gateway Request Models

/// Chat message for Claudeflare Gateway API
/// - Note: Used in ChatRequest to send messages to the Gateway
public struct ChatMessage: Codable, Sendable, Equatable {
    /// Message role: "user", "assistant", or "system"
    public let role: String
    /// Message content
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

/// Chat request body for Claudeflare Gateway API
/// - Note: Sent as JSON to /api/v1/chat endpoint
public struct ChatRequest: Codable, Sendable {
    /// Array of chat messages
    public let messages: [ChatMessage]
    /// Model identifier (required): gemini-flash, gemini-pro, qwq-32b, deepseek-v3
    public let model: String
    /// Whether to enable thinking mode (optional, default false)
    public let enableThinking: Bool?
    /// User context for personalized prompts (optional)
    public let userContext: UserContext?
    /// User language for localized error messages (optional, e.g., "zh", "en", "ja", "ko")
    public let language: String?
    
    public init(
        messages: [ChatMessage],
        model: String = "gemini-flash",
        enableThinking: Bool? = nil,
        userContext: UserContext? = nil,
        language: String? = nil
    ) {
        self.messages = messages
        self.model = model
        self.enableThinking = enableThinking
        self.userContext = userContext
        self.language = language
    }
}

// MARK: - Multimodal Message Models

/// Inline data for multimodal content (Base64 encoded)
public struct InlineData: Codable, Sendable, Equatable {
    public let mimeType: String
    public let data: String  // Base64 encoded
    
    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
    
    public init(mimeType: String, data: String) {
        self.mimeType = mimeType
        self.data = data
    }
}

/// Part type for multimodal messages
public enum PartType: String, Codable, Sendable {
    case text
    case inlineData = "inline_data"
}

/// A single part of a multimodal message
public struct MessagePart: Codable, Sendable, Equatable {
    /// Content type
    public let type: PartType
    /// Text content (when type == .text)
    public let text: String?
    /// Inline data (when type == .inlineData)
    public let inlineData: InlineData?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case inlineData = "inline_data"
    }
    
    public init(type: PartType, text: String? = nil, inlineData: InlineData? = nil) {
        self.type = type
        self.text = text
        self.inlineData = inlineData
    }
    
    /// Create a text part
    public static func text(_ content: String) -> MessagePart {
        MessagePart(type: .text, text: content, inlineData: nil)
    }
    
    /// Create an image part
    public static func image(mimeType: String, base64Data: String) -> MessagePart {
        MessagePart(type: .inlineData, text: nil, inlineData: InlineData(mimeType: mimeType, data: base64Data))
    }
    
    /// Create a file part
    public static func file(mimeType: String, base64Data: String) -> MessagePart {
        MessagePart(type: .inlineData, text: nil, inlineData: InlineData(mimeType: mimeType, data: base64Data))
    }
}

/// Multimodal chat message supporting text and attachments
public struct MultimodalChatMessage: Codable, Sendable, Equatable {
    public let role: String
    public let parts: [MessagePart]
    
    public init(role: String, parts: [MessagePart]) {
        self.role = role
        self.parts = parts
    }
    
    /// Create from pure text
    public init(role: String, content: String) {
        self.role = role
        self.parts = [.text(content)]
    }
    
    /// Create from text and attachments
    public init(role: String, content: String, attachments: [IndexedAttachment]) {
        self.role = role
        var parts: [MessagePart] = []
        
        // Add attachments first
        for attachment in attachments {
            if let base64 = attachment.base64Data {
                // Determine MIME type based on attachment type and file extension
                let mimeType: String
                if attachment.attachment.type == .file,
                   let fileName = attachment.attachment.name {
                    // For files, use file extension to get accurate MIME type
                    let fileExtension = (fileName as NSString).pathExtension
                    mimeType = AttachmentType.mimeType(for: fileExtension)
                } else {
                    // For images/audio, use default MIME type
                    mimeType = attachment.attachment.type.mimeType
                }
                
                // Use .file() for document types, .image() for images
                if attachment.attachment.type == .file {
                    parts.append(.file(mimeType: mimeType, base64Data: base64))
                } else {
                    parts.append(.image(mimeType: mimeType, base64Data: base64))
                }
            }
        }
        
        // Add text content
        parts.append(.text(content))
        
        self.parts = parts
    }
    
    /// Create from AIMessage
    public init(from message: AIMessage) {
        self.role = message.role.rawValue
        self.parts = [.text(message.content)]
    }
}

/// Multimodal chat request body
public struct MultimodalChatRequest: Codable, Sendable {
    /// Array of multimodal messages
    public let messages: [MultimodalChatMessage]
    /// Model identifier
    public let model: String
    /// Whether to enable thinking mode
    public let enableThinking: Bool?
    /// User context
    public let userContext: UserContext?
    /// User language
    public let language: String?
    
    public init(
        messages: [MultimodalChatMessage],
        model: String,
        enableThinking: Bool? = nil,
        userContext: UserContext? = nil,
        language: String? = nil
    ) {
        self.messages = messages
        self.model = model
        self.enableThinking = enableThinking
        self.userContext = userContext
        self.language = language
    }
}

/// User context for personalized prompts
public struct UserContext: Codable, Sendable, Equatable {
    public let userId: String?
    public let preferences: [String: String]?
    
    public init(userId: String? = nil, preferences: [String: String]? = nil) {
        self.userId = userId
        self.preferences = preferences
    }
}


// MARK: - Available Models

/// Available AI models from new-api server
public struct AIModel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let provider: String
    public let description: String
    public let supportsThinking: Bool
    public let recommended: [String]  // Region codes: US, EU, CN, etc.
    
    public init(
        id: String,
        name: String,
        provider: String,
        description: String,
        supportsThinking: Bool,
        recommended: [String]
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.description = description
        self.supportsThinking = supportsThinking
        self.recommended = recommended
    }
}

/// Model utilities
public extension AIModel {
    /// Check if model supports thinking mode based on model ID
    /// Models with "thinking", "qwq", or "deepseek-r1" in name support thinking
    static func supportsThinking(_ modelId: String) -> Bool {
        let lowercased = modelId.lowercased()
        return lowercased.contains("thinking") ||
               lowercased.contains("qwq") ||
               lowercased.contains("deepseek-r1")
    }
    
    /// Create AIModel from ServerModelInfo
    static func from(_ serverModel: ServerModelInfo) -> AIModel {
        AIModel(
            id: serverModel.id,
            name: serverModel.id,
            provider: serverModel.ownedBy ?? "unknown",
            description: "",
            supportsThinking: supportsThinking(serverModel.id),
            recommended: []
        )
    }
}


// MARK: - Claudeflare Gateway Error Types

/// Server model info from /v1/models endpoint
public struct ServerModelInfo: Codable, Identifiable, Equatable {
    public let id: String
    public let object: String?
    public let created: Int?
    public let ownedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
    }
    
    public init(id: String, object: String? = nil, created: Int? = nil, ownedBy: String? = nil) {
        self.id = id
        self.object = object
        self.created = created
        self.ownedBy = ownedBy
    }
}

/// Response from /v1/models endpoint
public struct ModelsListResponse: Codable {
    public let object: String
    public let data: [ServerModelInfo]
}

/// Error types for Claudeflare Gateway client
/// - Note: Implements LocalizedError for user-friendly error messages
/// - Requirements: 7.1, 7.2, 7.3, 7.4
public enum ClaudeflareError: Error, LocalizedError, Equatable {
    /// Token not configured
    case notConfigured
    /// Network connection error
    /// - Requirements: 7.4
    case networkError(String)
    /// Authentication failed (HTTP 401)
    /// - Requirements: 7.1
    case authenticationError
    /// Server error (HTTP 4xx/5xx)
    /// - Requirements: 7.3
    case serverError(Int)
    /// Response parsing error
    case parseError(String)
    /// Request was cancelled
    case cancelled
    /// Invalid model
    case invalidModel(String)
    /// Quota exceeded (HTTP 429)
    /// - Requirements: 7.2
    case quotaExceeded
    
    /// 用户友好的错误描述
    /// - Requirements: 7.1, 7.2, 7.3, 7.4
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Token 未配置"
        case .networkError:
            // Requirements: 7.4
            return "网络连接失败，请检查网络"
        case .authenticationError:
            // Requirements: 7.1
            return "会话已过期，请重新登录"
        case .serverError(let code):
            // Requirements: 7.3
            if code == 502 || code == 503 {
                return "服务暂时不可用，请稍后重试"
            }
            return "服务器错误，请稍后重试"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .cancelled:
            return "请求已取消"
        case .invalidModel(let model):
            return "模型不可用: \(model)"
        case .quotaExceeded:
            // Requirements: 7.2
            return "使用额度已用完，请稍后再试"
        }
    }
    
    /// 错误代码，用于日志和调试
    /// - Requirements: 7.5, 7.6
    public var errorCode: String {
        switch self {
        case .notConfigured:
            return "CHAT_NOT_CONFIGURED"
        case .networkError:
            return "CHAT_NETWORK_ERROR"
        case .authenticationError:
            return "CHAT_401_AUTH_ERROR"
        case .serverError(let code):
            return "CHAT_\(code)_SERVER_ERROR"
        case .parseError:
            return "CHAT_PARSE_ERROR"
        case .cancelled:
            return "CHAT_CANCELLED"
        case .invalidModel:
            return "CHAT_INVALID_MODEL"
        case .quotaExceeded:
            return "CHAT_429_QUOTA_EXCEEDED"
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ClaudeflareError, rhs: ClaudeflareError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured):
            return true
        case (.networkError(let lhsMsg), .networkError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.authenticationError, .authenticationError):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.parseError(let lhsMsg), .parseError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.cancelled, .cancelled):
            return true
        case (.invalidModel(let lhsModel), .invalidModel(let rhsModel)):
            return lhsModel == rhsModel
        case (.quotaExceeded, .quotaExceeded):
            return true
        default:
            return false
        }
    }
}
