//
//  KeychainService.swift
//  guanji0.34
//
//  Keychain 存储服务 - 标准 iOS Keychain 实现
//

import Foundation
import Security

/// Keychain 存储服务
/// 使用最简单的标准 iOS Keychain API
public final class KeychainService {
    
    public static let shared = KeychainService()
    
    private let service: String
    
    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "hansen.guanji0-34"
    }
    
    // MARK: - Public API
    
    /// 保存字符串
    public func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, forKey: key)
    }
    
    /// 保存 Data
    public func set(_ data: Data, forKey key: String) -> Bool {
        // 先删除已存在的项
        delete(key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 保存 Bool
    public func set(_ value: Bool, forKey key: String) -> Bool {
        return set(value ? "1" : "0", forKey: key)
    }
    
    /// 获取字符串
    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 获取 Data
    public func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    /// 获取 Bool
    public func bool(forKey key: String) -> Bool {
        return string(forKey: key) == "1"
    }
    
    /// 删除指定 key
    @discardableResult
    public func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// 清除所有存储的数据
    public func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
