//
//  AppleSignInCoordinator.swift
//  guanji0.34
//
//  Apple 登录协调器
//  处理 Sign in with Apple 的原生流程
//

import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Apple Sign In Error

/// Apple 登录错误
public enum AppleSignInError: Error {
    case cancelled
    case failed(String)
    case invalidResponse
}

// MARK: - Apple Sign In Result

/// Apple 登录结果
public struct AppleSignInResult {
    /// Apple 返回的 identity token (JWT)
    public let identityToken: String
    
    /// Apple 返回的 authorization code
    public let authorizationCode: String?
    
    /// Apple 用户标识符
    public let userIdentifier: String
    
    /// 用户邮箱（首次登录时可能提供）
    public let email: String?
    
    /// 用户全名（首次登录时可能提供）
    public let fullName: String?
}

// MARK: - Apple Token Request (for backend)

/// Apple Token 请求模型（发送到后端）
struct AppleTokenRequest: Codable {
    let identityToken: String
    let authorizationCode: String?
    let userIdentifier: String?
    let email: String?
    let fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
        case userIdentifier = "user_identifier"
        case email
        case fullName = "full_name"
    }
}

// MARK: - Apple Sign In Coordinator

/// Apple 登录协调器
/// 处理 Sign in with Apple 的原生流程
public final class AppleSignInCoordinator: NSObject {
    
    // MARK: - Singleton
    
    public static let shared = AppleSignInCoordinator()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Properties
    
    /// 登录完成回调
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    
    // MARK: - Public API
    
    /// 开始 Apple 登录流程
    /// - Returns: AppleSignInResult 包含 identity token 和用户信息
    /// - Throws: AppleSignInError 如果登录失败或被取消
    @MainActor
    public func signIn() async throws -> AppleSignInResult {
        // 创建 Apple ID 请求
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // 创建授权控制器
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        // 使用 async/await 等待结果
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            authorizationController.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    
    /// 授权成功回调
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.invalidResponse)
            continuation = nil
            return
        }
        
        // 获取 identity token
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleSignInError.failed("Unable to fetch identity token"))
            continuation = nil
            return
        }
        
        // 获取 authorization code
        var authorizationCode: String?
        if let authCodeData = appleIDCredential.authorizationCode {
            authorizationCode = String(data: authCodeData, encoding: .utf8)
        }
        
        // 获取用户全名
        var fullName: String?
        if let nameComponents = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: nameComponents)
            if !name.isEmpty {
                fullName = name
            }
        }
        
        let result = AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            userIdentifier: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: fullName
        )
        
        continuation?.resume(returning: result)
        continuation = nil
    }
    
    /// 授权失败回调
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let signInError: AppleSignInError
        
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                signInError = .cancelled
            default:
                signInError = .failed(error.localizedDescription)
            }
        } else {
            signInError = .failed(error.localizedDescription)
        }
        
        continuation?.resume(throwing: signInError)
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    
    /// 提供展示授权界面的窗口
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
