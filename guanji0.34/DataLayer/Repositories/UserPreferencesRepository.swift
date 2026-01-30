import Foundation

/// Repository for managing user preferences
/// Handles default mode settings
/// Requirements: 5.2
public final class UserPreferencesRepository {
    public static let shared = UserPreferencesRepository()
    
    // MARK: - Keys
    
    private let defaultModeKey = "user_default_mode"
    private let thinkingModeKey = "user_thinking_mode_enabled"
    private let lastConversationIdKey = "user_last_conversation_id"
    private let lastConversationDateKey = "user_last_conversation_date"
    
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
    
    /// Whether thinking mode is enabled for AI conversations
    public var thinkingModeEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: thinkingModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: thinkingModeKey)
        }
    }
    
    // MARK: - Last Conversation State
    
    /// Last active conversation ID (persisted across app launches)
    public var lastConversationId: String? {
        get {
            UserDefaults.standard.string(forKey: lastConversationIdKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastConversationIdKey)
        }
    }
    
    /// Date when last conversation was active (for new day detection)
    public var lastConversationDate: String? {
        get {
            UserDefaults.standard.string(forKey: lastConversationDateKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastConversationDateKey)
        }
    }
    
    /// Save current conversation state
    /// - Parameter conversationId: The conversation ID to save
    public func saveLastConversation(id: String?) {
        lastConversationId = id
        lastConversationDate = DateUtilities.today
    }
    
    /// Load last conversation ID if it's still valid (same day)
    /// Returns nil if it's a new day, triggering new conversation creation
    public func loadLastConversationIfSameDay() -> String? {
        guard let savedDate = lastConversationDate,
              savedDate == DateUtilities.today,
              let savedId = lastConversationId else {
            return nil
        }
        return savedId
    }
}
