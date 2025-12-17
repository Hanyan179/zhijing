import SwiftUI
import Combine

public final class AppState: ObservableObject {
    @Published public var selectedDate: String = DateUtilities.today
    @Published public var focusEntryId: String? = nil
    @Published public var lang: Lang = Localization.current
    @Published public var showMindState: Bool = false
    @Published public var showCapsuleCreator: Bool = false
    @Published public var showPlaceNaming: Bool = false
    @Published public var pendingLocation: LocationVO? = nil
    @Published public var resolvedLocation: LocationVO? = nil
    @Published public var showLocationPermission: Bool = false
    @Published public var locationAuthStatus: LocationAuthStatus = .notDetermined
    @Published public var homeValence: MindValence? = nil
    @Published public var editingEntryId: String? = nil
    @Published public var editingDraft: String = ""
    
    // Capsule Creator Draft State
    @Published public var capsuleDraftPrompt: String = ""
    @Published public var capsuleDraftDate: Date = Date().addingTimeInterval(24*60*60)
    @Published public var capsuleDraftSealed: Bool = true
    @Published public var capsuleDraftSystemQuestion: String = ""
    @Published public var capsuleDraftShowSystemQuestion: Bool = false
    
    @Published public var hasAutoExpandedInput: Bool = false
    
    // MARK: - AI Mode State
    
    /// Current application mode (journal or ai)
    @Published public var currentMode: AppMode = .journal
    
    /// Currently active AI conversation ID
    @Published public var currentConversationId: String? = nil
    
    /// Whether AI is currently streaming a response
    @Published public var isAIStreaming: Bool = false
    
    /// Whether thinking mode is enabled for AI responses
    @Published public var thinkingModeEnabled: Bool = false
    
    public init() {
        // Load default mode preference on app launch - Requirements 5.3, 5.5
        currentMode = UserPreferencesRepository.shared.loadDefaultMode()
        thinkingModeEnabled = UserPreferencesRepository.shared.thinkingModeEnabled
    }
}
