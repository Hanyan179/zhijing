import Foundation

// MARK: - AI Service Error Types

/// AI Service error types
/// Used for error handling in AI conversation features
public enum AIServiceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError(Error)
    case streamingError(String)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
