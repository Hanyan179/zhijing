import Foundation
import Speech
import AVFoundation
import Combine

/// 语音识别服务 - 封装 Speech Framework
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
@MainActor
public final class SpeechService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 是否正在监听
    @Published public private(set) var isListening = false
    
    /// 实时识别的文字
    @Published public private(set) var recognizedText = ""
    
    /// 错误信息
    @Published public private(set) var error: VoiceCallError?
    
    /// 当前音频电平 (0.0-1.0)，用于波形动画
    @Published public private(set) var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    /// 静音检测定时器
    private var silenceTimer: Timer?
    
    /// 静音阈值（秒）- 1.5秒无声音后触发回调
    private let silenceThreshold: TimeInterval = 1.5
    
    /// 静音检测回调
    private var onSilenceDetected: ((String) -> Void)?
    
    /// 上次识别到文字的时间
    private var lastSpeechTime: Date?
    
    /// 是否为连续监听模式（按住说话场景）
    private var isContinuousMode: Bool = false
    
    /// 累积的文字（用于连续模式下跨识别任务保留文字）
    private var accumulatedText: String = ""
    
    // MARK: - Initialization
    
    public init() {
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        let locale = Locale.current
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        }
    }
    
    // MARK: - Authorization
    
    public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }
    
    public func requestAuthorization() async -> Bool {
        let micGranted = await requestMicrophonePermission()
        guard micGranted else {
            error = .microphonePermissionDenied
            return false
        }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        continuation.resume(returning: true)
                    case .denied, .restricted:
                        self.error = .speechRecognitionPermissionDenied
                        continuation.resume(returning: false)
                    case .notDetermined:
                        continuation.resume(returning: false)
                    @unknown default:
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    public var hasPermission: Bool {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        return speechStatus == .authorized && micStatus == .authorized
    }
    
    // MARK: - Listening Control
    
    /// 开始监听语音（带静音检测）
    public func startListening(onSilenceDetected: @escaping (String) -> Void) {
        guard hasPermission else {
            error = .speechRecognitionPermissionDenied
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            error = .speechRecognizerUnavailable
            return
        }
        
        if isListening { stopListening() }
        
        self.onSilenceDetected = onSilenceDetected
        self.recognizedText = ""
        self.error = nil
        self.lastSpeechTime = Date()
        
        do {
            try startAudioSession()
            try startRecognition(recognizer: recognizer)
            startSilenceDetection()
            isListening = true
        } catch {
            self.error = .audioSessionError(error.localizedDescription)
            cleanup()
        }
    }
    
    /// 开始连续监听（按住说话模式，不会因静音自动停止）
    public func startContinuousListening() {
        guard hasPermission else {
            error = .speechRecognitionPermissionDenied
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            error = .speechRecognizerUnavailable
            return
        }
        
        if isListening { stopListening() }
        
        isContinuousMode = true
        accumulatedText = ""
        recognizedText = ""
        error = nil
        
        do {
            try startAudioSession()
            try startContinuousRecognition(recognizer: recognizer)
            isListening = true
        } catch {
            self.error = .audioSessionError(error.localizedDescription)
            isContinuousMode = false
            cleanup()
        }
    }
    
    /// 停止连续监听并返回累积的文字
    @discardableResult
    public func stopContinuousListening() -> String {
        let result = recognizedText
        isContinuousMode = false
        accumulatedText = ""
        cleanup()
        return result
    }
    
    /// 停止监听
    public func stopListening() {
        if isContinuousMode {
            _ = stopContinuousListening()
        } else {
            cleanup()
        }
    }

    
    // MARK: - Private Methods
    
    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startRecognition(recognizer: SFSpeechRecognizer) throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = recognitionRequest else {
            throw VoiceCallError.recognitionFailed("无法创建识别请求")
        }
        
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.calculateAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.lastSpeechTime = Date()
                    
                    if result.isFinal {
                        self.handleFinalResult()
                    }
                }
                
                if let error = error {
                    self.handleRecognitionError(error)
                }
            }
        }
    }
    
    private func startContinuousRecognition(recognizer: SFSpeechRecognizer) throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = recognitionRequest else {
            throw VoiceCallError.recognitionFailed("无法创建识别请求")
        }
        
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.calculateAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self, self.isContinuousMode else { return }
                
                if let result = result {
                    let currentText = result.bestTranscription.formattedString
                    if self.accumulatedText.isEmpty {
                        self.recognizedText = currentText
                    } else {
                        self.recognizedText = self.accumulatedText + " " + currentText
                    }
                    
                    if result.isFinal && self.isContinuousMode {
                        self.accumulatedText = self.recognizedText
                        self.restartContinuousListening()
                    }
                }
                
                if let error = error {
                    self.handleContinuousRecognitionError(error)
                }
            }
        }
    }
    
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
            return
        }
        
        if nsError.domain == "kAFAssistantErrorDomain" &&
           (nsError.code == 1110 || nsError.code == 203 || nsError.code == 1101) {
            if recognizedText.isEmpty && isListening {
                restartListening()
            }
            return
        }
        
        self.error = .recognitionFailed(error.localizedDescription)
        cleanup()
    }
    
    private func handleContinuousRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
            return
        }
        
        if nsError.domain == "kAFAssistantErrorDomain" &&
           (nsError.code == 1110 || nsError.code == 203 || nsError.code == 1101) {
            if isContinuousMode {
                if !recognizedText.isEmpty {
                    accumulatedText = recognizedText
                }
                restartContinuousListening()
            }
            return
        }
        
        self.error = .recognitionFailed(error.localizedDescription)
        isContinuousMode = false
        cleanup()
    }
    
    private func restartContinuousListening() {
        guard isContinuousMode else { return }
        
        cleanupForRestart()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, self.isContinuousMode else { return }
            guard let recognizer = self.speechRecognizer, recognizer.isAvailable else { return }
            
            do {
                try self.startAudioSession()
                try self.startContinuousRecognition(recognizer: recognizer)
                self.isListening = true
            } catch {
                self.error = .audioSessionError(error.localizedDescription)
                self.isContinuousMode = false
                self.cleanup()
            }
        }
    }
    
    private func restartListening() {
        guard let callback = onSilenceDetected else { return }
        let previousText = recognizedText
        
        cleanupForRestart()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.startListeningWithPreviousText(previousText: previousText, onSilenceDetected: callback)
        }
    }
    
    private func startListeningWithPreviousText(previousText: String, onSilenceDetected: @escaping (String) -> Void) {
        guard hasPermission else {
            error = .speechRecognitionPermissionDenied
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            error = .speechRecognizerUnavailable
            return
        }
        
        if isListening { stopListening() }
        
        self.onSilenceDetected = onSilenceDetected
        if !previousText.isEmpty { self.recognizedText = previousText }
        self.error = nil
        self.lastSpeechTime = Date()
        
        do {
            try startAudioSession()
            try startRecognitionWithPreviousText(recognizer: recognizer, previousText: previousText)
            startSilenceDetection()
            isListening = true
        } catch {
            self.error = .audioSessionError(error.localizedDescription)
            cleanup()
        }
    }

    
    private func startRecognitionWithPreviousText(recognizer: SFSpeechRecognizer, previousText: String) throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = recognitionRequest else {
            throw VoiceCallError.recognitionFailed("无法创建识别请求")
        }
        
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.calculateAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    if previousText.isEmpty {
                        self.recognizedText = newText
                    } else {
                        self.recognizedText = previousText + " " + newText
                    }
                    self.lastSpeechTime = Date()
                    
                    if result.isFinal {
                        self.handleFinalResult()
                    }
                }
                
                if let error = error {
                    self.handleRecognitionError(error)
                }
            }
        }
    }
    
    private func cleanupForRestart() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isListening = false
        lastSpeechTime = nil
    }
    
    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkSilence()
            }
        }
    }
    
    private func checkSilence() {
        guard isListening,
              let lastTime = lastSpeechTime,
              !recognizedText.isEmpty else { return }
        
        let silenceDuration = Date().timeIntervalSince(lastTime)
        
        if silenceDuration >= silenceThreshold {
            let text = recognizedText
            onSilenceDetected?(text)
            cleanup()
        }
    }
    
    private func handleFinalResult() {
        guard !recognizedText.isEmpty else { return }
        let text = recognizedText
        onSilenceDetected?(text)
        cleanup()
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        
        let db = 20 * log10(max(rms, 0.0001))
        let normalizedLevel = max(0, min(1, (db + 50) / 40))
        
        Task { @MainActor [weak self] in
            self?.audioLevel = normalizedLevel
        }
    }
    
    private func cleanup() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isListening = false
        onSilenceDetected = nil
        lastSpeechTime = nil
        audioLevel = 0.0
        isContinuousMode = false
        accumulatedText = ""
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.cleanup()
        }
    }
}
