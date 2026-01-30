//
//  LoginViewModel.swift
//  guanji0.34
//
//  登录视图模型
//  管理登录状态和错误，处理 OAuth 社交登录
//  - Requirements: 3.3, 3.4, 3.5
//

import Foundation
import SwiftUI
import Combine

/// 登录视图模型
/// 管理登录状态、错误处理、Google/Apple OAuth 登录
/// - Requirements: 3.3, 3.4, 3.5
@MainActor
public final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 是否正在加载
    /// - Requirements: 3.6
    @Published public private(set) var isLoading: Bool = false
    
    /// 错误信息
    /// - Requirements: 3.7
    @Published public var error: AuthError?
    
    // MARK: - Dependencies
    
    /// 认证服务
    private let authService: AuthService
    
    // MARK: - Initialization
    
    /// 初始化登录视图模型
    /// - Parameter authService: 认证服务实例
    public init(authService: AuthService = .shared) {
        self.authService = authService
    }
    
    // MARK: - Computed Properties
    
    /// 是否有错误
    public var hasError: Bool {
        error != nil
    }
    
    // MARK: - Google Sign In
    
    /// 使用 Google 登录
    /// - Requirements: 3.3
    public func signInWithGoogle() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await authService.signInWithGoogle()
                // 登录成功，authService 会更新 authState
            } catch let authError as AuthError {
                // 用户取消不显示错误
                if case .oauthCancelled = authError {
                    // 静默处理
                } else {
                    self.error = authError
                }
            } catch {
                self.error = AuthError.from(error)
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Apple Sign In
    
    /// 使用 Apple 登录
    /// - Requirements: 3.4
    public func signInWithApple() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await authService.signInWithApple()
                // 登录成功，authService 会更新 authState
            } catch let authError as AuthError {
                // 用户取消不显示错误
                if case .oauthCancelled = authError {
                    // 静默处理
                } else {
                    self.error = authError
                }
            } catch {
                self.error = AuthError.from(error)
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Error Handling
    
    /// 清除错误
    public func clearError() {
        error = nil
    }
}
