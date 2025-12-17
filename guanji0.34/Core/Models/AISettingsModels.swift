import Foundation
import Security

// MARK: - AI Settings Model

/// Settings for AI conversation features
/// Requirements: 5.4, 5.5
public struct AISettings: Codable, Equatable {
    public var apiKey: String
    public var showThinkingProcess: Bool
    public var selectedModel: String
    
    public init(
        apiKey: String = "",
        showThinkingProcess: Bool = true,
        selectedModel: String = "Qwen/QwQ-32B"
    ) {
        self.apiKey = apiKey
        self.showThinkingProcess = showThinkingProcess
        self.selectedModel = selectedModel
    }
    
    /// Available AI models
    public static let availableModels: [String] = [
        "Qwen/QwQ-32B",
        "deepseek-ai/DeepSeek-V3",
        "deepseek-ai/DeepSeek-R1"
    ]
}

// MARK: - Keychain Helper

/// Helper for secure API key storage in Keychain
/// Requirements: 5.4
private struct KeychainHelper {
    static let service = "hansen.guanji0-34.ai-settings"
    static let apiKeyAccount = "api-key"
    
    /// Save API key to Keychain
    static func saveAPIKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Load API key from Keychain
    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Delete API key from Keychain
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
