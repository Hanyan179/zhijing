import Foundation

// MARK: - App Mode

/// Application mode for switching between Journal and AI conversation
public enum AppMode: String, Codable {
    case journal
    case ai
}

// MARK: - Message Role

/// Role of a message in AI conversation
public enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Attachment Type

/// Type of attachment in a message
public enum AttachmentType: String, Codable {
    case image
    case audio
    case file
}

// MARK: - Message Attachment

/// Attachment in an AI message (image, audio, or file)
public struct MessageAttachment: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let type: AttachmentType
    public let url: String
    public let name: String?
    public let duration: String?  // For audio attachments
    
    public init(
        id: String = UUID().uuidString,
        type: AttachmentType,
        url: String,
        name: String? = nil,
        duration: String? = nil
    ) {
        self.id = id
        self.type = type
        self.url = url
        self.name = name
        self.duration = duration
    }
}

// MARK: - AI Message

/// A single message in an AI conversation
public struct AIMessage: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let role: MessageRole
    public var content: String
    public var reasoningContent: String?  // AI thinking process
    public let timestamp: Date
    public var attachments: [MessageAttachment]?
    
    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        reasoningContent: String? = nil,
        timestamp: Date = Date(),
        attachments: [MessageAttachment]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.reasoningContent = reasoningContent
        self.timestamp = timestamp
        self.attachments = attachments
    }
}


// MARK: - AI Conversation

/// A complete AI conversation session containing multiple messages
public struct AIConversation: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String?
    public var messages: [AIMessage]
    public var dayId: String  // Primary day index (format: "yyyy.MM.dd") - L1 DayIndex association
    public var associatedDays: [String]  // ["2025.12.15", "2025.12.16"] - All days this conversation spans
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        messages: [AIMessage] = [],
        dayId: String = DateUtilities.today,
        associatedDays: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.dayId = dayId
        self.associatedDays = associatedDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Preview text from the first user message (truncated to 50 chars)
    public var previewText: String {
        guard let firstUserMessage = messages.first(where: { $0.role == .user }) else {
            return ""
        }
        let text = firstUserMessage.content
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
    
    /// Auto-generate title from first user message (truncated to 20 chars)
    public mutating func generateTitle() {
        guard title == nil,
              let firstUserMessage = messages.first(where: { $0.role == .user }) else {
            return
        }
        let text = firstUserMessage.content
        title = String(text.prefix(20))
    }
    
    /// Add a message and update timestamps
    public mutating func addMessage(_ message: AIMessage) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-add current day to associatedDays if not present
        let dayString = DateUtilities.formatDate(message.timestamp)
        if !associatedDays.contains(dayString) {
            associatedDays.append(dayString)
        }
        
        // Update dayId to the most recent day if conversation spans multiple days
        if let latestDay = associatedDays.last {
            dayId = latestDay
        }
    }
    
    /// Get messages sorted by timestamp (chronological order)
    public var sortedMessages: [AIMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Conversation Day Group

/// Group of conversations for a specific day (used in sidebar display)
public struct ConversationDayGroup: Equatable {
    public let date: String
    public let conversations: [AIConversation]
    
    public init(date: String, conversations: [AIConversation]) {
        self.date = date
        self.conversations = conversations
    }
}

// MARK: - Indexed Attachment

/// Processing state for attachments
public enum ProcessingState: String, Codable, Sendable {
    case pending      // 等待处理
    case processing   // 处理中（压缩/编码）
    case ready        // 准备就绪
    case failed       // 处理失败
}

/// Attachment with index for user reference (e.g., [1], [2], [3])
/// - Note: Used for multimodal messages where users can reference attachments by number
public struct IndexedAttachment: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let index: Int                    // 编号索引：1, 2, 3...
    public let attachment: MessageAttachment
    public let base64Data: String?           // Base64 编码数据（发送时使用）
    public let thumbnailData: Data?          // 缩略图数据（本地显示用）
    public let processingState: ProcessingState
    
    public init(
        id: String = UUID().uuidString,
        index: Int,
        attachment: MessageAttachment,
        base64Data: String? = nil,
        thumbnailData: Data? = nil,
        processingState: ProcessingState = .pending
    ) {
        self.id = id
        self.index = index
        self.attachment = attachment
        self.base64Data = base64Data
        self.thumbnailData = thumbnailData
        self.processingState = processingState
    }
    
    /// Create a copy with updated properties
    public func with(
        index: Int? = nil,
        base64Data: String? = nil,
        thumbnailData: Data? = nil,
        processingState: ProcessingState? = nil
    ) -> IndexedAttachment {
        IndexedAttachment(
            id: self.id,
            index: index ?? self.index,
            attachment: self.attachment,
            base64Data: base64Data ?? self.base64Data,
            thumbnailData: thumbnailData ?? self.thumbnailData,
            processingState: processingState ?? self.processingState
        )
    }
}

// MARK: - Attachment Type Extension

extension AttachmentType {
    /// Get MIME type for attachment
    public var mimeType: String {
        switch self {
        case .image:
            return "image/jpeg"  // 默认，实际根据文件扩展名确定
        case .audio:
            return "audio/mpeg"
        case .file:
            return "application/octet-stream"
        }
    }
    
    /// Get MIME type from file extension
    public static func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "md": return "text/markdown"
        case "json": return "application/json"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "csv": return "text/csv"
        case "rtf": return "application/rtf"
        case "xml": return "application/xml"
        case "html", "htm": return "text/html"
        default: return "application/octet-stream"
        }
    }
}
