import SwiftUI

/// 模式切换按钮 - 单图标切换，符合 iOS 最佳实践
/// 显示当前模式的图标，点击切换到另一个模式
/// Requirements: 1.1, 1.2, 1.3, 7.1
public struct ModeToggleBar: View {
    @EnvironmentObject private var appState: AppState
    
    /// 切换模式时的回调
    public var onModeChange: ((AppMode) -> Void)?
    
    public init(onModeChange: ((AppMode) -> Void)? = nil) {
        self.onModeChange = onModeChange
    }
    
    public var body: some View {
        Button(action: toggleMode) {
            Image(systemName: currentIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    /// 当前模式对应的图标
    /// - 日记模式显示 sparkles（点击切换到 AI）
    /// - AI 模式显示 pencil.line（点击切换到日记）- 简洁的书写图标
    private var currentIcon: String {
        appState.currentMode == .journal ? "sparkles" : "pencil.line"
    }
    
    /// 图标颜色 - 统一使用正常颜色
    private var iconColor: Color {
        Colors.slateText
    }
    
    /// 背景颜色 - 统一使用正常背景
    private var backgroundColor: Color {
        Color(.systemGray6)
    }
    
    /// 切换模式
    private func toggleMode() {
        triggerHaptic()
        let newMode: AppMode = appState.currentMode == .journal ? .ai : .journal
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            appState.currentMode = newMode
        }
        onModeChange?(newMode)
    }
    
    /// 触发触觉反馈
    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

#if DEBUG
struct ModeToggleBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Journal mode - shows sparkles icon
            ModeToggleBar()
                .environmentObject({
                    let state = AppState()
                    state.currentMode = .journal
                    return state
                }())
            
            // AI mode - shows note.text icon
            ModeToggleBar()
                .environmentObject({
                    let state = AppState()
                    state.currentMode = .ai
                    return state
                }())
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
