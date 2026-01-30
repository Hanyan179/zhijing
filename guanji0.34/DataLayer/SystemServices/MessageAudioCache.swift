import Foundation
import AVFoundation

/// 消息音频缓存管理器
/// 负责缓存和播放消息的 TTS 音频
@MainActor
public final class MessageAudioCache: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = MessageAudioCache()
    
    // MARK: - Published Properties
    
    /// 当前正在播放的消息 ID
    @Published public private(set) var playingMessageId: String?
    
    /// 当前正在加载的消息 ID
    @Published public private(set) var loadingMessageId: String?
    
    /// 错误信息
    @Published public private(set) var error: String?
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private let fileManager = FileManager.default
    
    /// 缓存目录
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("MessageAudio", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 播放消息音频
    /// 如果已缓存则直接播放，否则先生成再播放
    /// - Parameters:
    ///   - messageId: 消息 ID
    ///   - text: 消息文本
    public func playAudio(for messageId: String, text: String) {
        // 如果正在播放同一条消息，停止播放
        if playingMessageId == messageId {
            stopPlayback()
            return
        }
        
        // 停止当前播放
        stopPlayback()
        
        // 检查缓存
        let cacheURL = cacheURL(for: messageId)
        if fileManager.fileExists(atPath: cacheURL.path) {
            print("[MessageAudioCache] Playing cached audio for message: \(messageId)")
            playFromFile(cacheURL, messageId: messageId)
            return
        }
        
        // 生成音频
        generateAndPlay(messageId: messageId, text: text)
    }
    
    /// 停止播放
    public func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingMessageId = nil
    }
    
    /// 检查消息是否有缓存的音频
    public func hasCache(for messageId: String) -> Bool {
        let cacheURL = cacheURL(for: messageId)
        return fileManager.fileExists(atPath: cacheURL.path)
    }
    
    /// 清除所有缓存
    public func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    private func cacheURL(for messageId: String) -> URL {
        // 使用 messageId 的 hash 作为文件名，避免特殊字符问题
        let fileName = "\(messageId.hashValue).mp3"
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    private func generateAndPlay(messageId: String, text: String) {
        loadingMessageId = messageId
        error = nil
        
        ClaudeflareClient.shared.textToSpeech(text: text) { [weak self] result in
            guard let self = self else { return }
            
            self.loadingMessageId = nil
            
            switch result {
            case .success(let audioData):
                // 保存到缓存
                let cacheURL = self.cacheURL(for: messageId)
                do {
                    try audioData.write(to: cacheURL)
                    print("[MessageAudioCache] Saved audio to cache: \(cacheURL.lastPathComponent)")
                    
                    // 播放
                    self.playFromFile(cacheURL, messageId: messageId)
                } catch {
                    print("[MessageAudioCache] Failed to save audio: \(error.localizedDescription)")
                    self.error = "保存音频失败"
                }
                
            case .failure(let error):
                print("[MessageAudioCache] TTS failed: \(error.localizedDescription)")
                switch error {
                case .serverError(let code):
                    self.error = "服务器错误 (\(code))"
                case .authenticationError:
                    self.error = "认证失败，请重新登录"
                case .parseError(let msg):
                    self.error = msg
                default:
                    self.error = "生成语音失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func playFromFile(_ url: URL, messageId: String) {
        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // 创建播放器
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            playingMessageId = messageId
            print("[MessageAudioCache] Started playing audio for message: \(messageId)")
        } catch {
            print("[MessageAudioCache] Failed to play audio: \(error.localizedDescription)")
            self.error = "播放失败"
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension MessageAudioCache: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playingMessageId = nil
            self.audioPlayer = nil
            print("[MessageAudioCache] Finished playing audio")
        }
    }
    
    nonisolated public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.playingMessageId = nil
            self.audioPlayer = nil
            self.error = "音频解码错误"
            print("[MessageAudioCache] Audio decode error: \(error?.localizedDescription ?? "unknown")")
        }
    }
}
