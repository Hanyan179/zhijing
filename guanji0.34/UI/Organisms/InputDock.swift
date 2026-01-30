import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
@MainActor
public struct InputDock: View {
    @StateObject private var vm = InputViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var showAudioPicker = false
    @State private var permissionAlert: String? = nil
    @FocusState private var inputFocused: Bool
    @State private var showMoreActions = false
    @State private var showExpandedInput = false
    @State private var showVoiceCall = false
    
    /// Voice input mode state
    @State private var voiceCancelled = false
    @State private var voicePressing = false
    
    /// Thinking mode state (synced with AIConversationViewModel via notification)
    @State private var thinkingModeEnabled = false
    
    /// Selected model tier (synced with AIConversationViewModel via notification)
    @State private var selectedModelTier: ModelTier = .balanced
    
    /// Show model selector sheet
    @State private var showModelSelector = false
    
    /// Attachment manager for AI mode (shared with AIConversationViewModel)
    @ObservedObject private var attachmentManager: AttachmentManager
    
    public init(attachmentManager: AttachmentManager) {
        self._attachmentManager = ObservedObject(wrappedValue: attachmentManager)
    }
    public var body: some View {
        // 主内容
        VStack(spacing: 8) {
            if let ctx = vm.replyContext {
                ReplyContextBar(text: ctx, onCancel: { vm.replyContext = nil })
            }
        
        // Show different attachment bars based on mode
        if appState.currentMode == .ai {
                    // AI mode: show indexed attachments from AttachmentManager
                    if !attachmentManager.pendingAttachments.isEmpty {
                        AttachmentPreviewBar(
                            attachments: attachmentManager.pendingAttachments,
                            onRemove: { id in attachmentManager.removeAttachment(id: id) }
                        )
                }
                
                // Show error message if any
                if let errorMsg = attachmentManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button(action: { attachmentManager.errorMessage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            } else {
                // Journal mode: show simple attachments from InputViewModel
                if !vm.attachments.isEmpty {
                    AttachmentsBar(items: vm.attachments, onRemove: { vm.removeAttachment(id: $0) })
                }
            }
            
            // Quick Action Bar - separate from input card (mode toggle + thinking)
            quickActionBar
                .padding(.bottom, 4)
            
            // Mode Toggle Bar (Journal/AI) - above input field
            // Requirements: 1.1, 1.2, 1.3, 2.1
            // Now a single icon button in the input row instead of above
            
            // Main input area - unified card (input + menu)
            if vm.isRecording {
                RecordingBar(isRecording: vm.isRecording, duration: vm.recordingSeconds, onStart: { }, onStop: { vm.stopRecording() }, onCancel: { vm.cancelRecording() })
                    .padding(.horizontal, 16)
            } else if vm.inputMode == .voice {
                // Voice input mode layout
                inputCard(content: voiceModeContent, showMenu: vm.showAppsMenu)
            } else {
                // Text input mode layout
                inputCard(content: textModeContent, showMenu: vm.showAppsMenu)
            }
            
            // Expandable Menu Panel is now inside unifiedInputCard
        } // end VStack
        .animation(.easeInOut, value: inputFocused)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.inputMode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.showAppsMenu)
        .fullScreenCover(isPresented: $showExpandedInput) {
            ExpandedInputView(vm: vm, isPresented: $showExpandedInput)
        }
        .fullScreenCover(isPresented: $showVoiceCall) {
            VoiceCallScreen(conversationId: appState.currentConversationId)
        }
        
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerSheet { imgs in
                if !imgs.isEmpty {
                    // In AI mode, use AttachmentManager for indexed attachments
                    if appState.currentMode == .ai {
                        Task { @MainActor in
                            try? await attachmentManager.addImages(imgs)
                        }
                    } else {
                        // In journal mode, direct send
                        vm.pendingImages = imgs
                        vm.submit()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureSheet { img, url in
                if let i = img {
                    // In AI mode, use AttachmentManager for indexed attachments
                    if appState.currentMode == .ai {
                        Task { @MainActor in
                            try? await attachmentManager.addImages([i])
                        }
                    } else {
                        // In journal mode, direct send
                        vm.pendingImages = [i]
                        vm.submit()
                    }
                } else if let u = url {
                    if appState.currentMode == .ai {
                        Task { @MainActor in
                            try? await attachmentManager.addFiles([u])
                        }
                    } else {
                        vm.importFile(url: u)
                        vm.submit()
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker { urls in
                if appState.currentMode == .ai {
                    // AI mode: use AttachmentManager for indexed attachments
                    Task { @MainActor in
                        try? await attachmentManager.addFiles(urls)
                    }
                } else {
                    // Journal mode: use InputViewModel and submit
                    for url in urls {
                        vm.importFile(url: url)
                    }
                    vm.submit()
                }
            }
        }
        .sheet(isPresented: $showAudioPicker) {
            DocumentPicker(types: [.audio]) { urls in
                if appState.currentMode == .ai {
                    // AI mode: use AttachmentManager for indexed attachments
                    Task { @MainActor in
                        try? await attachmentManager.addFiles(urls)
                    }
                } else {
                    // Journal mode: use InputViewModel and submit
                    for url in urls {
                        vm.importFile(url: url, isAudio: true)
                    }
                    vm.submit()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_initiate_reply"))) { note in
            if let dict = note.userInfo as? [String: Any] {
                vm.replyContext = dict["text"] as? String
                vm.replyQuestionId = dict["id"] as? String
                inputFocused = true
            }
        }
        .alert(isPresented: Binding(get: { permissionAlert != nil }, set: { if !$0 { permissionAlert = nil } })) {
            Alert(
                title: Text(Localization.tr("privacyTitle")),
                message: Text(permissionAlert ?? ""),
                primaryButton: .default(Text(Localization.tr("openSettings")), action: {
                    #if os(iOS)
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    #endif
                    permissionAlert = nil
                }),
                secondaryButton: .cancel(Text(Localization.tr("cancel")), action: { permissionAlert = nil })
            )
        }
    }
    
    // MARK: - Layout Views
    
    /// Input Card - combines input and menu into one card (without quick actions)
    @ViewBuilder
    private func inputCard<Content: View>(content: Content, showMenu: Bool) -> some View {
        VStack(spacing: 0) {
            // Input content
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            
            // Expandable menu (inside the card)
            if showMenu {
                Divider()
                    .padding(.horizontal, 12)
                
                menuGrid
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
        }
        .background(inputCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    /// Quick Action Bar - separate from input card
    @ViewBuilder
    private var quickActionBar: some View {
        HStack(spacing: 12) {
            // Mode toggle button (Journal/AI)
            Button(action: {
                handleModeToggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: appState.currentMode == .journal ? "sparkles" : "pencil.line")
                        .font(.subheadline)
                    Text(appState.currentMode == .journal ? "AI" : "笔记")
                        .font(.subheadline)
                }
                .foregroundColor(Colors.slateText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)  // Prevent double-tap issues
            
            // Thinking mode toggle (AI mode only)
            if appState.currentMode == .ai {
                Button(action: {
                    thinkingModeEnabled.toggle()
                    NotificationCenter.default.post(
                        name: Notification.Name("gj_thinking_mode_changed"),
                        object: nil,
                        userInfo: ["enabled": thinkingModeEnabled]
                    )
                    #if canImport(UIKit)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    #endif
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.subheadline)
                        Text("思考")
                            .font(.subheadline)
                    }
                    .foregroundColor(thinkingModeEnabled ? Colors.indigo : Colors.slateText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(thinkingModeEnabled ? Colors.indigo.opacity(0.15) : Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // 桌宠机器人（AI 模式下显示）
            if appState.currentMode == .ai {
                Button(action: { showModelSelector = true }) {
                    RobotAvatarMood(
                        mindValence: appState.robotMindValence,
                        bodyEnergy: appState.robotBodyEnergy,
                        theme: colorScheme == .dark ? .dark : .light,
                        size: 80,
                        modelTier: selectedModelTier,
                        thinkingMode: thinkingModeEnabled
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(0.5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_thinking_mode_sync"))) { notification in
            if let enabled = notification.userInfo?["enabled"] as? Bool {
                thinkingModeEnabled = enabled
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_model_tier_sync"))) { notification in
            if let tierRaw = notification.userInfo?["tier"] as? String,
               let tier = ModelTier(rawValue: tierRaw) {
                selectedModelTier = tier
            }
        }
        .sheet(isPresented: $showModelSelector) {
            ModelTierSelectorSheet(
                selectedTier: $selectedModelTier,
                thinkingModeEnabled: $thinkingModeEnabled,
                onTierSelected: { tier in
                    NotificationCenter.default.post(
                        name: Notification.Name("gj_model_tier_changed"),
                        object: nil,
                        userInfo: ["tier": tier.rawValue]
                    )
                },
                onThinkingModeChanged: { enabled in
                    NotificationCenter.default.post(
                        name: Notification.Name("gj_thinking_mode_changed"),
                        object: nil,
                        userInfo: ["enabled": enabled]
                    )
                }
            )
        }
        .onAppear {
            // Load initial model tier from UserDefaults
            if let tierRaw = UserDefaults.standard.string(forKey: "ai_selected_model_tier"),
               let tier = ModelTier(rawValue: tierRaw) {
                selectedModelTier = tier
            }
        }
    }
    
    /// Menu grid inside the unified card
    @ViewBuilder
    private var menuGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Camera
            menuPanelButton(icon: "camera", label: "相机") { handleCamera() }
            
            // Gallery
            menuPanelButton(icon: "photo.on.rectangle", label: "相册") { handleGallery() }
            
            // File
            menuPanelButton(icon: "paperclip", label: "文件") { handleFileUpload() }
            
            // Voice Call (AI mode only)
            if appState.currentMode == .ai {
                menuPanelButton(icon: "phone.fill", label: "通话") { showVoiceCall = true }
            }
            
            // Time Capsule (Journal mode only)
            if appState.currentMode == .journal {
                menuPanelButton(icon: "hourglass", label: "胶囊") {
                    withAnimation(.spring()) { appState.showCapsuleCreator = true }
                }
                
                // Mood - 使用机器人图标
                let isMoodDisabled = DailyTrackerRepository.shared.hasRecordForToday()
                menuPanelButton(
                    customIcon: RobotIcon(
                        size: 28,
                        eyeStyle: isMoodDisabled ? .check : .happy
                    ),
                    label: "心情",
                    isDisabled: isMoodDisabled
                ) {
                    if !isMoodDisabled {
                        withAnimation(.spring()) { appState.showMindState = true }
                    }
                }
            }
        }
    }
    
    /// Input card background color
    private var inputCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemBackground
                : UIColor.white
        })
    }
    
    /// Text mode content (inside unified card)
    @ViewBuilder
    private var textModeContent: some View {
        HStack(spacing: 10) {
            // Text input field
            ZStack(alignment: .bottomTrailing) {
                TextField(placeholderText, text: $vm.text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .focused($inputFocused)
                    .onAppear {
                        if !appState.hasAutoExpandedInput {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                inputFocused = true
                                appState.hasAutoExpandedInput = true
                            }
                        }
                    }
                
                if vm.text.count > 20 || vm.text.contains("\n") {
                    Button(action: { showExpandedInput = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.footnote)
                            .foregroundColor(Colors.systemGray)
                            .padding(4)
                    }
                }
            }
            
            // Voice toggle button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    vm.inputMode = .voice
                }
            }) {
                Image(systemName: "waveform")
                    .font(.body)
                    .foregroundColor(Colors.slateText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            // Expand button (+)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    vm.showAppsMenu.toggle()
                }
            }) {
                Image(systemName: vm.showAppsMenu ? "xmark" : "plus")
                    .font(.title3.weight(.medium))
                    .foregroundColor(Colors.slateText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            // Send button
            if hasValidText {
                SubmitButton(hasText: true, onClick: { handleSubmit() })
            }
        }
    }
    
    /// Voice mode content (inside unified card)
    @ViewBuilder
    private var voiceModeContent: some View {
        HStack(spacing: 10) {
            // Press to speak button
            PressToSpeakButton(
                isPressing: $voicePressing,
                isCancelled: $voiceCancelled,
                transcribedText: $vm.transcribedText,
                audioLevel: vm.audioLevel,
                onStart: { vm.startVoiceTranscription() },
                onEnd: { vm.stopVoiceTranscription() },
                onCancel: { vm.cancelVoiceTranscription() },
                onEdit: {
                    vm.stopVoiceTranscriptionForEdit()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        vm.inputMode = .text
                    }
                }
            )
            
            // Keyboard toggle button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    vm.inputMode = .text
                }
            }) {
                Image(systemName: "keyboard")
                    .font(.body)
                    .foregroundColor(Colors.slateText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            // Expand button (+)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    vm.showAppsMenu.toggle()
                }
            }) {
                Image(systemName: vm.showAppsMenu ? "xmark" : "plus")
                    .font(.title3.weight(.medium))
                    .foregroundColor(Colors.slateText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
    }
    
    /// Expandable Menu Panel - WeChat style grid below input
    @ViewBuilder
    private var expandableMenuPanel: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Camera
            menuPanelButton(icon: "camera", label: "相机") {
                handleCamera()
            }
            
            // Gallery
            menuPanelButton(icon: "photo.on.rectangle", label: "相册") {
                handleGallery()
            }
            
            // File
            menuPanelButton(icon: "paperclip", label: "文件") {
                handleFileUpload()
            }
            
            // Voice Call (AI mode only)
            if appState.currentMode == .ai {
                menuPanelButton(icon: "phone.fill", label: "通话") {
                    showVoiceCall = true
                }
            }
            
            // Time Capsule (Journal mode only)
            if appState.currentMode == .journal {
                menuPanelButton(icon: "hourglass", label: "胶囊") {
                    withAnimation(.spring()) { appState.showCapsuleCreator = true }
                }
            }
            
            // Mood (Journal mode only)
            if appState.currentMode == .journal {
                let isMoodDisabled = DailyTrackerRepository.shared.hasRecordForToday()
                menuPanelButton(
                    customIcon: RobotIcon(
                        size: 28,
                        eyeStyle: isMoodDisabled ? .check : .happy
                    ),
                    label: "心情",
                    isDisabled: isMoodDisabled
                ) {
                    if !isMoodDisabled {
                        withAnimation(.spring()) { appState.showMindState = true }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
    
    /// Menu panel button - WeChat style with icon and label
    private func menuPanelButton(icon: String, label: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDisabled ? Colors.teal : Colors.slateText)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Colors.slateText)
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    /// Menu panel button with custom icon view
    private func menuPanelButton<IconView: View>(customIcon: IconView, label: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                customIcon
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Colors.slateText)
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    // MARK: - Layout Views
    
    /// Text input mode layout (keyboard mode)
    /// Requirements: 2.2, 2.3, 2.8
    @ViewBuilder
    private var textModeLayout: some View {
        DockContainer(isMenuOpen: false, isReplyMode: vm.replyContext != nil, isFocused: inputFocused) {
            HStack(spacing: 10) {
                // Text input field
                ZStack(alignment: .bottomTrailing) {
                    TextField(placeholderText, text: $vm.text, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.leading, 8)
                        .padding(.trailing, 30)
                        .focused($inputFocused)
                        .onAppear {
                            // Auto-focus only on first launch/appear
                            if !appState.hasAutoExpandedInput {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    inputFocused = true
                                    appState.hasAutoExpandedInput = true
                                }
                            }
                        }
                    
                    if vm.text.count > 20 || vm.text.contains("\n") {
                        Button(action: { showExpandedInput = true }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.footnote)
                                .foregroundColor(Colors.systemGray)
                                .padding(8)
                        }
                    }
                }
                
                // Voice toggle button (switch to voice mode)
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        vm.inputMode = .voice
                    }
                }) {
                    Image(systemName: "waveform")
                        .font(.body)
                        .foregroundColor(Colors.slateText)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                // Expand button (+) for toolbar
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        vm.showAppsMenu.toggle()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .rotationEffect(.degrees(vm.showAppsMenu ? 45 : 0))
                        .foregroundColor(Colors.slateText)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                // Send button (only show when there's content)
                if hasValidText {
                    SubmitButton(hasText: true, onClick: { handleSubmit() })
                }
            }
        }
    }
    
    /// Voice input mode layout (press to speak)
    /// Requirements: 3.2, 3.3
    @ViewBuilder
    private var voiceModeLayout: some View {
        DockContainer(isMenuOpen: false, isReplyMode: vm.replyContext != nil, isFocused: false) {
            HStack(spacing: 10) {
                // Press to speak button - 微信风格
                PressToSpeakButton(
                    isPressing: $voicePressing,
                    isCancelled: $voiceCancelled,
                    transcribedText: $vm.transcribedText,
                    audioLevel: vm.audioLevel,
                    onStart: {
                        vm.startVoiceTranscription()
                    },
                    onEnd: {
                        vm.stopVoiceTranscription()
                    },
                    onCancel: {
                        vm.cancelVoiceTranscription()
                    },
                    onEdit: {
                        // 右滑转文字：停止录音但不自动发送，切换到文本模式让用户编辑
                        vm.stopVoiceTranscriptionForEdit()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.inputMode = .text
                        }
                    }
                )
                
                // Keyboard toggle button (switch back to text mode)
                // Requirements: 3.10
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        vm.inputMode = .text
                    }
                }) {
                    Image(systemName: "keyboard")
                        .font(.body)
                        .foregroundColor(Colors.slateText)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Mode Change Handler
    
    /// Handle mode change from ModeToggleBar
    /// Requirements: 1.3, 6.1, 6.2
    private func handleModeChange(to newMode: AppMode) {
        let previousMode = appState.currentMode
        
        // When switching to AI mode, load most recent conversation
        if previousMode == .journal && newMode == .ai {
            let conversations = AIConversationRepository.shared.loadAll()
            if let mostRecent = conversations.first {
                appState.currentConversationId = mostRecent.id
            }
        }
        
        // Clear conversation ID when switching to journal mode
        if newMode == .journal {
            appState.currentConversationId = nil
        }
    }

    private func handleGallery() {
        PermissionsService.shared.requestPhotoAccess { status in
            if status == .authorized || status == .limited {
                showPhotoPicker = true
            } else {
                permissionAlert = Localization.tr("permPhotoDenied")
            }
        }
    }
    
    private func handleCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            permissionAlert = Localization.tr("permCameraDenied")
            return
        }
        PermissionsService.shared.requestCameraAccess { status in
            if status == .authorized {
                showCamera = true
            } else {
                permissionAlert = Localization.tr("permCameraDenied")
            }
        }
    }
    
    private func handleFileUpload() {
        showFilePicker = true
    }
    
    private func handleCalendar() {
        // Placeholder for calendar
    }
    
    /// Handle mode toggle between journal and AI mode
    /// Requirements: 6.3, 6.4
    private func handleModeToggle() {
        let previousMode = appState.currentMode
        let newMode: AppMode = previousMode == .journal ? .ai : .journal
        
        print("[InputDock] handleModeToggle() called, currentMode: \(previousMode) -> \(newMode)")
        
        // Update mode outside of animation to avoid "Publishing changes from within view updates" warning
        appState.currentMode = newMode
        
        // When switching to AI mode, expand conversation view
        // Keep current conversation if exists, otherwise load last or create new
        if previousMode == .journal && newMode == .ai {
            appState.aiConversationCollapsed = false
            
            // If no current conversation, try to load last one from same day
            if appState.currentConversationId == nil {
                if let lastId = UserPreferencesRepository.shared.loadLastConversationIfSameDay() {
                    // Verify the conversation still exists
                    if AIConversationRepository.shared.load(id: lastId) != nil {
                        appState.setCurrentConversation(id: lastId)
                    }
                }
                // If still nil, AIConversationScreen will create a new one
            }
        }
        
        // When switching to journal mode, collapse conversation but KEEP the conversation ID
        // This allows returning to the same conversation when switching back
        if newMode == .journal {
            appState.aiConversationCollapsed = true
            // Don't clear currentConversationId - keep it for session continuity
        }
        
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
    
    /// Placeholder text based on current mode
    /// Requirements: 6.6, 6.7
    private var placeholderText: String {
        appState.currentMode == .journal
            ? Localization.tr("placeholder")
            : Localization.tr("AI.Placeholder")
    }
    
    /// Check if input has valid text (non-whitespace) or attachments in AI mode
    /// Requirements: 6.4, 6.5
    private var hasValidText: Bool {
        let hasText = !vm.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // In AI mode, also consider attachments as valid input
        if appState.currentMode == .ai {
            return hasText || !attachmentManager.pendingAttachments.isEmpty
        }
        return hasText
    }
    
    /// Handle submit action based on current mode
    /// In AI mode, sends attachments directly via notification
    /// In journal mode, uses InputViewModel.submit()
    private func handleSubmit() {
        inputFocused = false
        
        if appState.currentMode == .ai {
            // AI mode: send text and ready attachments via notification
            let readyAttachments = attachmentManager.getReadyAttachments()
            let text = vm.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only send if there's text or attachments
            guard !text.isEmpty || !readyAttachments.isEmpty else { return }
            
            // Post notification with attachments
            NotificationCenter.default.post(
                name: Notification.Name("gj_submit_input"),
                object: nil,
                userInfo: [
                    "text": text,
                    "indexedAttachments": readyAttachments
                ]
            )
            
            // Clear input state
            vm.text = ""
            attachmentManager.clearAll()
        } else {
            // Journal mode: use InputViewModel's submit
            vm.submit()
        }
    }
    
    private func quickActionButton(image: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: image)
                    .font(.title3)
                    .foregroundColor(tint)
                Text(Localization.tr("moreAction")) // Needs localization or just text
                    .foregroundColor(tint)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}
#else
public struct InputDock: View {
    @StateObject private var vm = InputViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var permissionAlert: String? = nil
    @FocusState private var inputFocused: Bool
    public init() {}
    public var body: some View {
        VStack(spacing: 8) {
            if let ctx = vm.replyContext {
                ReplyContextBar(text: ctx, onCancel: { vm.replyContext = nil })
            }
            if !vm.attachments.isEmpty { AttachmentsBar(items: vm.attachments, onRemove: { vm.removeAttachment(id: $0) }) }
            InputQuickActions(
                onGallery: { permissionAlert = NSLocalizedString("permPhotoDenied", comment: "") },
                onCamera: { permissionAlert = NSLocalizedString("permCameraDenied", comment: "") },
                onRecord: { vm.toggleRecording() },
                onTimeCapsule: { withAnimation(.spring()) { appState.showCapsuleCreator = true } },
                onMood: { withAnimation(.spring()) { appState.showMindState = true } },
                onFile: {},
                onMore: {}
            )
            .padding(.horizontal, 16)
            DockContainer(isMenuOpen: false, isReplyMode: vm.replyContext != nil, isFocused: inputFocused) {
                ZStack(alignment: .leading) {
                    SwiftGrowingTextEditor(text: $vm.text)
                        .frame(maxWidth: .infinity)
                        .focused($inputFocused)
                    if vm.text.isEmpty { Text(Localization.tr("placeholder")).foregroundColor(Colors.systemGray).padding(.horizontal, 8) }
                }
                SubmitButton(hasText: !vm.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, onClick: { vm.submit(); inputFocused = false })
            }
            if vm.isRecording {
                RecordingBar(isRecording: vm.isRecording, duration: vm.recordingSeconds, onStart: { vm.startRecording() }, onStop: { vm.stopRecording() }, onCancel: { vm.cancelRecording() })
                    .padding(.horizontal, 16)
            }
        }
        .animation(.easeInOut, value: inputFocused)
        
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_initiate_reply"))) { note in
            if let dict = note.userInfo as? [String: Any] {
                vm.replyContext = dict["text"] as? String
                vm.replyQuestionId = dict["id"] as? String
            }
        }
        .alert(permissionAlert ?? "", isPresented: Binding(get: { permissionAlert != nil }, set: { _ in permissionAlert = nil })) {
            Button(Localization.tr("ok"), action: { permissionAlert = nil })
        }
    }
}
#endif
