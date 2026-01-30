import Foundation
import Combine

/// ViewModel for AI Settings screen
/// Now uses model tiers (fast, balanced, powerful) instead of individual models
public final class AISettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var showThinkingProcess: Bool = true
    @Published public var selectedModelTier: ModelTier = .balanced
    @Published public var isSaving: Bool = false
    
    // MARK: - Computed Properties
    
    /// Available model tiers for selection
    public var availableModelTiers: [ModelTier] {
        [.fast, .balanced, .powerful]
    }
    
    // MARK: - Private Properties
    
    private let repository = AISettingsRepository.shared
    
    // MARK: - Initialization
    
    public init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Load settings from repository
    public func loadSettings() {
        let settings = repository.getSettings()
        showThinkingProcess = settings.showThinkingProcess
        
        // Map legacy model to tier
        selectedModelTier = .balanced
    }
    
    /// Save settings to repository
    public func saveSettings() {
        isSaving = true
        
        let settings = AISettings(
            showThinkingProcess: showThinkingProcess,
            selectedModel: selectedModelTier.rawValue
        )
        
        repository.updateSettings(settings)
        
        isSaving = false
    }
    
    /// Reset to default settings
    public func resetToDefaults() {
        showThinkingProcess = true
        selectedModelTier = .balanced
    }
}
