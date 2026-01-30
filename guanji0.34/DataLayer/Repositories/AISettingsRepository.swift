import Foundation

/// Repository for managing AI settings
/// Handles persistence with UserDefaults
/// Uses cookie-based authentication with new-api
public final class AISettingsRepository {
    public static let shared = AISettingsRepository()
    
    // MARK: - Keys
    
    private let showThinkingKey = "ai_show_thinking_process"
    private let selectedModelKey = "ai_selected_model"
    
    // MARK: - Cached Settings
    
    private var cachedSettings: AISettings?
    
    private init() {
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
    public func updateSettings(_ newSettings: AISettings) {
        UserDefaults.standard.set(newSettings.showThinkingProcess, forKey: showThinkingKey)
        UserDefaults.standard.set(newSettings.selectedModel, forKey: selectedModelKey)
        cachedSettings = newSettings
    }
    
    /// Check if AI is configured (user is authenticated)
    public var isAPIKeyConfigured: Bool {
        AuthService.shared.isAuthenticated
    }
    
    // MARK: - Private Helpers
    
    private func loadSettingsFromStorage() -> AISettings {
        let showThinking = UserDefaults.standard.object(forKey: showThinkingKey) as? Bool ?? true
        let selectedModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? "gemini-2.5-flash"
        
        return AISettings(
            showThinkingProcess: showThinking,
            selectedModel: selectedModel
        )
    }
}
