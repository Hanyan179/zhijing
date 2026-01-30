//
//  EmailValidator.swift
//  guanji0.34
//
//  邮箱格式验证工具
//  - Requirements: 2.3
//

import Foundation

/// 邮箱格式验证工具
/// 使用正则表达式验证邮箱格式
/// - Requirements: 2.3
public enum EmailValidator {
    
    /// 邮箱验证正则表达式
    /// 匹配标准邮箱格式: local@domain.tld
    /// - 不允许以点开头或结尾
    /// - 不允许连续的点
    private static let emailRegex = #"^[A-Za-z0-9]([A-Za-z0-9._%+-]*[A-Za-z0-9])?@[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?\.[A-Za-z]{2,}$"#
    
    /// 验证邮箱格式是否有效
    /// - Parameter email: 邮箱地址
    /// - Returns: 是否有效
    /// - Requirements: 2.3
    public static func isValid(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        // Also reject emails with consecutive dots
        if email.contains("..") { return false }
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
