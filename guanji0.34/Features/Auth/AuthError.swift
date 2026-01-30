//
//  AuthError.swift
//  guanji0.34
//
//  认证错误类型 (Cognito OAuth)
//  - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
//

import Foundation

// MARK: - Auth Error

/// 认证错误类型
/// 定义 Cognito OAuth 认证相关的错误，并提供本地化错误描述
/// - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
public enum AuthError: LocalizedError, Equatable {
    
    // MARK: - Session Errors
    
    /// 会话已过期
    /// - Requirements: 7.1
    case sessionExpired
    
    /// Token 刷新失败
    case tokenRefreshFailed
    
    // MARK: - Apple Sign In Errors
    
    /// 用户取消 Apple 登录
    case appleSignInCancelled
    
    /// Apple 登录失败
    case appleSignInFailed(String)
    
    // MARK: - OAuth Errors (Cognito)
    
    /// 用户取消 OAuth 登录
    /// - Requirements: 1.6
    case oauthCancelled
    
    /// OAuth 登录失败
    /// - Requirements: 1.7
    case oauthFailed(String)
    
    /// Token 交换失败
    /// - Requirements: 1.7
    case tokenExchangeFailed(String)
    
    // MARK: - Network Errors
    
    /// 网络连接失败
    /// - Requirements: 7.4
    case networkError(String)
    
    /// 服务不可用
    /// - Requirements: 7.3
    case serviceUnavailable
    
    // MARK: - Rate Limiting
    
    /// 请求过于频繁 (429)
    /// - Requirements: 7.2
    case rateLimited
    
    // MARK: - Storage Errors
    
    /// Keychain 操作错误
    case keychainError(String)
    
    // MARK: - Unknown Error
    
    /// 未知错误
    case unknown(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .sessionExpired:
            return NSLocalizedString("auth.error.sessionExpired", comment: "会话已过期，请重新登录")
        case .tokenRefreshFailed:
            return NSLocalizedString("auth.error.tokenRefreshFailed", comment: "会话已过期，请重新登录")
        case .appleSignInCancelled:
            return NSLocalizedString("auth.error.appleSignInCancelled", comment: "登录已取消")
        case .appleSignInFailed(let message):
            return String(format: NSLocalizedString("auth.error.appleSignInFailed", comment: "Apple 登录失败: %@"), message)
        case .oauthCancelled:
            return NSLocalizedString("auth.error.oauthCancelled", comment: "登录已取消")
        case .oauthFailed(let message):
            return String(format: NSLocalizedString("auth.error.oauthFailed", comment: "登录失败: %@"), message)
        case .tokenExchangeFailed(let message):
            return String(format: NSLocalizedString("auth.error.tokenExchangeFailed", comment: "Token 获取失败: %@"), message)
        case .networkError:
            return NSLocalizedString("auth.error.networkError", comment: "网络连接失败，请检查网络")
        case .serviceUnavailable:
            return NSLocalizedString("auth.error.serviceUnavailable", comment: "服务器错误，请稍后重试")
        case .rateLimited:
            return NSLocalizedString("auth.error.rateLimited", comment: "使用额度已用完，请稍后再试")
        case .keychainError:
            return NSLocalizedString("auth.error.keychainError", comment: "存储错误")
        case .unknown(let message):
            return message
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionExpired, .sessionExpired),
             (.tokenRefreshFailed, .tokenRefreshFailed),
             (.appleSignInCancelled, .appleSignInCancelled),
             (.serviceUnavailable, .serviceUnavailable),
             (.rateLimited, .rateLimited),
             (.oauthCancelled, .oauthCancelled):
            return true
        case (.appleSignInFailed(let lhsMsg), .appleSignInFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.oauthFailed(let lhsMsg), .oauthFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.tokenExchangeFailed(let lhsMsg), .tokenExchangeFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.networkError(let lhsMsg), .networkError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.keychainError(let lhsMsg), .keychainError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Error Conversion

extension AuthError {
    
    /// 从错误转换为 AuthError
    /// - Parameter error: 原始错误
    /// - Returns: 对应的 AuthError
    /// - Requirements: 7.1, 7.2, 7.3, 7.4
    public static func from(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        // Check for URL/Network errors
        if let urlError = error as? URLError {
            return from(urlError: urlError)
        }
        
        // Check NSError domain for network issues
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkError("网络连接已断开")
            case NSURLErrorTimedOut:
                return .networkError("请求超时")
            default:
                return .networkError(error.localizedDescription)
            }
        }
        
        // Check for session/token errors
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("session") && errorString.contains("expired") {
            return .sessionExpired
        }
        
        if errorString.contains("refresh") && errorString.contains("failed") {
            return .tokenRefreshFailed
        }
        
        if errorString.contains("rate limit") ||
           errorString.contains("too many requests") {
            return .rateLimited
        }
        
        if errorString.contains("service unavailable") ||
           errorString.contains("503") ||
           errorString.contains("500") {
            return .serviceUnavailable
        }
        
        // Default to unknown error
        return .unknown(error.localizedDescription)
    }
    
    /// 从 URLError 转换为 AuthError
    /// - Parameter urlError: URL 错误
    /// - Returns: 对应的 AuthError
    /// - Requirements: 7.4
    public static func from(urlError: URLError) -> AuthError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError("网络连接已断开")
        case .timedOut:
            return .networkError("请求超时")
        case .cannotConnectToHost, .cannotFindHost:
            return .serviceUnavailable
        default:
            return .networkError(urlError.localizedDescription)
        }
    }
    
    /// 从 HTTP 状态码转换为 AuthError
    /// - Parameter statusCode: HTTP 状态码
    /// - Returns: 对应的 AuthError
    /// - Requirements: 7.1, 7.2, 7.3
    public static func from(statusCode: Int) -> AuthError {
        switch statusCode {
        case 401:
            return .sessionExpired
        case 429:
            return .rateLimited
        case 500, 502, 503:
            return .serviceUnavailable
        default:
            return .unknown("HTTP \(statusCode)")
        }
    }
}

// MARK: - Error Code

extension AuthError {
    
    /// 错误代码，用于日志和调试
    /// - Requirements: 7.5
    public var errorCode: String {
        switch self {
        case .sessionExpired: return "AUTH_SESSION_EXPIRED"
        case .tokenRefreshFailed: return "AUTH_TOKEN_REFRESH_FAILED"
        case .appleSignInCancelled: return "AUTH_APPLE_CANCELLED"
        case .appleSignInFailed: return "AUTH_APPLE_FAILED"
        case .oauthCancelled: return "AUTH_OAUTH_CANCELLED"
        case .oauthFailed: return "AUTH_OAUTH_FAILED"
        case .tokenExchangeFailed: return "AUTH_TOKEN_EXCHANGE_FAILED"
        case .networkError: return "AUTH_NETWORK_ERROR"
        case .serviceUnavailable: return "AUTH_SERVICE_UNAVAILABLE"
        case .rateLimited: return "AUTH_RATE_LIMITED"
        case .keychainError: return "AUTH_KEYCHAIN_ERROR"
        case .unknown: return "AUTH_UNKNOWN"
        }
    }
    
    /// 是否为可恢复错误（用户可以重试）
    public var isRecoverable: Bool {
        switch self {
        case .networkError, .serviceUnavailable, .rateLimited:
            return true
        case .sessionExpired, .tokenRefreshFailed:
            return true // User can re-login
        case .appleSignInCancelled, .oauthCancelled:
            return true // User can retry
        case .oauthFailed, .tokenExchangeFailed:
            return true // User can retry
        case .appleSignInFailed, .keychainError, .unknown:
            return false
        }
    }
}
