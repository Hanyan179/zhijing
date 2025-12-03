import SwiftUI
import Combine

public final class InputViewModel: ObservableObject {
    @Published public var isMenuOpen: Bool = false
    @Published public var isRecording: Bool = false
    @Published public var recordingSeconds: Int = 0
    @Published public var text: String = ""
    @Published public var replyContext: String? = nil
    public struct AttachmentItem: Identifiable, Hashable { public let id: String; public let type: String; public let name: String; public init(id: String = UUID().uuidString, type: String, name: String) { self.id = id; self.type = type; self.name = name } }
    @Published public var attachments: [AttachmentItem] = []
    private var timer: Timer?

    public init() {}

    public func toggleMenu() { isMenuOpen.toggle() }
    public func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recordingSeconds = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.recordingSeconds += 1 }
    }
    public func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    public func toggleRecording() { isRecording ? stopRecording() : startRecording() }
    public func cancelRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        recordingSeconds = 0
    }
    public func submit() { text = ""; attachments.removeAll() }
    public func addPhoto(name: String) { attachments.append(AttachmentItem(type: "photo", name: name)) }
    public func addFile(name: String) { attachments.append(AttachmentItem(type: "file", name: name)) }
    public func removeAttachment(id: String) { attachments.removeAll { $0.id == id } }
    deinit { timer?.invalidate() }
}
