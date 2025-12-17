import SwiftUI
import Combine
import AVFoundation
import Speech

public final class InputViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published public var isMenuOpen: Bool = false
    @Published public var isRecording: Bool = false
    @Published public var recordingSeconds: Int = 0
    @Published public var text: String = ""
    @Published public var replyContext: String? = nil
    @Published public var replyQuestionId: String? = nil
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
    
    deinit { timer?.invalidate() }
}
