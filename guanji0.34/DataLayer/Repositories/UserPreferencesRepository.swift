import Foundation

/// Repository for managing user preferences
/// Handles default mode and thinking mode settings
/// Requirements: 5.2, 10.5
public final class UserPreferencesRepository {
    public static let shared = UserPreferencesRepository()
    
    // MARK: - Keys
    
    private let defaultModeKey = "user_default_mode"
    private let thinkingModeKey = "ai_thinking_mode_enabled"
    private let apiKeyKey = "siliconflow_api_key"
    
    private init() {}
    
    // MARK: - Default Mode
    
    /// Default app mode (journal or ai)
    /// Requirements: 5.2, 5.3
    public var defaultMode: AppMode {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: defaultModeKey),
                  let mode = AppMode(rawValue: rawValue) else {
                return .journal  // Default to journal mode - Requirement 5.4
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultModeKey)
        }
    }
    
    /// Load default mode (alias for defaultMode getter)
    /// Requirements: 5.3
    public func loadDefaultMode() -> AppMode {
        return defaultMode
    }
    
    // MARK: - Thinking Mode
    
    /// Whether AI thinking mode is enabled
    /// Requirement: 10.5
    public var thinkingModeEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: thinkingModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: thinkingModeKey)
        }
    }
    
    // MARK: - API Key
    
    /// SiliconFlow API key
    public var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyKey)
        }
    }
    
    /// Check if API key is configured
    public var isAPIKeyConfigured: Bool {
        !apiKey.isEmpty
    }
}
