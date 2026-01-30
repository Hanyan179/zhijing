import SwiftUI

public struct CapsuleDetailSheet: View {
    public let question: QuestionEntry
    public let sourceEntry: JournalEntry?
    public let replies: [JournalEntry]
    public let onReply: (String) -> Void
    public let onClose: () -> Void
    public let lang: Lang
    
    // We reuse the lightweight components from InputDock
    @StateObject private var inputVM = InputViewModel()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var timelineVM: TimelineViewModel
    
    public init(question: QuestionEntry, sourceEntry: JournalEntry?, replies: [JournalEntry], onReply: @escaping (String) -> Void, onClose: @escaping () -> Void, lang: Lang) {
        self.question = question
        self.sourceEntry = sourceEntry
        self.replies = replies
        self.onReply = onReply
        self.onClose = onClose
        self.lang = lang
    }
    
    private var creationDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        guard let date = formatter.date(from: question.created_at) else { return question.created_at }
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if daysAgo == 0 {
            return question.created_at + " · " + Localization.tr("today", lang: lang)
        } else {
            return question.created_at + " · \(daysAgo)" + Localization.tr("daysAgoSuffix", lang: lang)
        }
    }
    
    private func getReplyType(reply: JournalEntry, index: Int) -> String {
        // Logic Update:
        // 1. Check if the reply is on the SAME DAY as the delivery date (or created date if delivery not set).
        // 2. If it's same day -> "Reply" (or "Same Day")
        // 3. If it's later -> "Follow Up"
        // 4. Overdue logic remains
        
        let replyDateStr = reply.metadata?.createdDate ?? ""
        let deliveryDateStr = question.delivery_date
        
        // If reply is AFTER delivery date (day level), it's a follow-up or overdue
        // We need robust date comparison, but string comparison works for yyyy.MM.dd
        if replyDateStr > deliveryDateStr {
             // If it's significantly later, maybe Overdue? Or just Follow Up?
             // User said "Only first one is same day" was wrong.
             // Actually, "Same Day" should mean "Replied on the intended delivery day".
             // "Follow Up" should mean "Replied on a LATER date".
             return Localization.tr("replyFollowUp", lang: lang)
        }
        
        return Localization.tr("replySameDay", lang: lang)
    }
    
    private func replyBadgeColor(type: String) -> Color {
        if type == Localization.tr("replyFollowUp", lang: lang) { return Colors.blue }
        if type == Localization.tr("replyOverdue", lang: lang) { return Colors.red }
        return Colors.green
    }
    
    private var liveReplies: [JournalEntry] {
        // Merge initial replies with any new ones found in the current timeline
        // This ensures that when we send a reply, it appears immediately if the timeline updates
        let currentItems = timelineVM.items.flatMap { item -> [JournalEntry] in
            switch item {
            case .scene(let s): return s.entries
            case .journey(let j): return j.entries
            }
        }.filter { $0.metadata?.questionId == question.id }
        
        let oldIds = Set(replies.map { $0.id })
        let distinctNew = currentItems.filter { !oldIds.contains($0.id) }
        return replies + distinctNew
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Header Info (Date & Source)
                        HStack {
                            Text(creationDateText).font(.caption).fontWeight(.medium).foregroundColor(Colors.systemGray)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // 2. The Question/Prompt
                        VStack(alignment: .leading, spacing: 12) {
                            if let prompt = question.system_prompt, !prompt.isEmpty {
                                Text(prompt).font(.title3).fontWeight(.semibold).foregroundColor(Colors.slateText).fixedSize(horizontal: false, vertical: true).lineSpacing(4)
                            } else {
                                Text(Localization.tr("lockedMemory", lang: lang)).font(.title3).foregroundColor(Colors.systemGray)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Context (Source Entry)
                        if let src = sourceEntry {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "quote.opening").font(.caption).foregroundColor(Colors.indigo)
                                    Text(Localization.tr("past", lang: lang)).font(.caption).fontWeight(.bold).foregroundColor(Colors.indigo).textCase(.uppercase)
                                }
                                SpecialContentRenderer(entry: src)
                                    .padding(12)
                                    .background(Colors.indigo.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Colors.indigo.opacity(0.1), lineWidth: 1))
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        // 4. Replies List
                        if liveReplies.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 48)).foregroundColor(Colors.systemGray.opacity(0.2))
                                Text(Localization.tr("waitingEchoes", lang: lang)).font(.subheadline).foregroundColor(Colors.systemGray)
                            }
                            .frame(maxWidth: .infinity).padding(.top, 20)
                        } else {
                            VStack(alignment: .leading, spacing: 24) {
                                ForEach(Array(liveReplies.enumerated()), id: \.element.id) { index, reply in
                                    let type = getReplyType(reply: reply, index: index)
                                    let badgeColor = replyBadgeColor(type: type)
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack {
                                            Circle().fill(badgeColor).frame(width: 8, height: 8)
                                            if index < liveReplies.count - 1 { Rectangle().fill(Colors.slateLight).frame(width: 1) }
                                        }
                                        .frame(width: 16)
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(type).font(.caption2).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(badgeColor).cornerRadius(4)
                                                
                                                // Display full date + time for ALL replies as per user request
                                                if let created = reply.metadata?.createdDate {
                                                    Text(created + " " + reply.timestamp).font(.caption2).foregroundColor(Colors.systemGray)
                                                } else {
                                                    Text(reply.timestamp).font(.caption2).foregroundColor(Colors.systemGray)
                                                }
                                                
                                                Spacer()
                                            }
                                            SpecialContentRenderer(entry: reply, textStyle: .body)
                                                .padding(12).background(Color(.secondarySystemBackground)).cornerRadius(12)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal).padding(.bottom, 20)
                        }
                    }
                }
                
                // 5. Input Area (Reusing InputDock Logic)
                VStack(spacing: 8) {
                    if let ctx = inputVM.replyContext {
                        ReplyContextBar(text: ctx, onCancel: { inputVM.replyContext = nil })
                    }
                    if !inputVM.attachments.isEmpty { AttachmentsBar(items: inputVM.attachments, onRemove: { inputVM.removeAttachment(id: $0) }) }
                    
                    // Quick Actions (Simplified for Detail Sheet)
                    if inputVM.showAppsMenu {
                        InputQuickActions(onGallery: { handleGallery() }, 
                                          onCamera: { handleCamera() }, 
                                          onRecord: { inputVM.toggleRecording() }, 
                                          onTimeCapsule: { }, 
                                          onMood: { }, 
                                          onFile: { handleFileUpload() }, 
                                          onMore: { },
                                          showTimeCapsule: false,
                                          showMood: false)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 4)
                    }
                    
                    DockContainer(isMenuOpen: false, isReplyMode: false) {
                        HStack(spacing: 10) {
                            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { inputVM.showAppsMenu.toggle() } }) {
                                Image(systemName: "plus").font(.system(size: 20, weight: .medium)).rotationEffect(.degrees(inputVM.showAppsMenu ? 45 : 0)).foregroundColor(Colors.slateText).frame(width: 32, height: 32).background(Color(.systemGray6)).clipShape(Circle())
                            }
                            TextField(Localization.tr("placeholder", lang: lang), text: $inputVM.text, axis: .vertical)
                                .lineLimit(1...5).textFieldStyle(.plain).padding(.vertical, 8).padding(.horizontal, 8)
                            SubmitButton(hasText: !inputVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !inputVM.attachments.isEmpty, onClick: {
                                inputVM.replyQuestionId = question.id
                                inputVM.submit()
                            })
                        }
                    }
                    if inputVM.isRecording {
                        RecordingBar(isRecording: inputVM.isRecording, duration: inputVM.recordingSeconds, onStart: { inputVM.startRecording() }, onStop: { inputVM.stopRecording() }, onCancel: { inputVM.cancelRecording() }).padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
                .background(Color(UIColor.systemBackground))
                .onChange(of: inputVM.isRecording) { recording in
                    if recording {
                        inputVM.replyQuestionId = question.id
                    }
                }
            }
            .background(Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.body).foregroundColor(Colors.indigo)
                    }
                }
            }
            // Media Pickers
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerSheet { imgs in 
                    if !imgs.isEmpty { 
                        inputVM.pendingImages = imgs
                        inputVM.replyQuestionId = question.id // Ensure linkage
                        inputVM.submit() 
                    } 
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureSheet { img, url in 
                    if let i = img { 
                        inputVM.addPhoto(name: "Camera", image: i)
                        inputVM.replyQuestionId = question.id // Ensure linkage for camera
                        inputVM.submit()
                    } else if let u = url {
                        inputVM.importFile(url: u)
                        inputVM.replyQuestionId = question.id
                        inputVM.submit()
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker { urls in
                    for url in urls {
                        inputVM.importFile(url: url)
                    }
                    // Submit immediately after selection
                    inputVM.replyQuestionId = question.id
                    inputVM.submit()
                }
            }
        }
    }
    
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showFilePicker = false
    
    // Helper stubs for media actions (since we are inside a struct, we need to bridge to state)
    private func handleGallery() { showPhotoPicker = true }
    private func handleCamera() { showCamera = true }
    private func handleFileUpload() { showFilePicker = true }
}
