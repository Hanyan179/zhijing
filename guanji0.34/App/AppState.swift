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
    
    // MARK: - Robot Avatar State
    /// 机器人心情值 (0-100)，根据用户最近的 DailyTracker 记录动态变化
    @Published public var robotMindValence: Int = 50
    /// 机器人能量值 (0-100)，根据用户最近的 DailyTracker 记录动态变化
    @Published public var robotBodyEnergy: Int = 50
    
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
    
    /// AI 对话是否处于折叠状态（显示摘要卡片）
    /// - Requirements: 4.5, 4.6, 4.8
    @Published public var aiConversationCollapsed: Bool = true
    
    public init() {
        // Load default mode preference on app launch - Requirements 5.3, 5.5
        currentMode = UserPreferencesRepository.shared.loadDefaultMode()
        thinkingModeEnabled = UserPreferencesRepository.shared.thinkingModeEnabled
        
        // Load last conversation ID if same day (for session continuity)
        currentConversationId = UserPreferencesRepository.shared.loadLastConversationIfSameDay()
        
        // Load robot state from latest DailyTracker record
        loadRobotState()
        
        // Note: Background timeline recording removed for battery efficiency
        // Location is now only captured when user submits input
        print("[AppState] App initialized - lastConversationId: \(currentConversationId ?? "nil")")
    }
    
    // MARK: - Robot State Management
    
    /// 从最近的 DailyTracker 记录加载机器人状态
    public func loadRobotState() {
        // 强制重新加载以确保获取最新数据
        DailyTrackerRepository.shared.reload()
        
        if let latestRecord = DailyTrackerRepository.shared.loadLatest() {
            robotMindValence = latestRecord.moodWeather
            robotBodyEnergy = latestRecord.bodyEnergy
            print("[AppState] Robot state loaded - mind: \(robotMindValence), energy: \(robotBodyEnergy)")
        } else {
            print("[AppState] No DailyTracker record found, using defaults")
        }
    }
    
    /// 更新机器人状态（当用户提交新的 DailyTracker 记录时调用）
    public func updateRobotState(mindValence: Int, bodyEnergy: Int) {
        robotMindValence = mindValence
        robotBodyEnergy = bodyEnergy
        print("[AppState] Robot state updated - mind: \(mindValence), energy: \(bodyEnergy)")
    }
    
    /// Set current conversation ID and persist it
    public func setCurrentConversation(id: String?) {
        currentConversationId = id
        UserPreferencesRepository.shared.saveLastConversation(id: id)
    }
    
    // MARK: - AI Conversation Collapse/Expand
    
    /// 展开 AI 对话到全屏
    /// - Requirements: 4.5, 4.6
    public func expandAIConversation() {
        aiConversationCollapsed = false
        currentMode = .ai
    }
    
    /// 折叠 AI 对话为摘要卡片
    /// - Requirements: 4.5, 4.6, 4.8
    public func collapseAIConversation() {
        aiConversationCollapsed = true
        currentMode = .journal
    }
}
