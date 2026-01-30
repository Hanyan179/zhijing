import Foundation

// MARK: - Model Capability Configuration

/// 模型能力配置
/// 描述特定 AI 模型支持的功能和限制
/// Validates: Requirements 1.1, 1.2, 1.3, 1.4
public struct ModelCapability: Codable, Equatable, Sendable {
    /// 模型唯一标识符
    public let modelId: String
    
    /// 显示名称
    public let displayName: String
    
    /// 支持的图片 MIME 类型
    public let supportedImageTypes: [String]
    
    /// 支持的文档 MIME 类型
    public let supportedDocumentTypes: [String]
    
    /// 支持的音频 MIME 类型
    public let supportedAudioTypes: [String]
    
    /// 支持的视频 MIME 类型
    public let supportedVideoTypes: [String]
    
    /// 图片大小限制（字节）
    public let maxImageSize: Int
    
    /// 文档大小限制（字节）
    public let maxDocumentSize: Int
    
    /// 单次请求最大附件数量
    public let maxAttachmentCount: Int
    
    /// 是否支持思考模式
    public let supportsThinking: Bool
    
    /// 是否支持多模态输入
    public let supportsMultimodal: Bool
    
    // MARK: - Initialization
    
    public init(
        modelId: String,
        displayName: String,
        supportedImageTypes: [String],
        supportedDocumentTypes: [String],
        supportedAudioTypes: [String],
        supportedVideoTypes: [String],
        maxImageSize: Int,
        maxDocumentSize: Int,
        maxAttachmentCount: Int,
        supportsThinking: Bool,
        supportsMultimodal: Bool
    ) {
        self.modelId = modelId
        self.displayName = displayName
        self.supportedImageTypes = supportedImageTypes
        self.supportedDocumentTypes = supportedDocumentTypes
        self.supportedAudioTypes = supportedAudioTypes
        self.supportedVideoTypes = supportedVideoTypes
        self.maxImageSize = maxImageSize
        self.maxDocumentSize = maxDocumentSize
        self.maxAttachmentCount = maxAttachmentCount
        self.supportsThinking = supportsThinking
        self.supportsMultimodal = supportsMultimodal
    }
    
    // MARK: - Computed Properties
    
    /// 所有支持的 MIME 类型
    public var allSupportedMimeTypes: [String] {
        supportedImageTypes + supportedDocumentTypes +
        supportedAudioTypes + supportedVideoTypes
    }
    
    // MARK: - Public Methods
    
    /// 检查 MIME 类型是否支持
    /// - Parameter mimeType: 要检查的 MIME 类型
    /// - Returns: 是否支持该 MIME 类型
    public func isMimeTypeSupported(_ mimeType: String) -> Bool {
        allSupportedMimeTypes.contains(mimeType.lowercased())
    }
    
    /// 获取文件大小限制（根据 MIME 类型）
    /// - Parameter mimeType: 文件的 MIME 类型
    /// - Returns: 对应的大小限制（字节）
    public func getSizeLimit(for mimeType: String) -> Int {
        if supportedImageTypes.contains(mimeType.lowercased()) {
            return maxImageSize
        }
        return maxDocumentSize
    }
}

// MARK: - Gemini Default Configurations

/// Gemini 模型默认能力配置
/// Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7
public extension ModelCapability {
    
    // MARK: - Size Constants
    
    /// 20MB in bytes (for images)
    private static let twentyMB = 20 * 1024 * 1024
    
    /// 50MB in bytes (for documents)
    private static let fiftyMB = 50 * 1024 * 1024
    
    // MARK: - Supported MIME Types
    
    /// Gemini 支持的图片 MIME 类型
    /// Validates: Requirement 2.1
    private static let geminiImageTypes: [String] = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
        "image/heic"
    ]
    
    /// Gemini 支持的音频 MIME 类型
    /// Validates: Requirement 2.2
    private static let geminiAudioTypes: [String] = [
        "audio/mpeg",
        "audio/wav",
        "audio/ogg"
    ]
    
    /// Gemini 支持的视频 MIME 类型
    /// Validates: Requirement 2.3
    private static let geminiVideoTypes: [String] = [
        "video/mp4",
        "video/webm",
        "video/quicktime"
    ]
    
    /// Gemini 支持的文档 MIME 类型
    /// Validates: Requirement 2.4
    private static let geminiDocumentTypes: [String] = [
        "application/pdf",
        "text/plain",
        "text/markdown",
        "application/json"
    ]
    
    // MARK: - Model Configurations
    
    /// Gemini 3 Flash Preview 默认配置
    /// - 支持图片: jpeg, png, gif, webp, heic (Requirement 2.1)
    /// - 支持音频: mpeg, wav, ogg (Requirement 2.2)
    /// - 支持视频: mp4, webm, quicktime (Requirement 2.3)
    /// - 支持文档: pdf, plain text, markdown, json (Requirement 2.4)
    /// - 图片大小限制: 20MB (Requirement 2.5)
    /// - 文档大小限制: 50MB (Requirement 2.6)
    /// - 附件数量限制: 10 (Requirement 2.7)
    static let gemini3FlashPreview = ModelCapability(
        modelId: "gemini-3-flash-preview",
        displayName: "Gemini 3 Flash",
        supportedImageTypes: geminiImageTypes,
        supportedDocumentTypes: geminiDocumentTypes,
        supportedAudioTypes: geminiAudioTypes,
        supportedVideoTypes: geminiVideoTypes,
        maxImageSize: twentyMB,
        maxDocumentSize: fiftyMB,
        maxAttachmentCount: 10,
        supportsThinking: true,
        supportsMultimodal: true
    )
    
    /// Gemini 3 Pro Preview 默认配置
    /// - 支持图片: jpeg, png, gif, webp, heic (Requirement 2.1)
    /// - 支持音频: mpeg, wav, ogg (Requirement 2.2)
    /// - 支持视频: mp4, webm, quicktime (Requirement 2.3)
    /// - 支持文档: pdf, plain text, markdown, json (Requirement 2.4)
    /// - 图片大小限制: 20MB (Requirement 2.5)
    /// - 文档大小限制: 50MB (Requirement 2.6)
    /// - 附件数量限制: 10 (Requirement 2.7)
    static let gemini3ProPreview = ModelCapability(
        modelId: "gemini-3-pro-preview",
        displayName: "Gemini 3 Pro",
        supportedImageTypes: geminiImageTypes,
        supportedDocumentTypes: geminiDocumentTypes,
        supportedAudioTypes: geminiAudioTypes,
        supportedVideoTypes: geminiVideoTypes,
        maxImageSize: twentyMB,
        maxDocumentSize: fiftyMB,
        maxAttachmentCount: 10,
        supportsThinking: true,
        supportsMultimodal: true
    )
    
    /// 所有可用的 Gemini 模型配置
    static let allGeminiModels: [ModelCapability] = [
        gemini3FlashPreview,
        gemini3ProPreview
    ]
}
