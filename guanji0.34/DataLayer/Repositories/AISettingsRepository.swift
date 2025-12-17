import Foundation
import Security

/// Repository for managing AI settings
/// Handles persistence with UserDefaults and Keychain for API key
/// Requirements: 5.4, 5.5
public final class AISettingsRepository {
    public static let shared = AISettingsRepository()
    
    // MARK: - Keys
    
    private let showThinkingKey = "ai_show_thinking_process"
    private let selectedModelKey = "ai_selected_model"
    private let keychainService = "hansen.guanji0-34.ai-settings"
    private let apiKeyAccount = "api-key"
    
    // MARK: - Cached Settings
    
    private var cachedSettings: AISettings?
    
    private init() {
        // Load settings on init
        cachedSettings = loadSettingsFromStorage()
    }
    
    // MARK: - Public API
    
    /// Get current AI settings
    public func getSettings() -> AISettings {
        if let cached = cachedSettings {
            return cached
        }
        let settings = loadSettingsFromStorage()
        cachedSettings = settings
        return settings
    }
    
    /// Update AI settings
    /// Requirements: 5.4, 5.5
    public func updateSettings(_ newSettings: AISettings) {
        // Save API key to Keychain
        _ = saveAPIKeyToKeychain(newSettings.apiKey)
        
        // Save other settings to UserDefaults
        UserDefaults.standard.set(newSettings.showThinkingProcess, forKey: showThinkingKey)
        UserDefaults.standard.set(newSettings.selectedModel, forKey: selectedModelKey)
        
        // Update cache
        cachedSettings = newSettings
        
        // Sync with AIService
        AIService.shared.setAPIKey(newSettings.apiKey)
        
        // Sync with legacy UserPreferencesRepository for backward compatibility
        UserPreferencesRepository.shared.thinkingModeEnabled = newSettings.showThinkingProcess
    }
    
    /// Check if API key is configured
    public var isAPIKeyConfigured: Bool {
        let key = loadAPIKeyFromKeychain()
        return key != nil && !key!.isEmpty
    }
    
    /// Get API key (for AIService)
    public func getAPIKey() -> String {
        return loadAPIKeyFromKeychain() ?? ""
    }
    
    // MARK: - Private Helpers
    
    private func loadSettingsFromStorage() -> AISettings {
        let apiKey = loadAPIKeyFromKeychain() ?? ""
        let showThinking = UserDefaults.standard.object(forKey: showThinkingKey) as? Bool ?? true
        let selectedModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? "Qwen/QwQ-32B"
        
        return AISettings(
            apiKey: apiKey,
            showThinkingProcess: showThinking,
            selectedModel: selectedModel
        )
    }
    
    // MARK: - Keychain Operations
    
    private func saveAPIKeyToKeychain(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // If key is empty, just delete
        if key.isEmpty {
            return true
        }
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            // Fall back to UserDefaults for migration
            return UserDefaults.standard.string(forKey: "siliconflow_api_key")
        }
        
        return key
    }
}
