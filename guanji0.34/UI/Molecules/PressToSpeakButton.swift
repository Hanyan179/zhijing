import SwiftUI
import AVFoundation

// MARK: - Record Action Enum

private enum RecordAction: Equatable {
    case send      // 默认：松开发送
    case cancel    // 左滑：取消
    case toText    // 右滑：转文字模式
}

// MARK: - Overlay Mode

private enum OverlayMode: Equatable {
    case recording    // 录音中（按住状态）
    case editing      // 编辑文字模式（松开后）
}

/// 按住说话按钮 - iOS 原生风格
public struct PressToSpeakButton: View {
    @Binding var isPressing: Bool
    @Binding var isCancelled: Bool
    @Binding var transcribedText: String
    
    /// 音频电平 (0.0-1.0)，从 InputViewModel 传入
    let audioLevel: Float
    
    let onStart: () -> Void
    let onEnd: () -> Void
    let onCancel: () -> Void
    let onEdit: (() -> Void)?
    
    @State private var currentAction: RecordAction = .send
    @State private var waveAmplitudes: [CGFloat] = Array(repeating: 0.15, count: 20)
    @State private var showOverlay: Bool = false
    @State private var overlayMode: OverlayMode = .recording
    @State private var editingText: String = ""
    
    public init(
        isPressing: Binding<Bool>,
        isCancelled: Binding<Bool>,
        transcribedText: Binding<String>,
        audioLevel: Float,
        onStart: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onEdit: (() -> Void)? = nil
    ) {
        self._isPressing = isPressing
        self._isCancelled = isCancelled
        self._transcribedText = transcribedText
        self.audioLevel = audioLevel
        self.onStart = onStart
        self.onEnd = onEnd
        self.onCancel = onCancel
        self.onEdit = onEdit
    }
    
    public var body: some View {
        buttonView
            .frame(height: 44)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        handleDragChanged(value: value)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
            .overlay(
                RecordingOverlayPresenter(
                    isPresented: $showOverlay,
                    overlayMode: $overlayMode,
                    currentAction: currentAction,
                    waveAmplitudes: waveAmplitudes,
                    transcribedText: transcribedText,
                    editingText: $editingText,
                    onSend: handleSend,
                    onCancelEdit: handleCancelEdit
                )
                .allowsHitTesting(overlayMode == .editing)
            )
            .onChange(of: isPressing) { newValue in
                if newValue {
                    showOverlay = true
                    overlayMode = .recording
                }
            }
            .onChange(of: transcribedText) { newValue in
                // 实时同步转录文字到编辑文字
                editingText = newValue
            }
            .onChange(of: audioLevel) { newLevel in
                // 根据真实音频电平更新波形
                if isPressing {
                    updateWaveformFromAudioLevel(CGFloat(newLevel))
                }
            }
    }
    
    // MARK: - Actions
    
    private func handleSend() {
        transcribedText = editingText
        showOverlay = false
        overlayMode = .recording
        currentAction = .send
        onEnd()
    }
    
    private func handleCancelEdit() {
        showOverlay = false
        overlayMode = .recording
        currentAction = .send
        editingText = ""
        transcribedText = ""
        onCancel()
    }
    
    // MARK: - Drag Handling
    
    private func handleDragChanged(value: DragGesture.Value) {
        if !isPressing {
            isPressing = true
            currentAction = .send
            editingText = ""
            triggerHaptic(.medium)
            onStart()
        }
        
        let screenSize = UIScreen.main.bounds.size
        updateAction(location: value.location, screenSize: screenSize)
    }
    
    private func handleDragEnded() {
        let action = currentAction
        isPressing = false
        
        // 重置波形
        waveAmplitudes = Array(repeating: 0.15, count: 20)
        
        switch action {
        case .send:
            currentAction = .send
            showOverlay = false
            triggerHaptic(.light)
            onEnd()
            
        case .cancel:
            currentAction = .send
            showOverlay = false
            isCancelled = true
            triggerHaptic(.rigid)
            onCancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isCancelled = false
            }
            
        case .toText:
            // 进入编辑模式，保留已转录的文字
            overlayMode = .editing
            editingText = transcribedText
            triggerHaptic(.light)
        }
    }
    
    private func updateAction(location: CGPoint, screenSize: CGSize) {
        let screenHeight = screenSize.height
        let screenWidth = screenSize.width
        let isInBottomArea = location.y > screenHeight * 0.65
        
        if isInBottomArea {
            if location.x < screenWidth * 0.33 {
                if currentAction != .cancel {
                    currentAction = .cancel
                    triggerHaptic(.rigid)
                }
            } else if location.x > screenWidth * 0.67 {
                if currentAction != .toText {
                    currentAction = .toText
                    triggerHaptic(.rigid)
                }
            } else {
                if currentAction != .send {
                    currentAction = .send
                    triggerHaptic(.light)
                }
            }
        } else {
            if currentAction != .send {
                currentAction = .send
                triggerHaptic(.light)
            }
        }
    }
    
    // MARK: - Button View
    
    private var buttonView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isPressing ? Colors.indigo.opacity(0.15) : Color(.systemGray6))
            
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isPressing ? Colors.indigo : Colors.slate600)
                
                Text(Localization.tr("holdToSpeak"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isPressing ? Colors.indigo : Colors.slateText)
            }
        }
        .scaleEffect(isPressing ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressing)
    }
    
    // MARK: - Wave Animation (基于真实音频电平，快速响应)
    
    private func updateWaveformFromAudioLevel(_ level: CGFloat) {
        // 更快的动画响应
        withAnimation(.easeOut(duration: 0.08)) {
            // 快速移动波形数据
            for i in 0..<(waveAmplitudes.count - 1) {
                waveAmplitudes[i] = waveAmplitudes[i + 1]
            }
            // 新值更直接地响应音频电平
            let variation = CGFloat.random(in: -0.05...0.05)
            let newValue = max(0.15, min(1.0, level + variation))
            waveAmplitudes[waveAmplitudes.count - 1] = newValue
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Recording Overlay Presenter

private struct RecordingOverlayPresenter: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var overlayMode: OverlayMode
    let currentAction: RecordAction
    let waveAmplitudes: [CGFloat]
    let transcribedText: String
    @Binding var editingText: String
    let onSend: () -> Void
    let onCancelEdit: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented {
            context.coordinator.showOverlay(
                overlayMode: overlayMode,
                currentAction: currentAction,
                waveAmplitudes: waveAmplitudes,
                transcribedText: transcribedText,
                editingText: $editingText,
                onSend: onSend,
                onCancelEdit: onCancelEdit
            )
        } else {
            context.coordinator.hideOverlay()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var overlayWindow: UIWindow?
        var hostingController: UIHostingController<RecordingOverlayContent>?
        var currentMode: OverlayMode = .recording
        
        func showOverlay(
            overlayMode: OverlayMode,
            currentAction: RecordAction,
            waveAmplitudes: [CGFloat],
            transcribedText: String,
            editingText: Binding<String>,
            onSend: @escaping () -> Void,
            onCancelEdit: @escaping () -> Void
        ) {
            let content = RecordingOverlayContent(
                overlayMode: overlayMode,
                currentAction: currentAction,
                waveAmplitudes: waveAmplitudes,
                transcribedText: transcribedText,
                editingText: editingText,
                onSend: onSend,
                onCancelEdit: onCancelEdit
            )
            
            // 如果模式改变，需要重建 window
            let modeChanged = currentMode != overlayMode
            currentMode = overlayMode
            
            if let hostingController = hostingController, !modeChanged {
                hostingController.rootView = content
                overlayWindow?.isUserInteractionEnabled = (overlayMode == .editing)
                return
            }
            
            // 需要重建 window
            hideOverlay()
            
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            self.hostingController = hostingController
            
            let window: UIWindow
            if overlayMode == .editing {
                window = UIWindow(windowScene: windowScene)
                window.isUserInteractionEnabled = true
            } else {
                window = PassthroughWindow(windowScene: windowScene)
                window.isUserInteractionEnabled = false
            }
            
            window.rootViewController = hostingController
            window.windowLevel = .alert + 1
            window.isHidden = false
            
            self.overlayWindow = window
        }
        
        func hideOverlay() {
            overlayWindow?.isHidden = true
            overlayWindow = nil
            hostingController = nil
        }
    }
}

// MARK: - Passthrough Window

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

// MARK: - Recording Overlay Content

private struct RecordingOverlayContent: View {
    let overlayMode: OverlayMode
    let currentAction: RecordAction
    let waveAmplitudes: [CGFloat]
    let transcribedText: String
    @Binding var editingText: String
    let onSend: () -> Void
    let onCancelEdit: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // iOS 原生毛玻璃背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    if overlayMode == .editing {
                        isTextFieldFocused = false
                    }
                }
            
            if overlayMode == .editing {
                editingModeContent
            } else {
                recordingModeContent
            }
        }
    }
    
    // MARK: - 录音模式内容
    
    private var recordingModeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if currentAction == .toText {
                // 滑到转文字区域：显示实时转录的文字
                liveTranscriptionView
                    .padding(.bottom, 40)
            } else {
                // 普通录音：显示波形
                recordingBubble
                    .padding(.bottom, 60)
            }
            
            Spacer()
            
            recordingModeBottomArea
        }
    }
    
    // MARK: - 编辑模式内容
    
    private var editingModeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 可编辑的文字气泡 - 适配深色模式
            VStack(spacing: 6) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Colors.indigo)
                    
                    TextEditor(text: $editingText)
                        .font(.body)
                        .foregroundColor(Colors.background) // 使用背景色确保对比度
                        .tint(Colors.background) // 光标颜色
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isTextFieldFocused)
                }
                .frame(width: 280)
                .frame(minHeight: 60, maxHeight: 140)
                
                // 提示文字
                Text("编辑后点击发送")
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.6))
            }
            
            Spacer()
            
            // 底部按钮
            editingModeBottomArea
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - 实时转录视图
    
    private var liveTranscriptionView: some View {
        VStack(spacing: 8) {
            // 文字气泡 - 适配深色模式
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Colors.indigo)
                
                ScrollView {
                    Text(transcribedText.isEmpty ? " " : transcribedText)
                        .font(.body)
                        .foregroundColor(Colors.background) // 使用背景色作为文字色，确保对比度
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
            }
            .frame(width: 280)
            .frame(minHeight: 60, maxHeight: 140)
            
            // 提示
            Text("松开编辑")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 录音气泡（带动态波形）
    
    private var recordingBubble: some View {
        VStack(spacing: 0) {
            ZStack {
                // 外圈脉冲动画
                Circle()
                    .fill(Colors.indigo.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(Colors.indigo.opacity(0.3))
                    .frame(width: 110, height: 110)
                
                // 主圆形
                Circle()
                    .fill(Colors.indigo)
                    .frame(width: 80, height: 80)
                
                // 波形 - 使用背景色确保对比度
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Colors.background)
                            .frame(width: 4, height: 10 + waveAmplitudes[i * 3] * 30)
                    }
                }
            }
            
            // 录音时长提示
            Text("正在录音...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
    }
    
    // MARK: - 底部操作区（录音模式）- iOS 原生风格
    
    private var recordingModeBottomArea: some View {
        VStack(spacing: 24) {
            HStack(spacing: 60) {
                cancelZone
                toTextZone
            }
            
            Text(statusText)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .padding(.bottom, 50)
        }
    }
    
    // MARK: - 底部操作区（编辑模式）- iOS 原生风格
    
    private var editingModeBottomArea: some View {
        HStack(spacing: 60) {
            // 取消按钮
            Button(action: onCancelEdit) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.primary)
                    }
                    Text("取消")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 发送按钮
            Button(action: onSend) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(editingText.isEmpty ? Color(.systemGray4) : Colors.indigo)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "arrow.up")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Text("发送")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(editingText.isEmpty)
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - 取消区域 - iOS 原生风格
    
    private var cancelZone: some View {
        let isActive = currentAction == .cancel
        
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? Colors.rose : Color(.systemGray5))
                    .frame(width: isActive ? 72 : 56, height: isActive ? 72 : 56)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
                
                Image(systemName: "xmark")
                    .font(isActive ? .title2.weight(.bold) : .title3.weight(.medium))
                    .foregroundColor(isActive ? .white : .primary)
            }
            
            Text("取消")
                .font(.caption)
                .foregroundColor(isActive ? Colors.rose : .secondary)
        }
    }
    
    // MARK: - 转文字区域 - iOS 原生风格
    
    private var toTextZone: some View {
        let isActive = currentAction == .toText
        
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? Colors.indigo : Color(.systemGray5))
                    .frame(width: isActive ? 72 : 56, height: isActive ? 72 : 56)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
                
                Image(systemName: "text.bubble")
                    .font(isActive ? .title2.weight(.medium) : .title3.weight(.medium))
                    .foregroundColor(isActive ? .white : .primary)
            }
            
            Text("转文字")
                .font(.caption)
                .foregroundColor(isActive ? Colors.indigo : .secondary)
        }
    }
    
    private var statusText: String {
        switch currentAction {
        case .send: return "松开发送"
        case .cancel: return "松开取消"
        case .toText: return ""
        }
    }
}

// MARK: - Triangle Shape (保留但不再使用)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#if DEBUG
struct PressToSpeakButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            VStack {
                Spacer()
                PressToSpeakButton(
                    isPressing: .constant(false),
                    isCancelled: .constant(false),
                    transcribedText: .constant("这是识别的文字"),
                    audioLevel: 0.5,
                    onStart: {}, onEnd: {}, onCancel: {}
                )
                .padding()
            }
        }
    }
}
#endif
