//
//  AuthService.swift
//  guanji0.34
//
//  认证服务 - 与后端 API 通信处理所有认证相关操作
//  使用 Session/Cookie 机制进行认证
//  登录状态通过 UserDefaults 持久化
//  - Requirements: 1.x, 2.x, 3.x, 4.x, 5.x, 6.x, 7.x, 8.x
//

import Foundation
import Combine
import AuthenticationServices
import UIKit

// MARK: - Auth State

/// 认证状态
/// - Requirements: 9.1, 9.2, 6.2
public enum AuthState: Equatable {
    /// 未知状态（应用启动时）
    case unknown
    /// 未认证
    case unauthenticated
    /// 已认证
    case authenticated(userId: String)
    /// 会话过期
    case sessionExpired
    
    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.unauthenticated, .unauthenticated),
             (.sessionExpired, .sessionExpired):
            return true
        case (.authenticated(let lhsId), .authenticated(let rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

// MARK: - URL Session Protocol (for testing)

/// URLSession 协议，用于依赖注入和测试
/// - Requirements: 8.1
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Auth Persistence Keys (Legacy)

private enum AuthPersistenceKeys {
    static let isLoggedIn = "auth.isLoggedIn"
    static let userId = "auth.userId"
    static let username = "auth.username"
    static let apiKey = "auth.apiKey"
    static let sessionCookies = "auth.sessionCookies"
}

// MARK: - Cognito OAuth Token Keys

/// Token 存储 Keys (Cognito OAuth)
/// - Requirements: 1.1, 1.2
private enum TokenKeys {
    static let idToken = "auth.idToken"
    static let refreshToken = "auth.refreshToken"
    static let userId = "auth.cognito.userId"
    static let userEmail = "auth.cognito.userEmail"
}

// MARK: - Keychain Storage (for immediate persistence)

private let keychain = KeychainService.shared

// MARK: - UserDefaults Storage (primary storage)

private let defaults = UserDefaults.standard

// MARK: - Auth Service

/// 认证服务
/// 处理所有认证相关逻辑，包括登录、2FA验证、注册、验证码发送和登出
/// - Requirements: 6.1, 8.1
public final class AuthService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = AuthService()
    
    // MARK: - Cognito OAuth Configuration
    
    /// Cognito Client ID
    /// - Requirements: 1.1, 1.2
    private let cognitoClientId = "1ij4bhqpi2cgoto4shuhl353ro"
    
    /// Cognito Hosted UI Domain
    /// - Requirements: 1.1, 1.2
    private let cognitoHostedUIDomain = "https://jing-ai-auth.auth.ap-northeast-1.amazoncognito.com"
    
    /// OAuth Redirect URI
    /// - Requirements: 1.1, 1.2
    private let redirectURI = "guanji://auth/callback"
    
    // MARK: - Published Properties
    
    /// 当前认证状态
    /// - Requirements: 6.1, 6.2
    @Published public private(set) var authState: AuthState = .unknown
    
    /// 当前用户数据
    @Published public private(set) var currentUser: UserData?
    
    /// 是否正在加载
    @Published public private(set) var isLoading: Bool = false
    
    /// 错误信息
    @Published public private(set) var error: AuthError?
    
    /// 当前 ID Token (用于 API 认证)
    /// - Requirements: 1.4, 2.6
    @Published public private(set) var idToken: String?
    
    // MARK: - Configuration
    
    /// 后端 API 基础 URL (Legacy new-api)
    /// - Requirements: 8.1
    private let baseURL: String
    
    /// jing-backend API 基础 URL (Cognito OAuth)
    /// - Requirements: 1.1, 1.2
    private let jingBackendURL: String
    
    /// URLSession 实例（支持 cookie 存储）
    /// - Requirements: 8.1
    private let session: URLSessionProtocol
    
    /// Cookie 存储
    /// - Requirements: 8.1
    private let cookieStorage: HTTPCookieStorage
    
    /// UserDefaults 用于持久化登录状态
    private let userDefaults: UserDefaults
    
    // MARK: - API Endpoints (Legacy - kept for logout only)
    
    private enum Endpoint {
        static let logout = "/api/user/logout"
        static let userSelf = "/api/user/self"  // 获取当前用户信息
    }
    
    // MARK: - Cognito OAuth Endpoints (jing-backend)
    
    /// Cognito OAuth API 端点
    /// - Requirements: 1.3, 2.3
    private enum CognitoEndpoint {
        static let token = "/api/auth/token"      // 授权码换 Token
        static let refresh = "/api/auth/refresh"  // 刷新 Token
        static let userMe = "/api/users/me"       // 获取用户信息
    }
    
    // MARK: - Initialization
    
    /// 初始化认证服务
    /// - Parameters:
    ///   - baseURL: 后端 API 基础 URL (Legacy)
    ///   - jingBackendURL: jing-backend API 基础 URL (Cognito OAuth)
    ///   - session: URLSession 实例（用于依赖注入）
    ///   - cookieStorage: Cookie 存储实例
    ///   - userDefaults: UserDefaults 实例
    /// - Requirements: 8.1, 1.1, 1.2
    public init(
        baseURL: String = "https://api.jiangzefang.store",
        jingBackendURL: String = "https://api.jingever.com",
        session: URLSessionProtocol? = nil,
        cookieStorage: HTTPCookieStorage = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.baseURL = baseURL
        self.jingBackendURL = jingBackendURL
        self.cookieStorage = cookieStorage
        self.userDefaults = userDefaults
        
        // 配置 URLSession 以支持 cookie 存储
        // - Requirements: 8.1
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = cookieStorage
            configuration.httpCookieAcceptPolicy = .always
            configuration.httpShouldSetCookies = true
            self.session = URLSession(configuration: configuration)
        }
        
        // 从 Keychain 恢复 ID Token (Cognito OAuth)
        // - Requirements: 2.1
        self.idToken = keychain.string(forKey: TokenKeys.idToken)
    }
    
    // MARK: - Computed Properties
    
    /// 检查用户是否已登录
    public var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    /// 检查是否有可用的 ID Token (Cognito OAuth)
    /// - Requirements: 2.6
    public var hasIdToken: Bool {
        return idToken != nil && !idToken!.isEmpty
    }
    
    // MARK: - Cognito OAuth Login
    
    /// 使用 Google 登录 (通过 Cognito Hosted UI)
    /// - Requirements: 1.1
    @MainActor
    public func signInWithGoogle() async throws {
        try await performOAuthLogin(provider: "Google")
    }
    
    /// 使用 Apple 原生登录
    /// 使用 ASAuthorizationController 进行原生 Apple Sign In
    /// - Requirements: 1.2
    @MainActor
    public func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        // 使用 AppleSignInCoordinator 进行原生登录
        let coordinator = AppleSignInCoordinator.shared
        
        do {
            let result = try await coordinator.signIn()
            
            print("[AuthService] Apple Sign In success, sending to backend...")
            print("[AuthService] User ID: \(result.userIdentifier)")
            print("[AuthService] Email: \(result.email ?? "hidden")")
            
            // 发送 identity token 到后端验证
            try await verifyAppleToken(result: result)
            
        } catch let error as AppleSignInError {
            switch error {
            case .cancelled:
                throw AuthError.oauthCancelled
            case .failed(let message):
                throw AuthError.oauthFailed(message)
            case .invalidResponse:
                throw AuthError.oauthFailed("Invalid Apple response")
            }
        }
    }
    
    /// 发送 Apple identity token 到后端验证
    @MainActor
    private func verifyAppleToken(result: AppleSignInResult) async throws {
        guard let url = URL(string: "\(jingBackendURL)/api/auth/apple") else {
            throw AuthError.tokenExchangeFailed("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 构建请求体
        let appleRequest = AppleTokenRequest(
            identityToken: result.identityToken,
            authorizationCode: result.authorizationCode,
            userIdentifier: result.userIdentifier,
            email: result.email,
            fullName: result.fullName
        )
        request.httpBody = try JSONEncoder().encode(appleRequest)
        
        print("[AuthService] Verifying Apple token at: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.tokenExchangeFailed("Invalid response")
        }
        
        print("[AuthService] Apple token verification response: HTTP \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("[AuthService] Apple token error: \(errorString)")
            }
            throw AuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析响应
        let apiResponse = try JSONDecoder().decode(APIResponse<TokenResponse>.self, from: data)
        
        guard apiResponse.success, let tokenResponse = apiResponse.data else {
            throw AuthError.tokenExchangeFailed(apiResponse.message)
        }
        
        print("[AuthService] Apple token verification successful")
        
        // 存储 Token 到 Keychain
        storeTokens(tokenResponse)
        
        // 更新 authState 为 authenticated
        authState = .authenticated(userId: "apple")
        
        // 获取用户信息
        await fetchCognitoUserInfo()
    }
    
    /// 通用 OAuth 登录流程 (用于 Google)
    /// - Parameter provider: OAuth 提供商 (Google)
    /// - Requirements: 1.1, 1.6
    @MainActor
    private func performOAuthLogin(provider: String) async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        // 构建 Cognito Hosted UI URL
        // - Requirements: 1.1, 1.2
        guard let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw AuthError.oauthFailed("Invalid redirect URI")
        }
        
        // 注意：scope 使用 %20 或 + 分隔，这里使用 URL 编码的空格
        let authURLString = "\(cognitoHostedUIDomain)/oauth2/authorize?" +
            "client_id=\(cognitoClientId)" +
            "&response_type=code" +
            "&scope=openid%20email%20profile" +
            "&redirect_uri=\(encodedRedirectURI)" +
            "&identity_provider=\(provider)"
        
        guard let authURL = URL(string: authURLString) else {
            throw AuthError.oauthFailed("Invalid auth URL")
        }
        
        print("[AuthService] Starting OAuth login with provider: \(provider)")
        print("[AuthService] Auth URL: \(authURLString)")
        
        // 使用 ASWebAuthenticationSession 进行 OAuth 登录
        // - Requirements: 1.1, 1.2
        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "guanji"
            ) { callbackURL, error in
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        // 用户取消登录
                        // - Requirements: 1.6
                        continuation.resume(throwing: AuthError.oauthCancelled)
                    } else {
                        continuation.resume(throwing: AuthError.oauthFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.oauthFailed("No callback URL"))
                    return
                }
                
                continuation.resume(returning: callbackURL)
            }
            
            // 设置 presentation context provider
            session.presentationContextProvider = OAuthPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            
            // 启动认证会话
            if !session.start() {
                continuation.resume(throwing: AuthError.oauthFailed("Failed to start auth session"))
            }
        }
        
        // 从回调 URL 提取授权码
        // - Requirements: 1.3
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.oauthFailed("No authorization code in callback")
        }
        
        print("[AuthService] Got authorization code: \(code.prefix(10))...")
        
        // 用授权码换取 Token
        // - Requirements: 1.3, 1.4, 1.5
        try await exchangeCodeForTokens(code: code)
    }
    
    /// 用授权码换取 Token
    /// - Parameter code: 授权码
    /// - Requirements: 1.3, 1.4, 1.5
    @MainActor
    private func exchangeCodeForTokens(code: String) async throws {
        guard let url = URL(string: "\(jingBackendURL)\(CognitoEndpoint.token)") else {
            throw AuthError.tokenExchangeFailed("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 构建请求体
        let tokenRequest = TokenExchangeRequest(code: code, redirectUri: redirectURI)
        request.httpBody = try JSONEncoder().encode(tokenRequest)
        
        print("[AuthService] Exchanging code for tokens at: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.tokenExchangeFailed("Invalid response")
        }
        
        print("[AuthService] Token exchange response: HTTP \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            // 尝试解析错误响应
            if let errorString = String(data: data, encoding: .utf8) {
                print("[AuthService] Token exchange error: \(errorString)")
            }
            throw AuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析 Token 响应 (后端返回 APIResponse<TokenResponse> 格式)
        // - Requirements: 1.3
        let apiResponse = try JSONDecoder().decode(APIResponse<TokenResponse>.self, from: data)
        
        guard apiResponse.success, let tokenResponse = apiResponse.data else {
            throw AuthError.tokenExchangeFailed(apiResponse.message)
        }
        
        print("[AuthService] Token exchange successful")
        print("[AuthService] ID Token: \(tokenResponse.idToken.prefix(20))...")
        print("[AuthService] Refresh Token: \(tokenResponse.refreshToken.prefix(20))...")
        
        // 存储 Token 到 Keychain
        // - Requirements: 1.4
        storeTokens(tokenResponse)
        
        // 更新 authState 为 authenticated
        // - Requirements: 1.5
        authState = .authenticated(userId: "cognito")
        
        // 获取用户信息
        await fetchCognitoUserInfo()
    }
    
    /// 存储 Token 到 Keychain
    /// - Parameter tokenResponse: Token 响应
    /// - Requirements: 1.4
    private func storeTokens(_ tokenResponse: TokenResponse) {
        // 存储 ID Token
        _ = keychain.set(tokenResponse.idToken, forKey: TokenKeys.idToken)
        self.idToken = tokenResponse.idToken
        
        // 存储 Refresh Token
        _ = keychain.set(tokenResponse.refreshToken, forKey: TokenKeys.refreshToken)
        
        print("[AuthService] Tokens stored to Keychain")
    }
    
    /// 获取 Cognito 用户信息
    /// - Requirements: 2.2
    @MainActor
    private func fetchCognitoUserInfo() async {
        guard let token = idToken else {
            print("[AuthService] fetchCognitoUserInfo: No ID Token")
            return
        }
        
        guard let url = URL(string: "\(jingBackendURL)\(CognitoEndpoint.userMe)") else {
            print("[AuthService] fetchCognitoUserInfo: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[AuthService] fetchCognitoUserInfo: Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                let userInfo = try JSONDecoder().decode(CognitoUserInfo.self, from: data)
                
                // 存储用户信息
                _ = keychain.set(userInfo.id, forKey: TokenKeys.userId)
                _ = keychain.set(userInfo.email, forKey: TokenKeys.userEmail)
                
                // 更新 authState 为 authenticated (使用真实用户 ID)
                authState = .authenticated(userId: userInfo.id)
                
                print("[AuthService] User info fetched: \(userInfo.email)")
            } else {
                print("[AuthService] fetchCognitoUserInfo: HTTP \(httpResponse.statusCode)")
            }
        } catch {
            print("[AuthService] fetchCognitoUserInfo failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Token Refresh
    
    /// 刷新 Token
    /// - Requirements: 2.3, 2.4, 2.5
    @MainActor
    public func refreshTokens() async throws {
        // 从 Keychain 读取 Refresh Token
        guard let refreshToken = keychain.string(forKey: TokenKeys.refreshToken) else {
            print("[AuthService] refreshTokens: No refresh token found")
            clearCognitoTokens()
            authState = .unauthenticated
            throw AuthError.tokenRefreshFailed
        }
        
        guard let url = URL(string: "\(jingBackendURL)\(CognitoEndpoint.refresh)") else {
            throw AuthError.tokenRefreshFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 构建请求体
        let refreshRequest = TokenRefreshRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(refreshRequest)
        
        print("[AuthService] Refreshing tokens...")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.tokenRefreshFailed
            }
            
            print("[AuthService] Token refresh response: HTTP \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 400 {
                // 刷新失败，清除 tokens 并设置 unauthenticated
                // - Requirements: 2.5
                if let errorString = String(data: data, encoding: .utf8) {
                    print("[AuthService] Token refresh error: \(errorString)")
                }
                clearCognitoTokens()
                authState = .unauthenticated
                throw AuthError.tokenRefreshFailed
            }
            
            // 解析 Token 响应 (后端返回 APIResponse<TokenResponse> 格式)
            let apiResponse = try JSONDecoder().decode(APIResponse<TokenResponse>.self, from: data)
            
            guard apiResponse.success, let tokenResponse = apiResponse.data else {
                clearCognitoTokens()
                authState = .unauthenticated
                throw AuthError.tokenRefreshFailed
            }
            
            // 更新 Keychain 中的 tokens
            // - Requirements: 2.4
            storeTokens(tokenResponse)
            
            print("[AuthService] Tokens refreshed successfully")
        } catch let authError as AuthError {
            throw authError
        } catch {
            // 刷新失败，清除 tokens 并设置 unauthenticated
            // - Requirements: 2.5
            print("[AuthService] Token refresh failed: \(error.localizedDescription)")
            clearCognitoTokens()
            authState = .unauthenticated
            throw AuthError.tokenRefreshFailed
        }
    }
    
    /// 清除 Cognito OAuth Tokens
    /// - Requirements: 2.5
    private func clearCognitoTokens() {
        keychain.delete(TokenKeys.idToken)
        keychain.delete(TokenKeys.refreshToken)
        keychain.delete(TokenKeys.userId)
        keychain.delete(TokenKeys.userEmail)
        self.idToken = nil
        print("[AuthService] Cognito tokens cleared")
    }
    
    // MARK: - Session Restoration
    
    /// 尝试恢复登录会话
    /// 在 App 启动时调用，检查是否有保存的登录状态
    /// 优先尝试 Cognito OAuth tokens，然后回退到 Legacy session
    /// - Returns: 是否成功恢复会话
    /// - Requirements: 2.1, 2.2
    @MainActor
    public func restoreSession() async -> Bool {
        // 首先尝试恢复 Cognito OAuth session
        // - Requirements: 2.1
        if await restoreCognitoSession() {
            return true
        }
        
        // 回退到 Legacy session (new-api)
        return await restoreLegacySession()
    }
    
    /// 尝试恢复 Cognito OAuth 会话
    /// - Returns: 是否成功恢复会话
    /// - Requirements: 2.1, 2.2
    @MainActor
    private func restoreCognitoSession() async -> Bool {
        // 从 Keychain 读取 idToken 和 refreshToken
        // - Requirements: 2.1
        guard let savedIdToken = keychain.string(forKey: TokenKeys.idToken),
              let _ = keychain.string(forKey: TokenKeys.refreshToken) else {
            print("[AuthService] No Cognito tokens found")
            return false
        }
        
        self.idToken = savedIdToken
        print("[AuthService] Found Cognito tokens, validating...")
        
        // 调用 GET /api/users/me 验证 token 有效性
        // - Requirements: 2.2
        do {
            let isValid = try await withTimeout(seconds: 5) {
                try await self.validateCognitoToken()
            }
            
            if isValid {
                print("[AuthService] Cognito session restored successfully")
                return true
            }
        } catch {
            print("[AuthService] Cognito token validation failed: \(error.localizedDescription)")
        }
        
        // 如果 401 则尝试 refreshTokens()
        // - Requirements: 2.2
        do {
            try await refreshTokens()
            
            // 刷新成功后再次验证
            let isValid = try await validateCognitoToken()
            if isValid {
                print("[AuthService] Cognito session restored after token refresh")
                return true
            }
        } catch {
            print("[AuthService] Token refresh failed: \(error.localizedDescription)")
        }
        
        // 刷新失败，清除 tokens
        clearCognitoTokens()
        return false
    }
    
    /// 验证 Cognito Token 有效性
    /// - Returns: Token 是否有效
    /// - Requirements: 2.2
    private func validateCognitoToken() async throws -> Bool {
        guard let token = idToken else {
            return false
        }
        
        guard let url = URL(string: "\(jingBackendURL)\(CognitoEndpoint.userMe)") else {
            throw AuthError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }
        
        print("[AuthService] validateCognitoToken: HTTP \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            // Token 无效或过期
            throw AuthError.sessionExpired
        }
        
        if httpResponse.statusCode >= 400 {
            throw AuthError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析用户信息
        let userInfo = try JSONDecoder().decode(CognitoUserInfo.self, from: data)
        
        // 存储用户信息
        _ = keychain.set(userInfo.id, forKey: TokenKeys.userId)
        _ = keychain.set(userInfo.email, forKey: TokenKeys.userEmail)
        
        // 更新 authState
        await MainActor.run {
            authState = .authenticated(userId: userInfo.id)
        }
        
        print("[AuthService] Cognito user validated: \(userInfo.email)")
        return true
    }
    
    /// 尝试恢复 Legacy 会话 (new-api) - 已弃用
    /// - Returns: 始终返回 false，因为 Legacy 会话已不再支持
    @MainActor
    private func restoreLegacySession() async -> Bool {
        // Legacy session 已弃用，直接返回 false
        authState = .unauthenticated
        return false
    }
    
    /// 带超时的异步操作
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AuthError.networkError("Request timeout")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// 验证当前会话是否有效
    private func validateSession() async throws -> UserData {
        guard let url = URL(string: "\(baseURL)\(Endpoint.userSelf)") else {
            throw AuthError.unknown("Invalid URL")
        }
        
        // 打印当前 cookie 状态用于调试
        if let cookies = cookieStorage.cookies(for: url) {
            print("[AuthService] validateSession: Found \(cookies.count) cookies for \(url)")
            for cookie in cookies {
                print("[AuthService]   - \(cookie.name): \(cookie.value.prefix(20))...")
            }
        } else {
            print("[AuthService] validateSession: No cookies found for \(url)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }
        
        print("[AuthService] validateSession: HTTP \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw AuthError.sessionExpired
        }
        
        if httpResponse.statusCode >= 400 {
            throw AuthError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<UserData>.self, from: data)
        
        if apiResponse.success, let userData = apiResponse.data {
            return userData
        } else {
            throw AuthError.sessionExpired
        }
    }
    
    /// 持久化登录状态（使用 Keychain）
    private func persistAuth(userId: String, username: String?) {
        _ = keychain.set(true, forKey: AuthPersistenceKeys.isLoggedIn)
        _ = keychain.set(userId, forKey: AuthPersistenceKeys.userId)
        if let username = username {
            _ = keychain.set(username, forKey: AuthPersistenceKeys.username)
        }
        
        // 同步持久化 session cookies
        persistSessionCookies()
        print("[AuthService] Auth persisted: userId=\(userId)")
    }
    
    /// 持久化 session cookies 到 Keychain
    private func persistSessionCookies() {
        guard let url = URL(string: baseURL),
              let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty else {
            return
        }
        
        // 将 cookies 转换为可序列化的字典数组
        var serializableCookies: [[String: Any]] = []
        
        for cookie in cookies {
            guard let properties = cookie.properties else { continue }
            
            var stringDict: [String: Any] = [:]
            for (key, value) in properties {
                if let date = value as? Date {
                    stringDict[key.rawValue] = date.timeIntervalSince1970
                    stringDict["\(key.rawValue)_isDate"] = true
                } else {
                    stringDict[key.rawValue] = value
                }
            }
            serializableCookies.append(stringDict)
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: serializableCookies, options: []) {
            _ = keychain.set(data, forKey: AuthPersistenceKeys.sessionCookies)
        }
    }
    
    /// 从 Keychain 恢复 session cookies
    private func restoreSessionCookies() {
        guard let cookieData = keychain.data(forKey: AuthPersistenceKeys.sessionCookies),
              let cookieArray = try? JSONSerialization.jsonObject(with: cookieData, options: []) as? [[String: Any]] else {
            return
        }
        
        for stringDict in cookieArray {
            var properties: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in stringDict {
                if key.hasSuffix("_isDate") { continue }
                
                let propertyKey = HTTPCookiePropertyKey(key)
                
                if stringDict["\(key)_isDate"] as? Bool == true,
                   let timeInterval = value as? TimeInterval {
                    properties[propertyKey] = Date(timeIntervalSince1970: timeInterval)
                } else {
                    properties[propertyKey] = value
                }
            }
            
            if let cookie = HTTPCookie(properties: properties) {
                cookieStorage.setCookie(cookie)
            }
        }
    }
    
    /// 清除持久化的认证状态
    private func clearPersistedAuth() {
        keychain.delete(AuthPersistenceKeys.isLoggedIn)
        keychain.delete(AuthPersistenceKeys.userId)
        keychain.delete(AuthPersistenceKeys.username)
        keychain.delete(AuthPersistenceKeys.apiKey)
        keychain.delete(AuthPersistenceKeys.sessionCookies)
    }

    
    // MARK: - Logout
    
    /// 用户登出
    /// - Throws: AuthError 如果登出失败（但本地数据仍会被清除）
    /// - Requirements: 5.1, 5.2, 5.3
    @MainActor
    public func logout() async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
            // 无论网络请求是否成功，都清除本地数据
            // - Requirements: 5.2, 5.3
            clearLocalData()
        }
        
        do {
            // 发送登出请求
            // - Requirements: 5.1
            guard let url = URL(string: "\(baseURL)\(Endpoint.logout)") else {
                throw AuthError.unknown("Invalid URL")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await session.data(for: request)
            
            // 检查 HTTP 状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode >= 400 {
                throw AuthError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            // 解析响应（可选，因为无论如何都会清除本地数据）
            if let apiResponse = try? JSONDecoder().decode(APIResponse<EmptyData>.self, from: data) {
                if !apiResponse.success {
                    print("[AuthService] Logout API returned error: \(apiResponse.message)")
                }
            }
            
            print("[AuthService] Logout successful")
        } catch {
            // 记录错误但不阻止本地数据清除
            print("[AuthService] Logout request failed: \(error.localizedDescription)")
            // 仍然抛出错误以通知调用者
            let convertedError = convertError(error)
            self.error = convertedError
            throw convertedError
        }
    }
    
    /// 清除本地数据
    /// - Requirements: 5.2, 5.3, 8.4
    private func clearLocalData() {
        // 更新认证状态
        // - Requirements: 5.2
        authState = .unauthenticated
        currentUser = nil
        
        // 清除持久化的认证状态
        clearPersistedAuth()
        
        // 清除 Cognito OAuth tokens
        clearCognitoTokens()
        
        // 清除 cookies
        // - Requirements: 5.3, 8.4
        clearCookies()
    }
    
    /// 清除所有与认证域相关的 cookies
    /// - Requirements: 8.4
    private func clearCookies() {
        guard let url = URL(string: baseURL) else { return }
        
        if let cookies = cookieStorage.cookies(for: url) {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
        
        print("[AuthService] Cookies cleared")
    }

    
    // MARK: - Network Helpers
    
    /// 执行 API 请求
    /// - Parameters:
    ///   - endpoint: API 端点路径
    ///   - method: HTTP 方法
    ///   - body: 请求体（可选）
    /// - Returns: 解码后的响应
    /// - Throws: 网络或解码错误
    private func performRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil as EmptyData?
    ) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuthError.unknown("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 编码请求体
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        
        // 执行请求
        let (data, response) = try await session.data(for: request)
        
        // 检查 HTTP 状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode >= 400 {
            // 尝试解析错误响应
            if let errorResponse = try? JSONDecoder().decode(APIResponse<EmptyData>.self, from: data) {
                throw AuthError.unknown(errorResponse.message)
            }
            throw AuthError.from(statusCode: httpResponse.statusCode)
        }
        
        // 解码响应
        let decoder = JSONDecoder()
        return try decoder.decode(R.self, from: data)
    }
    
    /// 转换错误为 AuthError
    /// - Parameter error: 原始错误
    /// - Returns: AuthError
    private func convertError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        
        if let urlError = error as? URLError {
            return AuthError.from(urlError: urlError)
        }
        
        if let decodingError = error as? DecodingError {
            return AuthError.unknown("Response parsing failed: \(decodingError.localizedDescription)")
        }
        
        return AuthError.from(error)
    }
    
    // MARK: - Testing Support
    
    /// 重置服务状态（仅用于测试）
    internal func reset() {
        authState = .unknown
        currentUser = nil
        isLoading = false
        error = nil
    }
    
    /// 设置认证状态
    /// 用于应用启动时初始化状态或测试
    /// - Parameter state: 新的认证状态
    public func setAuthState(_ state: AuthState) {
        authState = state
        if case .authenticated = state {
            // 如果有用户数据，保持不变
        } else {
            currentUser = nil
        }
    }
    
    #if DEBUG
    /// 开发者快速登录（跳过认证）
    /// 仅在 DEBUG 模式下可用
    @MainActor
    public func devBypassLogin() {
        print("[AuthService] DEV BYPASS: Skipping authentication")
        authState = .authenticated(userId: "dev-user")
    }
    #endif
}

// MARK: - OAuth Presentation Context Provider

/// OAuth 认证会话的 Presentation Context Provider
/// 用于 ASWebAuthenticationSession 显示登录界面
/// - Requirements: 1.1, 1.2
final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    static let shared = OAuthPresentationContextProvider()
    
    private override init() {
        super.init()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 获取当前活动的窗口
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            // 如果找不到窗口，创建一个新的
            return UIWindow()
        }
        return window
    }
}
