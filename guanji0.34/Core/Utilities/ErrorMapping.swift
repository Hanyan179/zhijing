//
//  ErrorMapping.swift
//  guanji0.34
//
//  错误消息映射工具
//  将 HTTP 状态码和网络错误映射到用户友好的错误消息
//  - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
//

import Foundation

// MARK: - API Error

/// 统一的 API 错误类型
/// 用于将各种错误映射到用户友好的消息
/// - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
public enum APIError: Error, LocalizedError, Equatable {
    
    // MARK: - HTTP Status Code Errors
    
    /// 会话已过期 (HTTP 401)
    /// - Requirements: 7.1
    case sessionExpired
    
    /// 使用额度已用完 (HTTP 429)
    /// - Requirements: 7.2
    case quotaExceeded
    
    /// 服务器错误 (HTTP 500, 502, 503)
    /// - Requirements: 7.3
    case serverError(Int)
    
    // MARK: - Network Errors
    
    /// 网络连接失败
    /// - Requirements: 7.4
    case networkUnavailable
    
    /// 请求超时
    case requestTimeout
    
    /// 无法连接到服务器
    case cannotConnectToHost
    
    // MARK: - OAuth Errors
    
    /// OAuth 登录失败
    /// - Requirements: 7.5
    case oauthFailed(String)
    
    // MARK: - Other Errors
    
    /// 未知错误
    case unknown(String)
    
    // MARK: - LocalizedError
    
    /// 用户友好的错误描述
    /// - Requirements: 7.1, 7.2, 7.3, 7.4
    public var errorDescription: String? {
        switch self {
        case .sessionExpired:
            // Requirements: 7.1
            return "会话已过期，请重新登录"
        case .quotaExceeded:
            // Requirements: 7.2
            return "使用额度已用完，请稍后再试"
        case .serverError(let code):
            // Requirements: 7.3
            if code == 502 || code == 503 {
                return "服务暂时不可用，请稍后重试"
            }
            return "服务器错误，请稍后重试"
        case .networkUnavailable:
            // Requirements: 7.4
            return "网络连接失败，请检查网络"
        case .requestTimeout:
            return "请求超时，请检查网络后重试"
        case .cannotConnectToHost:
            return "无法连接到服务器，请稍后重试"
        case .oauthFailed(let message):
            // Requirements: 7.5
            return message
        case .unknown(let message):
            return message
        }
    }
    
    // MARK: - Error Code (for logging)
    
    /// 错误代码，用于日志和调试
    /// - Requirements: 7.5, 7.6
    public var errorCode: String {
        switch self {
        case .sessionExpired:
            return "API_401_SESSION_EXPIRED"
        case .quotaExceeded:
            return "API_429_QUOTA_EXCEEDED"
        case .serverError(let code):
            return "API_\(code)_SERVER_ERROR"
        case .networkUnavailable:
            return "NET_NO_CONNECTION"
        case .requestTimeout:
            return "NET_TIMEOUT"
        case .cannotConnectToHost:
            return "NET_CANNOT_CONNECT"
        case .oauthFailed:
            return "OAUTH_FAILED"
        case .unknown:
            return "UNKNOWN_ERROR"
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionExpired, .sessionExpired),
             (.quotaExceeded, .quotaExceeded),
             (.networkUnavailable, .networkUnavailable),
             (.requestTimeout, .requestTimeout),
             (.cannotConnectToHost, .cannotConnectToHost):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.oauthFailed(let lhsMsg), .oauthFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Error Mapping Utility

/// 错误映射工具
/// 提供静态方法将各种错误类型映射到 APIError
/// - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
public enum ErrorMapper {
    
    // MARK: - HTTP Status Code Mapping
    
    /// 从 HTTP 状态码映射到 APIError
    /// - Parameter statusCode: HTTP 状态码
    /// - Returns: 对应的 APIError
    /// - Requirements: 7.1, 7.2, 7.3
    public static func fromStatusCode(_ statusCode: Int) -> APIError {
        switch statusCode {
        case 401:
            // Requirements: 7.1
            return .sessionExpired
        case 429:
            // Requirements: 7.2
            return .quotaExceeded
        case 500, 502, 503:
            // Requirements: 7.3
            return .serverError(statusCode)
        default:
            return .serverError(statusCode)
        }
    }
    
    /// 从 HTTP 状态码获取用户友好的错误消息
    /// - Parameter statusCode: HTTP 状态码
    /// - Returns: 用户友好的错误消息
    /// - Requirements: 7.1, 7.2, 7.3
    public static func messageForStatusCode(_ statusCode: Int) -> String {
        return fromStatusCode(statusCode).errorDescription ?? "未知错误"
    }
    
    // MARK: - Network Error Mapping
    
    /// 从 URLError 映射到 APIError
    /// - Parameter urlError: URL 错误
    /// - Returns: 对应的 APIError
    /// - Requirements: 7.4
    public static func fromURLError(_ urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            // Requirements: 7.4
            return .networkUnavailable
        case .timedOut:
            return .requestTimeout
        case .cannotConnectToHost, .cannotFindHost:
            return .cannotConnectToHost
        default:
            return .networkUnavailable
        }
    }
    
    /// 从 NSError 映射到 APIError
    /// - Parameter nsError: NS 错误
    /// - Returns: 对应的 APIError
    /// - Requirements: 7.4
    public static func fromNSError(_ nsError: NSError) -> APIError {
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                // Requirements: 7.4
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .requestTimeout
            case NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                return .cannotConnectToHost
            default:
                return .networkUnavailable
            }
        }
        return .unknown(nsError.localizedDescription)
    }
    
    /// 从任意 Error 映射到 APIError
    /// - Parameter error: 任意错误
    /// - Returns: 对应的 APIError
    /// - Requirements: 7.4
    public static func fromError(_ error: Error) -> APIError {
        // Check for URLError
        if let urlError = error as? URLError {
            return fromURLError(urlError)
        }
        
        // Check for NSError with URL domain
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return fromNSError(nsError)
        }
        
        // Check for AuthError
        if let authError = error as? AuthError {
            return fromAuthError(authError)
        }
        
        // Check for ClaudeflareError
        if let claudeflareError = error as? ClaudeflareError {
            return fromClaudeflareError(claudeflareError)
        }
        
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - AuthError Mapping
    
    /// 从 AuthError 映射到 APIError
    /// - Parameter authError: 认证错误
    /// - Returns: 对应的 APIError
    public static func fromAuthError(_ authError: AuthError) -> APIError {
        switch authError {
        case .sessionExpired, .tokenRefreshFailed:
            return .sessionExpired
        case .rateLimited:
            return .quotaExceeded
        case .serviceUnavailable:
            return .serverError(503)
        case .networkError:
            return .networkUnavailable
        case .oauthFailed(let message):
            return .oauthFailed(message)
        case .oauthCancelled, .appleSignInCancelled:
            return .oauthFailed("登录已取消")
        default:
            return .unknown(authError.errorDescription ?? "未知错误")
        }
    }
    
    // MARK: - ClaudeflareError Mapping
    
    /// 从 ClaudeflareError 映射到 APIError
    /// - Parameter claudeflareError: Claudeflare 错误
    /// - Returns: 对应的 APIError
    public static func fromClaudeflareError(_ claudeflareError: ClaudeflareError) -> APIError {
        switch claudeflareError {
        case .authenticationError:
            return .sessionExpired
        case .quotaExceeded:
            return .quotaExceeded
        case .serverError(let code):
            return .serverError(code)
        case .networkError:
            return .networkUnavailable
        default:
            return .unknown(claudeflareError.errorDescription ?? "未知错误")
        }
    }
    
    // MARK: - Logging
    
    /// 记录错误到日志
    /// - Parameters:
    ///   - error: 错误
    ///   - context: 上下文信息
    /// - Requirements: 7.5, 7.6
    public static func logError(_ error: Error, context: String = "") {
        let apiError = fromError(error)
        let errorCode = apiError.errorCode
        let message = apiError.errorDescription ?? "Unknown error"
        
        // Log with error code for debugging
        // Requirements: 7.6
        if context.isEmpty {
            print("[ErrorMapper] \(errorCode): \(message)")
        } else {
            print("[ErrorMapper] [\(context)] \(errorCode): \(message)")
        }
        
        // If the original error has an error_code from backend, log it too
        if let claudeflareError = error as? ClaudeflareError,
           case .networkError(let detail) = claudeflareError,
           detail.contains("(") && detail.contains(")") {
            // Extract error_code from message like "Error message (CHAT_502_001)"
            if let start = detail.lastIndex(of: "("),
               let end = detail.lastIndex(of: ")") {
                let backendErrorCode = String(detail[detail.index(after: start)..<end])
                print("[ErrorMapper] Backend error_code: \(backendErrorCode)")
            }
        }
    }
}

// MARK: - User-Friendly Error Messages

/// 预定义的用户友好错误消息
/// - Requirements: 7.1, 7.2, 7.3, 7.4
public enum UserFriendlyErrorMessage {
    /// 会话已过期 (401)
    /// - Requirements: 7.1
    public static let sessionExpired = "会话已过期，请重新登录"
    
    /// 使用额度已用完 (429)
    /// - Requirements: 7.2
    public static let quotaExceeded = "使用额度已用完，请稍后再试"
    
    /// 服务器错误 (500)
    /// - Requirements: 7.3
    public static let serverError = "服务器错误，请稍后重试"
    
    /// 网络连接失败
    /// - Requirements: 7.4
    public static let networkError = "网络连接失败，请检查网络"
    
    /// 服务暂时不可用 (502, 503)
    public static let serviceUnavailable = "服务暂时不可用，请稍后重试"
    
    /// 请求超时
    public static let requestTimeout = "请求超时，请检查网络后重试"
}
