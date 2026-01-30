import SwiftUI

/// Main screen for AI conversation
/// Displays chat messages with streaming support and empty state
/// Input is handled by the shared InputDock component in TimelineScreen
public struct AIConversationScreen: View {
    @StateObject private var vm = AIConversationViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showModelSelector = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages or empty state
            if vm.messages.isEmpty && !vm.isStreaming {
                WelcomeView(
                    modelTier: vm.selectedModelTier,
                    thinkingMode: vm.thinkingModeEnabled,
                    onStarterTap: { starter in
                        vm.sendMessage(starter)
                    }
                )
            } else {
                messagesScrollView
            }
            // Input is handled by InputDock in TimelineScreen's safeAreaInset
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show AI toolbar when in AI mode
            if appState.currentMode == .ai {
                // Left: Back button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        appState.collapseAIConversation() 
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
                
                // Right: New conversation button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        vm.saveAndCreateNewConversation() 
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showModelSelector) {
            ModelTierSelectorSheet(
                selectedTier: $vm.selectedModelTier,
                thinkingModeEnabled: $vm.thinkingModeEnabled,
                onTierSelected: { tier in
                    vm.setModelTier(tier)
                },
                onThinkingModeChanged: { enabled in
                    vm.setThinkingMode(enabled)
                }
            )
        }
        .onAppear {
            loadConversation()
        }
        .onChange(of: appState.currentConversationId) { newId in
            // Only load if we're in AI mode (avoid double loading during mode switch)
            guard appState.currentMode == .ai else { return }
            
            if let id = newId {
                // Only load if it's a different conversation
                if vm.conversation?.id != id {
                    vm.loadConversation(id: id)
                }
            } else {
                vm.createNewConversation()
                if let newConvId = vm.conversation?.id {
                    appState.setCurrentConversation(id: newConvId)
                }
            }
        }
        .onChange(of: appState.currentMode) { newMode in
            // When switching to AI mode, ensure we have a valid conversation
            if newMode == .ai {
                if let id = appState.currentConversationId {
                    // Only load if it's a different conversation
                    if vm.conversation?.id != id {
                        if AIConversationRepository.shared.load(id: id) != nil {
                            vm.loadConversation(id: id)
                        } else {
                            vm.createNewConversation()
                            if let newConvId = vm.conversation?.id {
                                appState.setCurrentConversation(id: newConvId)
                            }
                        }
                    }
                } else {
                    // No conversation ID, create new
                    vm.createNewConversation()
                    if let newConvId = vm.conversation?.id {
                        appState.setCurrentConversation(id: newConvId)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_ai_new_conversation"))) { _ in
            // Handle new conversation request from toolbar
            vm.saveAndCreateNewConversation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("gj_submit_input"))) { notification in
            // Only handle input when in AI mode
            guard appState.currentMode == .ai else { return }
            
            if let userInfo = notification.userInfo {
                let text = (userInfo["text"] as? String) ?? ""
                
                // Check for indexed attachments (new flow from InputDock)
                if let indexedAttachments = userInfo["indexedAttachments"] as? [IndexedAttachment] {
                    // New flow: attachments already processed by AttachmentManager
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !indexedAttachments.isEmpty {
                        vm.sendMessageWithAttachments(text, attachments: indexedAttachments)
                    }
                } else {
                    // Legacy flow: process images/files (for backward compatibility)
                    let images = userInfo["images"] as? [UIImage] ?? []
                    let files = userInfo["files"] as? [URL] ?? []
                    
                    if !images.isEmpty || !files.isEmpty {
                        Task { @MainActor in
                            // Add images to attachment manager
                            if !images.isEmpty {
                                try? await vm.attachmentManager.addImages(images)
                            }
                            
                            // Add files to attachment manager
                            if !files.isEmpty {
                                try? await vm.attachmentManager.addFiles(files)
                            }
                            
                            // Send message with attachments
                            let readyAttachments = vm.attachmentManager.getReadyAttachments()
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !readyAttachments.isEmpty {
                                vm.sendMessageWithAttachments(text, attachments: readyAttachments)
                                vm.attachmentManager.clearAll()
                            }
                        }
                    } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Text only message
                        vm.sendMessage(text)
                    }
                }
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(vm.messages) { message in
                    MessageBubble(
                        message: message,
                        onRegenerate: message.role == .assistant ? {
                            vm.regenerateMessage(message)
                        } : nil
                    )
                    .id(message.id)
                }
                
                // Streaming response
                if vm.isStreaming {
                    StreamingMessageBubble(
                        content: vm.streamingContent,
                        reasoningContent: vm.streamingReasoning
                    )
                    .id("streaming")
                }
                
                // Error message
                if let error = vm.errorMessage {
                    errorView(error)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Colors.amber)
                
                Text(message)
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
            }
            
            Button(action: {
                vm.retryLastMessage()
            }) {
                Text(Localization.tr("Action.Retry"))
                    .font(Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Colors.indigo)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.amber.opacity(0.1))
        )
    }
    
    // MARK: - Helpers
    
    private func loadConversation() {
        if let id = appState.currentConversationId {
            // Verify conversation exists
            if AIConversationRepository.shared.load(id: id) != nil {
                vm.loadConversation(id: id)
            } else {
                // Conversation was deleted, create new
                vm.createNewConversation()
                if let newConvId = vm.conversation?.id {
                    appState.setCurrentConversation(id: newConvId)
                }
            }
        } else {
            // No conversation selected, create a new one
            vm.createNewConversation()
            if let newConvId = vm.conversation?.id {
                appState.setCurrentConversation(id: newConvId)
            }
        }
    }
}

// MARK: - Welcome View

/// Empty state view with robot companion
/// 简洁的陪伴感，机器人静静等待用户开始对话
/// AI 模式下显示模型档位（卫星球颜色）和思考模式（头顶灯泡）
/// Requirements: 4.4
public struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let onStarterTap: (String) -> Void
    let modelTier: ModelTier
    let thinkingMode: Bool
    
    public init(
        modelTier: ModelTier = .balanced,
        thinkingMode: Bool = false,
        onStarterTap: @escaping (String) -> Void
    ) {
        self.modelTier = modelTier
        self.thinkingMode = thinkingMode
        self.onStarterTap = onStarterTap
    }
    
    private var robotTheme: RobotMoodTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            // AI Robot Avatar - 使用动态心情状态 + AI 模式装饰
            RobotAvatarMood(
                mindValence: appState.robotMindValence,
                bodyEnergy: appState.robotBodyEnergy,
                theme: robotTheme,
                size: 180,
                modelTier: modelTier,
                thinkingMode: thinkingMode
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Model Tier Selector Sheet

/// Sheet for selecting AI model tier with thinking mode toggle
/// Displays three tier options: fast, balanced, powerful
/// - Requirements: 5.1, 5.2, 5.3, 5.4
public struct ModelTierSelectorSheet: View {
    @Binding var selectedTier: ModelTier
    @Binding var thinkingModeEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    let onTierSelected: (ModelTier) -> Void
    let onThinkingModeChanged: (Bool) -> Void
    
    public init(
        selectedTier: Binding<ModelTier>,
        thinkingModeEnabled: Binding<Bool>,
        onTierSelected: @escaping (ModelTier) -> Void,
        onThinkingModeChanged: @escaping (Bool) -> Void
    ) {
        self._selectedTier = selectedTier
        self._thinkingModeEnabled = thinkingModeEnabled
        self.onTierSelected = onTierSelected
        self.onThinkingModeChanged = onThinkingModeChanged
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // Model tier section
                Section {
                    ForEach(ModelTier.allCases, id: \.self) { tier in
                        Button(action: {
                            selectedTier = tier
                            onTierSelected(tier)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tier.displayName)
                                        .font(Typography.body)
                                        .foregroundColor(Colors.slateText)
                                    
                                    Text(tier.description)
                                        .font(Typography.caption)
                                        .foregroundColor(Colors.slate600)
                                }
                                
                                Spacer()
                                
                                if tier == selectedTier {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Colors.indigo)
                                        .font(.footnote.weight(.semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(Localization.tr("AI.ModelTier"))
                }
                
                // Thinking mode section
                Section {
                    Toggle(isOn: Binding(
                        get: { thinkingModeEnabled },
                        set: { newValue in
                            thinkingModeEnabled = newValue
                            onThinkingModeChanged(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Localization.tr("AI.ThinkingMode"))
                                .font(Typography.body)
                                .foregroundColor(Colors.slateText)
                            
                            Text(Localization.tr("AI.ThinkingMode.Description"))
                                .font(Typography.caption)
                                .foregroundColor(Colors.slate600)
                        }
                    }
                    .tint(Colors.indigo)
                } header: {
                    Text(Localization.tr("AI.Options"))
                }
            }
            .navigationTitle(Localization.tr("AI.SelectModel"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Localization.tr("Action.Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Legacy Model Selector Sheet (kept for reference, can be removed later)

/// Sheet for selecting AI model with thinking mode toggle in toolbar
/// Uses native iOS Sheet and List
/// Supports both server-fetched models and local fallback models
/// Requirements: 1.2, 1.3, 2.3
@available(*, deprecated, message: "Use ModelTierSelectorSheet instead")
public struct ModelSelectorSheet: View {
    @Binding var selectedModel: String
    @Binding var thinkingModeEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    let models: [AIModel]
    let onModelSelected: (String) -> Void
    let onThinkingModeChanged: (Bool) -> Void
    
    public init(
        selectedModel: Binding<String>,
        thinkingModeEnabled: Binding<Bool>,
        models: [AIModel] = [],
        onModelSelected: @escaping (String) -> Void,
        onThinkingModeChanged: @escaping (Bool) -> Void
    ) {
        self._selectedModel = selectedModel
        self._thinkingModeEnabled = thinkingModeEnabled
        self.models = models
        self.onModelSelected = onModelSelected
        self.onThinkingModeChanged = onThinkingModeChanged
    }
    
    /// Check if currently selected model supports thinking
    private var selectedModelSupportsThinking: Bool {
        models.first { $0.id == selectedModel }?.supportsThinking ?? AIModel.supportsThinking(selectedModel)
    }
    
    public var body: some View {
        NavigationStack {
            List(models) { model in
                Button(action: {
                    selectedModel = model.id
                    onModelSelected(model.id)
                    // Auto-disable thinking mode if new model doesn't support it
                    if !model.supportsThinking && thinkingModeEnabled {
                        thinkingModeEnabled = false
                        onThinkingModeChanged(false)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.name)
                                .font(Typography.body)
                                .foregroundColor(Colors.slateText)
                            
                            if !model.description.isEmpty {
                                Text(model.description)
                                    .font(Typography.caption)
                                    .foregroundColor(Colors.slate600)
                            }
                        }
                        
                        Spacer()
                        
                        if model.id == selectedModel {
                            Image(systemName: "checkmark")
                                .foregroundColor(Colors.indigo)
                                .font(.footnote.weight(.semibold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(Localization.tr("AI.SelectModel"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done button on left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Localization.tr("Action.Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                // Thinking mode toggle on right (only if model supports it)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedModelSupportsThinking {
                        Button(action: {
                            thinkingModeEnabled.toggle()
                            onThinkingModeChanged(thinkingModeEnabled)
                        }) {
                            Image(systemName: "lightbulb")
                                .font(.body)
                                .foregroundColor(thinkingModeEnabled ? Colors.indigo : Colors.slate600)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#if DEBUG
struct AIConversationScreen_Previews: PreviewProvider {
    static var previews: some View {
        AIConversationScreen()
            .environmentObject(AppState())
    }
}
#endif
