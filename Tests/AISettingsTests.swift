import Foundation

// MARK: - Unit Tests and Property-Based Testing for AISettings
// **Feature: ai-rich-content-rendering**
// These tests verify the correctness properties of the AI Settings system
// Requirements: 5.1-5.5

/// Test utilities for generating random AI settings
enum AISettingsTestGenerators {
    
    /// Generate a random string of specified length
    static func randomString(length: Int = 20) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate a random API key (simulating real API key format)
    static func randomAPIKey() -> String {
        // Simulate API key format: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        return "sk-\(randomString(length: 32))"
    }
    
    /// Generate a random model selection from available models
    static func randomModel() -> String {
        return AISettings.availableModels.randomElement() ?? "Qwen/QwQ-32B"
    }
    
    /// Generate a random boolean
    static func randomBool() -> Bool {
        return Bool.random()
    }
    
    /// Generate a random AISettings object
    static func randomSettings() -> AISettings {
        return AISettings(
            apiKey: randomAPIKey(),
            showThinkingProcess: randomBool(),
            selectedModel: randomModel()
        )
    }
    
    /// Generate AISettings with empty API key
    static func settingsWithEmptyAPIKey() -> AISettings {
        return AISettings(
            apiKey: "",
            showThinkingProcess: randomBool(),
            selectedModel: randomModel()
        )
    }
    
    /// Generate AISettings with special characters in API key
    static func settingsWithSpecialChars() -> AISettings {
        let specialKey = "sk-\(randomString(length: 16))_\(randomString(length: 8))-test"
        return AISettings(
            apiKey: specialKey,
            showThinkingProcess: randomBool(),
            selectedModel: randomModel()
        )
    }
}


// MARK: - Property Tests for AISettings

/// Property-based tests for AISettings persistence
/// **Feature: ai-rich-content-rendering**
enum AISettingsPropertyTests {
    
    /// **Property 5: Settings persistence round-trip**
    /// **Validates: Requirements 5.4, 5.5**
    /// For any valid AISettings object, saving and then loading should produce
    /// an equivalent object with the same field values.
    static func testSettingsPersistenceRoundTrip(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let repository = AISettingsRepository.shared
        
        for i in 0..<iterations {
            // Generate random settings
            let originalSettings: AISettings
            
            // Mix different types of settings
            switch i % 4 {
            case 0:
                originalSettings = AISettingsTestGenerators.randomSettings()
            case 1:
                originalSettings = AISettingsTestGenerators.settingsWithEmptyAPIKey()
            case 2:
                originalSettings = AISettingsTestGenerators.settingsWithSpecialChars()
            default:
                originalSettings = AISettings() // Default settings
            }
            
            // Save settings
            repository.updateSettings(originalSettings)
            
            // Load settings back
            let loadedSettings = repository.getSettings()
            
            // Verify all fields match
            guard loadedSettings.apiKey == originalSettings.apiKey else {
                return (false, "API key mismatch: expected '\(originalSettings.apiKey)', got '\(loadedSettings.apiKey)'")
            }
            
            guard loadedSettings.showThinkingProcess == originalSettings.showThinkingProcess else {
                return (false, "showThinkingProcess mismatch: expected \(originalSettings.showThinkingProcess), got \(loadedSettings.showThinkingProcess)")
            }
            
            guard loadedSettings.selectedModel == originalSettings.selectedModel else {
                return (false, "selectedModel mismatch: expected '\(originalSettings.selectedModel)', got '\(loadedSettings.selectedModel)'")
            }
            
            // Verify Equatable conformance
            guard loadedSettings == originalSettings else {
                return (false, "Settings not equal after round-trip: \(originalSettings) vs \(loadedSettings)")
            }
        }
        
        return (true, nil)
    }
    
    /// Additional test: Verify API key is stored securely (not in plain UserDefaults)
    static func testAPIKeySecureStorage(iterations: Int = 50) -> (passed: Bool, failingExample: String?) {
        let repository = AISettingsRepository.shared
        
        for _ in 0..<iterations {
            // Generate a unique API key
            let uniqueKey = AISettingsTestGenerators.randomAPIKey()
            
            // Save settings with this key
            let settings = AISettings(
                apiKey: uniqueKey,
                showThinkingProcess: true,
                selectedModel: "Qwen/QwQ-32B"
            )
            repository.updateSettings(settings)
            
            // Verify the key is NOT stored in plain UserDefaults
            // (It should be in Keychain instead)
            let userDefaultsKey = UserDefaults.standard.string(forKey: "ai_api_key")
            if userDefaultsKey == uniqueKey {
                return (false, "API key found in plain UserDefaults - should be in Keychain")
            }
            
            // Verify we can still retrieve the key through the repository
            let loadedSettings = repository.getSettings()
            guard loadedSettings.apiKey == uniqueKey else {
                return (false, "API key not retrievable after secure storage")
            }
        }
        
        return (true, nil)
    }
    
    /// Additional test: Verify default values are correct
    static func testDefaultValues() -> (passed: Bool, failingExample: String?) {
        let defaultSettings = AISettings()
        
        // Verify default API key is empty
        guard defaultSettings.apiKey.isEmpty else {
            return (false, "Default API key should be empty, got: '\(defaultSettings.apiKey)'")
        }
        
        // Verify default thinking mode is true
        guard defaultSettings.showThinkingProcess == true else {
            return (false, "Default showThinkingProcess should be true")
        }
        
        // Verify default model is Qwen/QwQ-32B
        guard defaultSettings.selectedModel == "Qwen/QwQ-32B" else {
            return (false, "Default model should be 'Qwen/QwQ-32B', got: '\(defaultSettings.selectedModel)'")
        }
        
        return (true, nil)
    }
    
    /// Additional test: Verify model selection is from available models
    static func testModelSelectionValidity(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            let randomModel = AISettingsTestGenerators.randomModel()
            
            // Verify the generated model is in the available models list
            guard AISettings.availableModels.contains(randomModel) else {
                return (false, "Generated model '\(randomModel)' not in available models")
            }
        }
        
        return (true, nil)
    }
    
    /// Run all property tests and print results
    static func runAllTests() {
        print("Running AISettings Property Tests...")
        print(String(repeating: "=", count: 50))
        
        // Test 1: Settings Persistence Round-Trip (Property 5)
        let roundTripResult = testSettingsPersistenceRoundTrip()
        if roundTripResult.passed {
            print("✅ Property 5 (Settings Persistence Round-Trip): PASSED")
        } else {
            print("❌ Property 5 (Settings Persistence Round-Trip): FAILED")
            if let failing = roundTripResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 2: API Key Secure Storage
        let secureStorageResult = testAPIKeySecureStorage()
        if secureStorageResult.passed {
            print("✅ Additional (API Key Secure Storage): PASSED")
        } else {
            print("❌ Additional (API Key Secure Storage): FAILED")
            if let failing = secureStorageResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 3: Default Values
        let defaultValuesResult = testDefaultValues()
        if defaultValuesResult.passed {
            print("✅ Additional (Default Values): PASSED")
        } else {
            print("❌ Additional (Default Values): FAILED")
            if let failing = defaultValuesResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 4: Model Selection Validity
        let modelValidityResult = testModelSelectionValidity()
        if modelValidityResult.passed {
            print("✅ Additional (Model Selection Validity): PASSED")
        } else {
            print("❌ Additional (Model Selection Validity): FAILED")
            if let failing = modelValidityResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print(String(repeating: "=", count: 50))
        
        // Summary
        let allPassed = roundTripResult.passed && secureStorageResult.passed && 
                        defaultValuesResult.passed && modelValidityResult.passed
        if allPassed {
            print("All AISettings property tests PASSED ✅")
        } else {
            print("Some AISettings property tests FAILED ❌")
        }
    }
}


// MARK: - Unit Tests for AISettingsRepository

/// Unit tests for AISettingsRepository
/// **Feature: ai-rich-content-rendering**
/// Requirements: 5.1-5.5
enum AISettingsRepositoryUnitTests {
    
    /// Test that repository returns default settings when nothing is saved
    static func testDefaultSettings() -> (passed: Bool, failingExample: String?) {
        // Clear any existing settings by saving empty/default values
        let defaultSettings = AISettings()
        AISettingsRepository.shared.updateSettings(defaultSettings)
        
        let settings = AISettingsRepository.shared.getSettings()
        
        // Verify default values
        guard settings.apiKey.isEmpty else {
            return (false, "Default API key should be empty after reset")
        }
        
        guard settings.showThinkingProcess == true else {
            return (false, "Default showThinkingProcess should be true")
        }
        
        guard settings.selectedModel == "Qwen/QwQ-32B" else {
            return (false, "Default model should be 'Qwen/QwQ-32B'")
        }
        
        return (true, nil)
    }
    
    /// Test save and load operations
    static func testSaveAndLoad() -> (passed: Bool, failingExample: String?) {
        let testSettings = AISettings(
            apiKey: "test-api-key-12345",
            showThinkingProcess: false,
            selectedModel: "deepseek-ai/DeepSeek-V3"
        )
        
        // Save
        AISettingsRepository.shared.updateSettings(testSettings)
        
        // Load
        let loadedSettings = AISettingsRepository.shared.getSettings()
        
        // Verify
        guard loadedSettings.apiKey == testSettings.apiKey else {
            return (false, "API key mismatch after save/load")
        }
        
        guard loadedSettings.showThinkingProcess == testSettings.showThinkingProcess else {
            return (false, "showThinkingProcess mismatch after save/load")
        }
        
        guard loadedSettings.selectedModel == testSettings.selectedModel else {
            return (false, "selectedModel mismatch after save/load")
        }
        
        return (true, nil)
    }
    
    /// Test isAPIKeyConfigured property
    static func testIsAPIKeyConfigured() -> (passed: Bool, failingExample: String?) {
        // Test with empty key
        let emptySettings = AISettings(apiKey: "", showThinkingProcess: true, selectedModel: "Qwen/QwQ-32B")
        AISettingsRepository.shared.updateSettings(emptySettings)
        
        guard !AISettingsRepository.shared.isAPIKeyConfigured else {
            return (false, "isAPIKeyConfigured should be false for empty key")
        }
        
        // Test with valid key
        let validSettings = AISettings(apiKey: "valid-key-123", showThinkingProcess: true, selectedModel: "Qwen/QwQ-32B")
        AISettingsRepository.shared.updateSettings(validSettings)
        
        guard AISettingsRepository.shared.isAPIKeyConfigured else {
            return (false, "isAPIKeyConfigured should be true for valid key")
        }
        
        return (true, nil)
    }
    
    /// Run all unit tests
    static func runAllTests() {
        print("Running AISettingsRepository Unit Tests...")
        print(String(repeating: "-", count: 50))
        
        let defaultResult = testDefaultSettings()
        if defaultResult.passed {
            print("✅ Default Settings: PASSED")
        } else {
            print("❌ Default Settings: FAILED - \(defaultResult.failingExample ?? "")")
        }
        
        let saveLoadResult = testSaveAndLoad()
        if saveLoadResult.passed {
            print("✅ Save and Load: PASSED")
        } else {
            print("❌ Save and Load: FAILED - \(saveLoadResult.failingExample ?? "")")
        }
        
        let configuredResult = testIsAPIKeyConfigured()
        if configuredResult.passed {
            print("✅ isAPIKeyConfigured: PASSED")
        } else {
            print("❌ isAPIKeyConfigured: FAILED - \(configuredResult.failingExample ?? "")")
        }
        
        print(String(repeating: "-", count: 50))
    }
}


// MARK: - Unit Tests for AISettingsViewModel

/// Unit tests for AISettingsViewModel
/// **Feature: ai-rich-content-rendering**
/// Requirements: 5.3-5.5
enum AISettingsViewModelUnitTests {
    
    /// Test that ViewModel loads settings on init
    static func testLoadSettingsOnInit() -> (passed: Bool, failingExample: String?) {
        // Set up known settings
        let testSettings = AISettings(
            apiKey: "init-test-key",
            showThinkingProcess: false,
            selectedModel: "deepseek-ai/DeepSeek-R1"
        )
        AISettingsRepository.shared.updateSettings(testSettings)
        
        // Create ViewModel
        let vm = AISettingsViewModel()
        
        // Verify settings are loaded
        guard vm.apiKey == testSettings.apiKey else {
            return (false, "ViewModel should load API key on init")
        }
        
        guard vm.showThinkingProcess == testSettings.showThinkingProcess else {
            return (false, "ViewModel should load showThinkingProcess on init")
        }
        
        guard vm.selectedModel == testSettings.selectedModel else {
            return (false, "ViewModel should load selectedModel on init")
        }
        
        return (true, nil)
    }
    
    /// Test API key validation
    static func testAPIKeyValidation() -> (passed: Bool, failingExample: String?) {
        let vm = AISettingsViewModel()
        
        // Test empty key
        vm.apiKey = ""
        guard !vm.isAPIKeyValid else {
            return (false, "Empty API key should be invalid")
        }
        
        // Test whitespace-only key
        vm.apiKey = "   "
        guard !vm.isAPIKeyValid else {
            return (false, "Whitespace-only API key should be invalid")
        }
        
        // Test valid key
        vm.apiKey = "valid-api-key-123"
        guard vm.isAPIKeyValid else {
            return (false, "Non-empty API key should be valid")
        }
        
        return (true, nil)
    }
    
    /// Test available models list
    static func testAvailableModels() -> (passed: Bool, failingExample: String?) {
        let vm = AISettingsViewModel()
        
        guard !vm.availableModels.isEmpty else {
            return (false, "Available models should not be empty")
        }
        
        guard vm.availableModels.contains("Qwen/QwQ-32B") else {
            return (false, "Available models should contain default model")
        }
        
        return (true, nil)
    }
    
    /// Test saveSettings method
    static func testSaveSettings() -> (passed: Bool, failingExample: String?) {
        let vm = AISettingsViewModel()
        
        // Set new values
        vm.apiKey = "save-test-key-456"
        vm.showThinkingProcess = true
        vm.selectedModel = "deepseek-ai/DeepSeek-V3"
        
        // Save
        vm.saveSettings()
        
        // Verify saved to repository
        let savedSettings = AISettingsRepository.shared.getSettings()
        
        guard savedSettings.apiKey == vm.apiKey else {
            return (false, "API key should be saved to repository")
        }
        
        guard savedSettings.showThinkingProcess == vm.showThinkingProcess else {
            return (false, "showThinkingProcess should be saved to repository")
        }
        
        guard savedSettings.selectedModel == vm.selectedModel else {
            return (false, "selectedModel should be saved to repository")
        }
        
        return (true, nil)
    }
    
    /// Test resetToDefaults method
    static func testResetToDefaults() -> (passed: Bool, failingExample: String?) {
        let vm = AISettingsViewModel()
        
        // Set non-default values
        vm.apiKey = "some-key"
        vm.showThinkingProcess = false
        vm.selectedModel = "deepseek-ai/DeepSeek-V3"
        
        // Reset
        vm.resetToDefaults()
        
        // Verify defaults
        guard vm.apiKey.isEmpty else {
            return (false, "API key should be empty after reset")
        }
        
        guard vm.showThinkingProcess == true else {
            return (false, "showThinkingProcess should be true after reset")
        }
        
        guard vm.selectedModel == "Qwen/QwQ-32B" else {
            return (false, "selectedModel should be default after reset")
        }
        
        return (true, nil)
    }
    
    /// Run all unit tests
    static func runAllTests() {
        print("Running AISettingsViewModel Unit Tests...")
        print(String(repeating: "-", count: 50))
        
        let initResult = testLoadSettingsOnInit()
        if initResult.passed {
            print("✅ Load Settings on Init: PASSED")
        } else {
            print("❌ Load Settings on Init: FAILED - \(initResult.failingExample ?? "")")
        }
        
        let validationResult = testAPIKeyValidation()
        if validationResult.passed {
            print("✅ API Key Validation: PASSED")
        } else {
            print("❌ API Key Validation: FAILED - \(validationResult.failingExample ?? "")")
        }
        
        let modelsResult = testAvailableModels()
        if modelsResult.passed {
            print("✅ Available Models: PASSED")
        } else {
            print("❌ Available Models: FAILED - \(modelsResult.failingExample ?? "")")
        }
        
        let saveResult = testSaveSettings()
        if saveResult.passed {
            print("✅ Save Settings: PASSED")
        } else {
            print("❌ Save Settings: FAILED - \(saveResult.failingExample ?? "")")
        }
        
        let resetResult = testResetToDefaults()
        if resetResult.passed {
            print("✅ Reset to Defaults: PASSED")
        } else {
            print("❌ Reset to Defaults: FAILED - \(resetResult.failingExample ?? "")")
        }
        
        print(String(repeating: "-", count: 50))
    }
}


// MARK: - Run All AI Settings Tests

/// Run all AI Settings tests (property-based and unit tests)
public func runAllAISettingsTests() {
    print("\n" + String(repeating: "=", count: 60))
    print("AI SETTINGS TEST SUITE")
    print(String(repeating: "=", count: 60) + "\n")
    
    // Property-based tests
    AISettingsPropertyTests.runAllTests()
    print("")
    
    // Repository unit tests
    AISettingsRepositoryUnitTests.runAllTests()
    print("")
    
    // ViewModel unit tests
    AISettingsViewModelUnitTests.runAllTests()
    
    print("\n" + String(repeating: "=", count: 60))
    print("AI SETTINGS TEST SUITE COMPLETE")
    print(String(repeating: "=", count: 60) + "\n")
}
