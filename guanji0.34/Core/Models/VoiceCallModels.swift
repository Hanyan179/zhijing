import Foundation

// MARK: - Voice Call State

/// 语音通话状态
/// Requirements: 5.1
public enum CallState: Equatable {
    /// 空闲状态 - 未开始通话
    case idle
    /// 监听状态 - 正在识别用户语音
    case listening
    /// 处理状态 - AI 正在生成回复
    case processing
    /// 朗读状态 - AI 正在朗读回复
    case speaking
}

// MARK: - Voice Call Session

/// 语音通话会话数据
/// Requirements: 4.3
public struct VoiceCallSession {
    /// 当前通话状态
    public var state: CallState = .idle
    
    /// 用户说的话（实时识别）
    public var recognizedText: String = ""
    
    /// AI 回复的文字
    public var aiResponseText: String = ""
    
    /// 关联的对话 ID（用于保存对话记录）
    public var conversationId: String?
    
    /// 通话开始时间
    public var startTime: Date?
    
    /// 通话中收集的消息（用于结束时保存）
    public var messages: [VoiceCallMessage] = []
    
    public init(conversationId: String? = nil) {
        self.conversationId = conversationId
    }
}

// MARK: - Voice Call Message

/// 语音通话中的单条消息
public struct VoiceCallMessage: Identifiable {
    public let id: String
    public let role: MessageRole
    public let content: String
    public let timestamp: Date
    
    public enum MessageRole {
        case user
        case assistant
    }
    
    public init(role: MessageRole, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Voice Call Error

/// 语音通话错误类型
public enum VoiceCallError: Error, LocalizedError {
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case speechRecognizerUnavailable
    case audioSessionError(String)
    case recognitionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "需要麦克风权限才能进行语音通话"
        case .speechRecognitionPermissionDenied:
            return "需要语音识别权限才能理解您说的话"
        case .speechRecognizerUnavailable:
            return "语音识别服务暂不可用"
        case .audioSessionError(let message):
            return "音频会话错误: \(message)"
        case .recognitionFailed(let message):
            return "语音识别失败: \(message)"
        }
    }
}
