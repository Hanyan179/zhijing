import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public struct InputDock: View {
    @StateObject private var vm = InputViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var showAudioPicker = false
    @State private var permissionAlert: String? = nil
    @FocusState private var inputFocused: Bool
    @State private var showMoreActions = false
    @State private var showExpandedInput = false
    
    public init() {}
    public var body: some View {
        VStack(spacing: 8) {
            if let ctx = vm.replyContext {
                ReplyContextBar(text: ctx, onCancel: { vm.replyContext = nil })
            }
            if !vm.attachments.isEmpty { AttachmentsBar(items: vm.attachments, onRemove: { vm.removeAttachment(id: $0) }) }
            
            // Expandable Menu Toolbar (Above the input field)
            if vm.showAppsMenu {
                InputQuickActions(
                    onGallery: { handleGallery() },
                    onCamera: { handleCamera() },
                    onRecord: { vm.toggleRecording() },
                    onTimeCapsule: { withAnimation(.spring()) { appState.showCapsuleCreator = true } },
                    onMood: { withAnimation(.spring()) { appState.showMindState = true } },
                    onFile: { handleFileUpload() },
                    onMore: { showMoreActions = true },
                    onModeToggle: { handleModeToggle() },
                    // Hide time capsule and mood buttons in AI mode
                    showTimeCapsule: appState.currentMode == .journal,
                    showMood: appState.currentMode == .journal,
                    showMore: false,
                    showModeToggle: true,
                    currentMode: appState.currentMode,
                    isMoodDisabled: DailyTrackerRepository.shared.hasRecordForToday()
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 4)
            }
            
            if vm.isRecording {
                RecordingBar(isRecording: vm.isRecording, duration: vm.recordingSeconds, onStart: { }, onStop: { vm.stopRecording() }, onCancel: { vm.cancelRecording() })
                    .padding(.horizontal, 16)
            } else {
                // Requirement 6.1: Distinct background for input area
                // Requirement 6.3: Focus state with subtle border/shadow
                DockContainer(isMenuOpen: false, isReplyMode: vm.replyContext != nil, isFocused: inputFocused) {
                    HStack(spacing: 10) {
                        // Expand Button (+)
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                vm.showAppsMenu.toggle()
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .rotationEffect(.degrees(vm.showAppsMenu ? 45 : 0))
                                .foregroundColor(Colors.slateText)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        
                        ZStack(alignment: .bottomTrailing) {
                            // Requirement 6.2: Contextual placeholder text (mode-based)
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
                                        .font(.system(size: 14))
                                        .foregroundColor(Colors.systemGray)
                                        .padding(8)
                                }
                            }
                        }
                        // Requirement 6.4: Visual prominence for send button
                        // Requirement 6.5: Show/hide based on text content
                        SubmitButton(hasText: hasValidText, onClick: { vm.submit(); inputFocused = false })
                    }
                }
            }
        }
        .animation(.easeInOut, value: inputFocused)
        .fullScreenCover(isPresented: $showExpandedInput) {
            ExpandedInputView(vm: vm, isPresented: $showExpandedInput)
        }
        
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerSheet { imgs in
                if !imgs.isEmpty {
                    // In AI mode, attach images instead of direct send
                    if appState.currentMode == .ai {
                        vm.pendingImages = imgs
                        for (index, img) in imgs.enumerated() {
                            vm.addPhoto(name: "Image \(index + 1)", image: img)
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
                    // In AI mode, attach image instead of direct send
                    if appState.currentMode == .ai {
                        vm.pendingImages = [i]
                        vm.addPhoto(name: "Camera Photo", image: i)
                    } else {
                        // In journal mode, direct send
                        vm.pendingImages = [i]
                        vm.submit()
                    }
                } else if let u = url {
                    vm.importFile(url: u)
                    if appState.currentMode == .journal {
                        vm.submit()
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker { urls in
                for url in urls {
                    vm.importFile(url: url)
                }
                // In journal mode, submit immediately; in AI mode, just attach
                if appState.currentMode == .journal {
                    vm.submit()
                }
            }
        }
        .sheet(isPresented: $showAudioPicker) {
            DocumentPicker(types: [.audio]) { urls in
                for url in urls {
                    vm.importFile(url: url, isAudio: true)
                }
                // In journal mode, submit immediately; in AI mode, just attach
                if appState.currentMode == .journal {
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let previousMode = appState.currentMode
            appState.currentMode = appState.currentMode == .journal ? .ai : .journal
            
            // When switching to AI mode, load most recent conversation
            if previousMode == .journal && appState.currentMode == .ai {
                let conversations = AIConversationRepository.shared.loadAll()
                if let mostRecent = conversations.first {
                    appState.currentConversationId = mostRecent.id
                }
                // If no conversations exist, currentConversationId remains nil
                // and AIConversationScreen will show welcome view
            }
            
            // Clear conversation ID when switching to journal mode
            if appState.currentMode == .journal {
                appState.currentConversationId = nil
            }
        }
    }
    
    /// Placeholder text based on current mode
    /// Requirements: 6.6, 6.7
    private var placeholderText: String {
        appState.currentMode == .journal
            ? Localization.tr("placeholder")
            : Localization.tr("AI.Placeholder")
    }
    
    /// Check if input has valid text (non-whitespace)
    /// Requirements: 6.4, 6.5
    private var hasValidText: Bool {
        !vm.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func quickActionButton(image: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: image)
                    .font(.system(size: 20, weight: .regular))
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
