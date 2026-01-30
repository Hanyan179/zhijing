import SwiftUI

/// 语音通话全屏界面
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5
public struct VoiceCallScreen: View {
    @StateObject private var vm = VoiceCallViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// 关联的对话 ID
    let conversationId: String?
    
    public init(conversationId: String? = nil) {
        self.conversationId = conversationId
    }
    
    public var body: some View {
        ZStack {
            // 背景
            Colors.slateLight
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 状态图标 + 波形动画
                statusView
                
                // 文字显示区域
                textDisplayView
                
                Spacer()
                
                // 错误提示
                if let error = vm.errorMessage {
                    errorBanner(error)
                }
                
                // 底部控制栏
                controlBar
            }
            .padding()
        }
        .onAppear {
            vm.startCall(conversationId: conversationId)
        }
        .onDisappear {
            vm.endCall()
        }
        .alert("需要权限", isPresented: $vm.showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(vm.permissionAlertMessage)
        }
    }
    
    // MARK: - Status View
    
    /// 状态视图：根据 state 显示不同图标/动画
    /// Requirements: 5.1, 5.2
    private var statusView: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(statusBackgroundColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                // 波形动画（监听状态）- 响应实际音量
                if vm.state == .listening {
                    WaveformAnimation(audioLevel: vm.audioLevel)
                        .frame(width: 100, height: 60)
                } else {
                    // 状态图标
                    statusIcon
                }
            }
            
            // 状态文字
            Text(statusText)
                .font(Typography.body)
                .foregroundColor(Colors.slate600)
        }
    }
    
    /// 状态图标
    private var statusIcon: some View {
        Group {
            switch vm.state {
            case .idle:
                Image(systemName: "phone.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.slate500)
            case .listening:
                // 波形动画处理
                EmptyView()
            case .processing:
                // 思考中动画
                ThinkingAnimation()
            case .speaking:
                SpeakingIcon()
            }
        }
    }
    
    /// 状态背景颜色
    private var statusBackgroundColor: Color {
        switch vm.state {
        case .idle:
            return Colors.slate500
        case .listening:
            return Colors.indigo
        case .processing:
            return Colors.slate500
        case .speaking:
            return Colors.indigo
        }
    }
    
    /// 状态文字
    private var statusText: String {
        switch vm.state {
        case .idle:
            return "准备中..."
        case .listening:
            return "正在聆听..."
        case .processing:
            return "AI 思考中..."
        case .speaking:
            return "AI 正在说话..."
        }
    }
    
    // MARK: - Text Display View
    
    /// 文字显示区域
    /// Requirements: 5.3, 5.4
    private var textDisplayView: some View {
        VStack(spacing: 16) {
            // 显示文字内容
            ScrollView {
                Text(vm.displayText)
                    .font(Typography.body)
                    .foregroundColor(Colors.slateText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxHeight: 200)
        }
        .frame(minHeight: 100)
    }
    
    // MARK: - Error Banner
    
    /// 错误提示横幅
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Colors.amber)
            
            Text(message)
                .font(Typography.caption)
                .foregroundColor(Colors.slateText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Colors.amber.opacity(0.1))
        )
    }
    
    // MARK: - Control Bar
    
    /// 底部控制栏：设置按钮 + 挂断按钮
    /// Requirements: 5.5, 6.1
    private var controlBar: some View {
        HStack(spacing: 60) {
            // 设置按钮（跳转系统 Siri 设置）
            Button(action: {
                vm.openVoiceSettings()
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Colors.cardBackground)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Colors.slate600)
                    }
                    
                    Text("设置")
                        .font(Typography.caption)
                        .foregroundColor(Colors.slate600)
                }
            }
            .buttonStyle(.plain)
            
            // 挂断按钮（红色圆形）
            Button(action: {
                // Only dismiss - endCall will be called in onDisappear
                dismiss()
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Colors.red)
                            .frame(width: 72, height: 72)
                            .shadow(color: Colors.red.opacity(0.3), radius: 8, y: 4)
                        
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Text("挂断")
                        .font(Typography.caption)
                        .foregroundColor(Colors.slate600)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Thinking Animation

/// AI 思考中动画
struct ThinkingAnimation: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Colors.slate500)
                    .frame(width: 12, height: 12)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Speaking Icon

/// AI 说话中图标动画（iOS 16.1 兼容）
struct SpeakingIcon: View {
    @State private var animating = false
    
    var body: some View {
        Image(systemName: "speaker.wave.2.fill")
            .font(.system(size: 40))
            .foregroundColor(Colors.indigo)
            .opacity(animating ? 1.0 : 0.5)
            .scaleEffect(animating ? 1.05 : 0.95)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

// MARK: - Preview

#if DEBUG
struct VoiceCallScreen_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCallScreen(conversationId: nil)
    }
}
#endif
