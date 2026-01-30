import SwiftUI
import Combine
import AVFoundation
import Speech

/// 输入模式枚举
/// Requirements: 3.1, 3.2
public enum InputMode: Equatable {
    case text   // 文本输入模式（键盘）
    case voice  // 语音输入模式（按住说话）
}

public final class InputViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published public var isMenuOpen: Bool = false
    @Published public var isRecording: Bool = false
    @Published public var recordingSeconds: Int = 0
    @Published public var text: String = ""
    @Published public var replyContext: String? = nil
    @Published public var replyQuestionId: String? = nil
    
    // MARK: - Voice Input Mode Properties (Requirements: 3.1, 3.2)
    
    /// 当前输入模式
    @Published public var inputMode: InputMode = .text
    
    /// 是否正在进行语音转文字
    @Published public var isTranscribing: Bool = false
    
    /// 语音转文字的实时结果
    @Published public var transcribedText: String = ""
    
    /// 是否正在长按录音（按住说话状态）
    @Published public var isPressToSpeak: Bool = false
    public struct AttachmentItem: Identifiable, Hashable { 
        public let id: String
        public let type: String
        public let name: String
        public let url: URL? 
        public init(id: String = UUID().uuidString, type: String, name: String, url: URL? = nil) { 
            self.id = id; self.type = type; self.name = name; self.url = url 
        } 
    }
    @Published public var attachments: [AttachmentItem] = []
    @Published public var showAppsMenu: Bool = false 
    public var pendingImages: [UIImage] = []
    
    private var timer: Timer?
    private let audioQueue = DispatchQueue(label: "com.guanji.audio", qos: .userInitiated)
    private var isSettingUp = false
    
    private var audioRecorder: AVAudioRecorder?
    private var currentAudioPath: URL?
    
    // MARK: - Voice Transcription Dependencies
    
    /// SpeechService 实例，用于语音转文字
    private var speechService: SpeechService?
    
    /// 语音转文字错误信息
    @Published public var transcriptionError: VoiceCallError?
    
    /// 当前音频电平 (0.0-1.0)，用于波形动画
    @Published public var audioLevel: Float = 0.0

    public override init() { super.init() }

    public func toggleMenu() { isMenuOpen.toggle() }
    
    public func startRecording() {
        guard !isRecording, !isSettingUp else { return }
        isSettingUp = true
        
        let audioSession = AVAudioSession.sharedInstance()
        
        // Request Permission
        audioSession.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            guard allowed else {
                self.cleanupSetupFailure()
                return
            }
            
            self.audioQueue.async {
                do {
                    try audioSession.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
                    try audioSession.setActive(true)
                    
                    let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
                    self.currentAudioPath = path
                    
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    self.audioRecorder = try AVAudioRecorder(url: path, settings: settings)
                    self.audioRecorder?.delegate = self
                    self.audioRecorder?.prepareToRecord()
                    
                    if self.audioRecorder?.record() == true {
                        DispatchQueue.main.async {
                            self.isRecording = true
                            self.isSettingUp = false
                            self.recordingSeconds = 0
                            self.timer?.invalidate()
                            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.recordingSeconds += 1 }
                        }
                    } else {
                        print("Audio Recorder failed to start")
                        self.cleanupSetupFailure()
                    }
                    
                } catch {
                    print("Audio Setup Failed: \(error)")
                    self.cleanupSetupFailure()
                }
            }
        }
    }
    
    private func cleanupSetupFailure() {
        DispatchQueue.main.async {
            self.isSettingUp = false
            self.isRecording = false
        }
    }
    
    public func stopRecording() {
        guard isRecording || isSettingUp else { return }
        
        isRecording = false
        isSettingUp = false
        timer?.invalidate()
        timer = nil
        
        audioQueue.async { [weak self] in
            self?.audioRecorder?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        
        // Auto-submit as requested by user
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.submit()
        }
    }
    
    public func toggleRecording() { isRecording ? stopRecording() : startRecording() }
    
    public func cancelRecording() {
        isRecording = false
        isSettingUp = false
        timer?.invalidate()
        timer = nil
        audioQueue.async { [weak self] in
            self?.audioRecorder?.stop()
            self?.audioRecorder?.deleteRecording()
        }
        currentAudioPath = nil
        text = ""
    }
    
    public func submit() {
        if isRecording { stopRecording() }
        
        var payload: [String: Any] = [
            "text": text,
            "replyQuestionId": replyQuestionId ?? "",
            "images": pendingImages
        ]
        
        if let audio = currentAudioPath {
            payload["audio"] = audio
            payload["duration"] = String(format: "%02d:%02d", recordingSeconds / 60, recordingSeconds % 60)
        }
        
        let files = attachments.compactMap { $0.url }
        if !files.isEmpty {
            payload["files"] = files
        }
        
        NotificationCenter.default.post(name: Notification.Name("gj_submit_input"), object: nil, userInfo: payload)
        
        text = ""
        attachments.removeAll()
        pendingImages.removeAll()
        replyContext = nil
        replyQuestionId = nil
        currentAudioPath = nil
        recordingSeconds = 0
    }
    
    public func addPhoto(name: String, image: UIImage?) { 
        attachments.append(AttachmentItem(type: "photo", name: name))
        if let img = image { pendingImages.append(img) }
    }
    
    public func addFile(name: String, url: URL) { 
        attachments.append(AttachmentItem(type: "file", name: name, url: url)) 
    }
    
    public func importFile(url: URL, isAudio: Bool = false) {
        // Persist file to Documents directory
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let filename = UUID().uuidString + "_" + url.lastPathComponent
        let dest = docs.appendingPathComponent(filename)
        
        do {
            // If file exists, remove it
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            // Copy (or move if possible, but copy is safer from picker)
            try fileManager.copyItem(at: url, to: dest)
            
            // Store relative path (filename) or absolute URL?
            // FileEntry logic handles both, but prefers relative for portability.
            // However, AttachmentItem takes a URL.
            // If we pass the absolute URL of the new location, FileEntry will see "file://" and use it.
            // That works.
            
            if isAudio {
                // For audio, we might want to set currentAudioPath or just add as attachment
                // User said "upload their own recording file". 
                // It should probably be treated as an attachment.
                addFile(name: url.lastPathComponent, url: dest)
            } else {
                addFile(name: url.lastPathComponent, url: dest)
            }
        } catch {
            print("Failed to persist file: \(error)")
        }
    }
    
    public func removeAttachment(id: String) { 
        if let idx = attachments.firstIndex(where: { $0.id == id }) {
            attachments.remove(at: idx)
            if idx < pendingImages.count { pendingImages.remove(at: idx) }
        }
    }
    
    // MARK: - Voice Transcription Methods (Requirements: 3.4, 3.5, 3.6, 3.7, 6.3)
    
    /// 开始语音转文字
    /// - 集成现有 SpeechService 进行实时语音识别
    /// Requirements: 3.4
    public func startVoiceTranscription() {
        guard !isTranscribing else { return }
        
        isTranscribing = true
        transcriptionError = nil
        transcribedText = ""
        
        Task { @MainActor in
            // 初始化 SpeechService（如果尚未初始化）
            if self.speechService == nil {
                self.speechService = SpeechService()
            }
            
            guard let service = self.speechService else {
                self.isTranscribing = false
                return
            }
            
            // 检查权限
            guard service.hasPermission else {
                // 请求权限
                let granted = await service.requestAuthorization()
                if granted {
                    // 权限获取成功，重新开始
                    self.isTranscribing = false
                    self.startVoiceTranscription()
                } else {
                    self.transcriptionError = .speechRecognitionPermissionDenied
                    self.isTranscribing = false
                }
                return
            }
            
            // 使用连续监听模式（按住说话场景）
            // 不会因为静音而自动停止，用户暂停说话后继续说话，文字会累积
            service.startContinuousListening()
            
            // 订阅实时识别结果（在 MainActor 上下文中）
            self.setupSpeechServiceObservers(service: service)
        }
    }
    
    /// 停止语音转文字
    /// - 停止录音并将转录文本追加到现有文本
    /// Requirements: 3.5, 6.3
    public func stopVoiceTranscription() {
        guard isTranscribing else { return }
        
        Task { @MainActor in
            // 使用连续监听的停止方法，获取最终文字
            if let service = self.speechService {
                let finalText = service.stopContinuousListening()
                if !finalText.isEmpty {
                    self.transcribedText = finalText
                }
            }
        }
        
        // 将转录文本追加到现有文本（Requirements: 6.3）
        appendTranscribedText()
        
        // 重置状态
        isTranscribing = false
        
        // 如果有文本，自动提交
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.submit()
            }
        }
    }
    
    /// 停止语音转文字（编辑模式）
    /// - 停止录音并将转录文本追加到现有文本，但不自动发送
    /// - 用户可以编辑文本后手动发送
    public func stopVoiceTranscriptionForEdit() {
        guard isTranscribing else { return }
        
        Task { @MainActor in
            // 使用连续监听的停止方法，获取最终文字
            if let service = self.speechService {
                let finalText = service.stopContinuousListening()
                if !finalText.isEmpty {
                    self.transcribedText = finalText
                }
            }
        }
        
        // 将转录文本追加到现有文本
        appendTranscribedText()
        
        // 重置状态
        isTranscribing = false
        
        // 不自动提交，让用户编辑
    }
    
    /// 取消语音转文字
    /// - 取消录音，不插入任何文字
    /// Requirements: 3.6
    public func cancelVoiceTranscription() {
        guard isTranscribing else { return }
        
        Task { @MainActor in
            self.speechService?.stopContinuousListening()
        }
        
        // 清除转录文本，不追加到输入框
        transcribedText = ""
        
        // 重置状态
        isTranscribing = false
    }
    
    /// 将转录文本追加到现有文本
    /// Requirements: 6.3 - 转录文字应该追加到现有文本后面，而不是替换
    private func appendTranscribedText() {
        guard !transcribedText.isEmpty else { return }
        
        if text.isEmpty {
            text = transcribedText
        } else {
            // 追加到现有文本，用空格分隔
            text = text + " " + transcribedText
        }
        
        // 清除转录文本
        transcribedText = ""
    }
    
    /// 订阅 SpeechService 的实时更新
    private var speechServiceCancellable: AnyCancellable?
    
    /// 设置 SpeechService 观察者（必须在 MainActor 上下文中调用）
    @MainActor
    private func setupSpeechServiceObservers(service: SpeechService) {
        // 取消之前的订阅
        speechServiceCancellable?.cancel()
        cancellables.removeAll()
        
        // 订阅实时识别结果 - 累积保存，不覆盖之前的内容
        speechServiceCancellable = service.$recognizedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                // 如果新文字不为空，更新转录文字
                // SpeechService 的 recognizedText 本身是累积的，直接使用
                self.transcribedText = text
            }
        
        // 订阅音频电平
        service.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)
        
        // 订阅错误
        service.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.transcriptionError = error
                    self?.isTranscribing = false
                }
            }
            .store(in: &cancellables)
    }
    
    /// Combine 订阅存储
    private var cancellables = Set<AnyCancellable>()
    
    deinit { timer?.invalidate() }
}
