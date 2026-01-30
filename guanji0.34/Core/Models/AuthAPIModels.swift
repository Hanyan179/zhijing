//
//  AuthAPIModels.swift
//  guanji0.34
//
//  Auth API 数据模型
//  定义与后端 API 通信的请求和响应模型
//  - Requirements: 1.1, 1.2, 2.1, 3.1, 3.4
//

import Foundation

// MARK: - API Response Models

/// 通用 API 响应
/// 后端 API 统一响应格式
/// - Requirements: 1.1, 1.2, 2.1, 3.1
public struct APIResponse<T: Codable>: Codable {
    /// 请求是否成功
    public let success: Bool
    /// 响应消息
    public let message: String
    /// 响应数据（可选）
    public let data: T?
    
    public init(success: Bool, message: String, data: T? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

/// 用户数据模型
/// 包含用户 ID、用户名、显示名称、角色、状态、分组等信息
/// - Requirements: 1.2, 2.2
public struct UserData: Codable, Equatable {
    /// 用户 ID
    public let id: Int?
    /// 用户名
    public let username: String?
    /// 显示名称
    public let displayName: String?
    /// 用户角色
    public let role: Int?
    /// 用户状态
    public let status: Int?
    /// 用户分组
    public let group: String?
    /// 是否需要 2FA 验证
    public let require2FA: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case role
        case status
        case group
        case require2FA = "require_2fa"
    }
    
    public init(
        id: Int? = nil,
        username: String? = nil,
        displayName: String? = nil,
        role: Int? = nil,
        status: Int? = nil,
        group: String? = nil,
        require2FA: Bool? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.role = role
        self.status = status
        self.group = group
        self.require2FA = require2FA
    }
}

/// 登录结果 (Legacy - kept for compatibility)
/// 表示登录操作的结果
/// - Requirements: 1.2, 1.3
public enum LoginResult: Equatable {
    /// 登录成功，返回用户数据
    case success(UserData)
}

// MARK: - Empty Response

/// 空响应数据
/// 用于不返回数据的 API 响应
public struct EmptyData: Codable, Equatable {
    public init() {}
}

// MARK: - Cognito OAuth Models

/// Token 响应 (Cognito OAuth)
/// - Requirements: 1.3, 1.4
public struct TokenResponse: Codable, Equatable {
    /// Access Token
    public let accessToken: String
    /// ID Token (用于 API 认证)
    public let idToken: String
    /// Refresh Token (用于刷新)
    public let refreshToken: String
    /// Token 过期时间（秒）
    public let expiresIn: Int
    /// Token 类型
    public let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
    
    public init(
        accessToken: String,
        idToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String
    ) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}

/// 用户信息 (Cognito OAuth)
/// - Requirements: 2.2
public struct CognitoUserInfo: Codable, Equatable {
    /// 用户 ID
    public let id: String
    /// 邮箱
    public let email: String
    /// 用户名（可选）
    public let name: String?
    /// 头像 URL（可选）
    public let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case avatarUrl = "avatar_url"
    }
    
    public init(
        id: String,
        email: String,
        name: String? = nil,
        avatarUrl: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
    }
}

/// Token 交换请求 (Cognito OAuth)
/// - Requirements: 1.3
public struct TokenExchangeRequest: Codable {
    /// 授权码
    public let code: String
    /// 重定向 URI
    public let redirectUri: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case redirectUri = "redirect_uri"
    }
    
    public init(code: String, redirectUri: String) {
        self.code = code
        self.redirectUri = redirectUri
    }
}

/// Token 刷新请求 (Cognito OAuth)
/// - Requirements: 2.3
public struct TokenRefreshRequest: Codable {
    /// Refresh Token
    public let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
