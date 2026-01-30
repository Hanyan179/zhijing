import Foundation

// MARK: - AI Settings Model

/// Settings for AI conversation features
/// Uses cookie-based authentication with new-api
public struct AISettings: Codable, Equatable {
    public var showThinkingProcess: Bool
    public var selectedModel: String
    
    public init(
        showThinkingProcess: Bool = true,
        selectedModel: String = "gemini-2.5-flash"
    ) {
        self.showThinkingProcess = showThinkingProcess
        self.selectedModel = selectedModel
    }
    
    /// Available AI models - fetched from server dynamically
    public static let availableModels: [String] = []
    
    /// Get display name for a model
    public static func displayName(for modelId: String) -> String {
        return modelId
    }
    
    /// Check if model supports thinking mode
    /// Models with "thinking", "qwq", or "deepseek-r1" in name support thinking
    public static func supportsThinking(_ modelId: String) -> Bool {
        let lowercased = modelId.lowercased()
        return lowercased.contains("thinking") ||
               lowercased.contains("qwq") ||
               lowercased.contains("deepseek-r1")
    }
}
