import Foundation
import AVFoundation
import UIKit
import Combine

/// 语音合成服务 - 封装 AVSpeechSynthesizer
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
@MainActor
public final class TTSService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// 是否正在朗读
    @Published public private(set) var isSpeaking = false
    
    /// 当前朗读进度 (0.0 - 1.0)
    @Published public private(set) var progress: Double = 0
    
    /// 错误信息
    @Published public private(set) var error: TTSError?
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    
    /// 朗读完成回调
    private var onComplete: (() -> Void)?
    
    /// 当前朗读的文字总长度（用于计算进度）
    private var totalCharacters: Int = 0
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 朗读文字
    /// - Parameters:
    ///   - text: 要朗读的文字
    ///   - onComplete: 朗读完成回调
    public func speak(_ text: String, onComplete: @escaping () -> Void) {
        // 如果正在朗读，先停止
        if isSpeaking {
            stop()
        }
        
        // 检查文字是否为空
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onComplete()
            return
        }
        
        self.onComplete = onComplete
        self.totalCharacters = text.count
        self.progress = 0
        self.error = nil
        
        do {
            try configureAudioSession()
            
            let utterance = createUtterance(for: text)
            synthesizer.speak(utterance)
            isSpeaking = true
        } catch {
            self.error = .audioSessionError(error.localizedDescription)
            onComplete()
        }
    }
    
    /// 停止朗读
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        cleanup()
    }
    
    /// 暂停朗读
    public func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }
    
    /// 继续朗读
    public func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    /// 打开系统 Siri 语音设置
    /// Requirements: 6.1, 6.2, 6.3
    public static func openSiriSettings() {
        // 尝试打开 Siri 设置页面
        if let url = URL(string: "App-prefs:SIRI") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // 回退到通用设置
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    /// 配置音频会话
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// 创建语音合成 utterance
    /// - Parameter text: 要朗读的文字
    /// - Returns: 配置好的 AVSpeechUtterance
    private func createUtterance(for text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        
        // 自动检测语言并选择合适的声音
        let voice = selectVoice(for: text)
        utterance.voice = voice
        
        // 配置语速和音调
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 添加适当的停顿
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        return utterance
    }
    
    /// 根据文字内容选择合适的声音
    /// Requirements: 2.5, 3.5
    /// - Parameter text: 要朗读的文字
    /// - Returns: 选择的声音，如果没有合适的则返回 nil（使用系统默认）
    private func selectVoice(for text: String) -> AVSpeechSynthesisVoice? {
        // 检测文字语言
        let detectedLanguage = detectLanguage(for: text)
        
        // 优先使用增强版声音（Siri 声音）
        if let enhancedVoice = findEnhancedVoice(for: detectedLanguage) {
            return enhancedVoice
        }
        
        // 回退到普通声音
        return AVSpeechSynthesisVoice(language: detectedLanguage)
    }
    
    /// 检测文字语言
    /// - Parameter text: 要检测的文字
    /// - Returns: 语言代码（如 "zh-CN", "en-US"）
    private func detectLanguage(for text: String) -> String {
        // 使用 NSLinguisticTagger 检测语言
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text
        
        if let language = tagger.dominantLanguage {
            // 将语言代码转换为 TTS 支持的格式
            return mapLanguageCode(language)
        }
        
        // 默认使用系统语言
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "zh"
        return mapLanguageCode(systemLanguage)
    }
    
    /// 将语言代码映射到 TTS 支持的格式
    private func mapLanguageCode(_ code: String) -> String {
        switch code.lowercased() {
        case "zh", "zh-hans", "zh-cn":
            return "zh-CN"
        case "zh-hant", "zh-tw", "zh-hk":
            return "zh-TW"
        case "en", "en-us":
            return "en-US"
        case "en-gb":
            return "en-GB"
        case "ja":
            return "ja-JP"
        case "ko":
            return "ko-KR"
        default:
            return code
        }
    }
    
    /// 查找增强版声音（Siri 声音）
    private func findEnhancedVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // 优先查找增强版声音
        let enhancedVoice = voices.first { voice in
            voice.language.hasPrefix(language.prefix(2).lowercased()) &&
            voice.quality == .enhanced
        }
        
        if let voice = enhancedVoice {
            return voice
        }
        
        // 查找默认声音
        return voices.first { voice in
            voice.language.lowercased().hasPrefix(language.prefix(2).lowercased())
        }
    }
    
    /// 清理资源
    private func cleanup() {
        isSpeaking = false
        progress = 0
        totalCharacters = 0
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        // 触发完成回调
        let callback = onComplete
        onComplete = nil
        callback?()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService: AVSpeechSynthesizerDelegate {
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.cleanup()
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.cleanup()
        }
    }
    
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // 更新朗读进度
            if self.totalCharacters > 0 {
                let spokenCharacters = characterRange.location + characterRange.length
                self.progress = Double(spokenCharacters) / Double(self.totalCharacters)
            }
        }
    }
}

// MARK: - TTS Error

/// TTS 错误类型
public enum TTSError: Error, LocalizedError {
    case audioSessionError(String)
    case synthesisError(String)
    
    public var errorDescription: String? {
        switch self {
        case .audioSessionError(let message):
            return "音频会话错误: \(message)"
        case .synthesisError(let message):
            return "语音合成错误: \(message)"
        }
    }
}
