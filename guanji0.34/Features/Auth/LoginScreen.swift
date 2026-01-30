//
//  LoginScreen.swift
//  guanji0.34
//
//  登录界面
//  提供 Apple 原生登录和 Google OAuth 社交登录
//  - Requirements: 3.1, 3.2, 3.6, 3.7
//

import SwiftUI

/// 登录界面
/// 提供 Apple 和 Google 社交登录按钮
/// 机器人会显示用户本地存储的心情状态（老用户回归时的陪伴感）
/// - Requirements: 3.1, 3.2, 3.6, 3.7
public struct LoginScreen: View {
    
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // 从本地 DailyTracker 读取的心情状态
    @State private var robotMindValence: Int = 50
    @State private var robotBodyEnergy: Int = 50
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo 和标题
                    headerSection
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // 社交登录按钮
                    // - Requirements: 3.1, 3.2
                    socialLoginButtons
                    
                    // 错误提示
                    // - Requirements: 3.7
                    if let error = viewModel.error {
                        errorView(error)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .background(Colors.background)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Robot Avatar - 显示用户本地存储的心情状态
            // 老用户回归时，机器人会"记得"他们的状态
            RobotAvatarMood(
                mindValence: robotMindValence,
                bodyEnergy: robotBodyEnergy,
                theme: colorScheme == .dark ? .dark : .light,
                size: 140
            )
            
            Text(Localization.tr("AI.Welcome.Title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Colors.text)
            
            Text(Localization.tr("AI.Welcome.Subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
        .onAppear {
            loadLocalRobotState()
        }
    }
    
    /// 从本地 DailyTracker 加载机器人状态
    /// 即使用户未登录，本地数据仍然存在
    private func loadLocalRobotState() {
        DailyTrackerRepository.shared.reload()
        if let latest = DailyTrackerRepository.shared.loadLatest() {
            robotMindValence = latest.moodWeather
            robotBodyEnergy = latest.bodyEnergy
        }
        // 如果没有本地数据，保持默认 50/50
    }
    
    // MARK: - Social Login Buttons
    
    private var socialLoginButtons: some View {
        VStack(spacing: 16) {
            // Apple 登录按钮 (放在上面，主要登录方式)
            // - Requirements: 3.2
            Button(action: { viewModel.signInWithApple() }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                    }
                    Text("使用 Apple 登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(colorScheme == .dark ? Color.white : Color.black)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.7 : 1.0)
            
            // 分隔线
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("或")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)
            
            // Google 登录按钮 (放在下面，备选方式)
            // - Requirements: 3.1
            Button(action: { viewModel.signInWithGoogle() }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Colors.text))
                            .scaleEffect(0.8)
                    } else {
                        // Google Logo (使用 G 字母图标)
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                    }
                    Text("使用 Google 登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Colors.slateLight)
                .foregroundColor(Colors.text)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.7 : 1.0)
        }
    }
    
    // MARK: - Error View
    
    /// 错误提示视图
    /// - Requirements: 3.7
    private func errorView(_ error: AuthError) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Colors.red)
            
            Text(error.errorDescription ?? Localization.tr("auth.error.unknown"))
                .font(.footnote)
                .foregroundStyle(Colors.red)
            
            Spacer()
            
            Button(action: { viewModel.clearError() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Colors.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
#endif
