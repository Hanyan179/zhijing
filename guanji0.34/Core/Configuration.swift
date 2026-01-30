//
//  Configuration.swift
//  guanji0.34
//
//  应用配置文件
//

import Foundation

/// 应用配置
/// 存储应用所需的配置信息
enum Configuration {
    
    // MARK: - API Configuration
    
    /// new-api 服务地址 (Legacy)
    static let apiBaseURL = "https://api.jiangzefang.store"
    
    /// jing-backend 服务地址 (Cognito OAuth)
    /// - Requirements: 1.1, 1.2
    static let jingBackendURL = "https://api.jingever.com"
    
    // MARK: - Validation
    
    /// 检查配置是否有效
    static var isConfigured: Bool {
        return !apiBaseURL.isEmpty && !jingBackendURL.isEmpty
    }
}
