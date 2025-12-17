import Foundation
import Combine

/// ViewModel for AI Settings screen
/// Requirements: 5.3-5.5
public final class AISettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var apiKey: String = ""
    @Published public var showThinkingProcess: Bool = true
    @Published public var selectedModel: String = "Qwen/QwQ-32B"
    @Published public var apiKeyError: String? = nil
    @Published public var isSaving: Bool = false
    
    // MARK: - Computed Properties
    
    /// Available AI models for selection
    public var availableModels: [String] {
        AISettings.availableModels
    }
    
    /// Check if API key is valid (non-empty after trimming)
    public var isAPIKeyValid: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Check if API key is configured
    public var isAPIKeyConfigured: Bool {
        AISettingsRepository.shared.isAPIKeyConfigured
    }
    
    // MARK: - Private Properties
    
    private let repository = AISettingsRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        loadSettings()
        setupValidation()
    }
    
    // MARK: - Public Methods
    
    /// Load settings from repository
    public func loadSettings() {
        let settings = repository.getSettings()
        apiKey = settings.apiKey
        showThinkingProcess = settings.showThinkingProcess
        selectedModel = settings.selectedModel
        apiKeyError = nil
    }
    
    /// Save settings to repository
    /// Requirements: 5.4, 5.5
    public func saveSettings() {
        // Validate API key if provided
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedKey.isEmpty && !validateAPIKeyFormat(trimmedKey) {
            apiKeyError = Localization.tr("AI.Error.InvalidAPIKey")
            return
        }
        
        isSaving = true
        apiKeyError = nil
        
        let settings = AISettings(
            apiKey: trimmedKey,
            showThinkingProcess: showThinkingProcess,
            selectedModel: selectedModel
        )
        
        repository.updateSettings(settings)
        
        // Update AIService with new API key
        AIService.shared.setAPIKey(trimmedKey)
        
        isSaving = false
    }
    
    /// Clear API key
    public func clearAPIKey() {
        apiKey = ""
        apiKeyError = nil
    }
    
    /// Reset to default settings
    public func resetToDefaults() {
        let defaults = AISettings()
        apiKey = defaults.apiKey
        showThinkingProcess = defaults.showThinkingProcess
        selectedModel = defaults.selectedModel
        apiKeyError = nil
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Clear error when user starts typing
        $apiKey
            .dropFirst()
            .sink { [weak self] _ in
                self?.apiKeyError = nil
            }
            .store(in: &cancellables)
    }
    
    /// Validate API key format
    /// Basic validation - checks for reasonable format
    private func validateAPIKeyFormat(_ key: String) -> Bool {
        // API key should be at least 10 characters
        guard key.count >= 10 else { return false }
        
        // API key should only contain alphanumeric characters, hyphens, and underscores
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard key.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return false
        }
        
        return true
    }
}
