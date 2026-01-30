//
//  RootView.swift
//  guanji0.34
//
//  根视图 - 根据认证状态显示不同界面
//  - Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
//

import SwiftUI

/// 根视图
/// 根据认证状态显示登录界面或主应用界面
/// - Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
public struct RootView: View {
    
    /// 认证服务
    /// - Requirements: 10.1, 10.3
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        Group {
            switch authService.authState {
            case .unknown:
                // 启动画面/加载状态
                // - Requirements: 11.1
                LaunchScreen()
                
            case .unauthenticated, .sessionExpired:
                // 登录界面
                // - Requirements: 11.1, 11.4
                LoginScreen()
                #if DEBUG
                    .overlay(alignment: .topTrailing) {
                        DevBypassButton()
                            .padding(.top, 60)
                            .padding(.trailing, 20)
                    }
                #endif
                
            case .authenticated:
                // 主应用界面
                // - Requirements: 11.2, 11.3
                MainAppView()
                    .environmentObject(appState)
            }
        }
        .task {
            // 应用启动时尝试恢复会话
            // - Requirements: 11.1, 11.2, 10.3
            await restoreSessionOnLaunch()
        }
    }
    
    /// 启动时恢复会话
    /// 尝试从持久化存储恢复登录状态
    private func restoreSessionOnLaunch() async {
        // 如果已经不是 unknown 状态，说明已经处理过了
        guard authService.authState == .unknown else { return }
        
        // 尝试恢复会话
        let restored = await authService.restoreSession()
        
        if !restored {
            print("[RootView] No valid session, showing login")
        } else {
            print("[RootView] Session restored successfully")
        }
    }
}

// MARK: - Launch Screen

#if DEBUG
/// 开发者快速登录按钮
/// 仅在 DEBUG 模式下可用，跳过认证直接进入主界面
private struct DevBypassButton: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Button(action: {
            // 设置一个假的认证状态，跳过登录
            authService.devBypassLogin()
        }) {
            Text("DEV")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.8))
                .cornerRadius(4)
        }
    }
}
#endif

/// 启动画面
/// 在应用启动时显示，等待会话恢复
private struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            RobotAvatar(mood: .processing, size: 120)
        }
    }
}

// MARK: - Main App View

/// 主应用视图
/// 包含主要的应用内容（TimelineScreen）
/// - Requirements: 11.2, 11.3
private struct MainAppView: View {
    var body: some View {
        NavigationStack {
            TimelineScreen()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
#endif
