import Foundation

// MARK: - Token Manager (Deprecated)

/// Token manager - DEPRECATED
/// Authentication is now handled via cookies by AuthService
/// This class is kept for backward compatibility but does nothing
@available(*, deprecated, message: "Use AuthService for cookie-based authentication")
public final class TokenManager {
    
    // MARK: - Singleton
    
    public static let shared = TokenManager()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API (No-op)
    
    /// Get token - always returns nil (use cookies instead)
    public func getToken() -> String? {
        return nil
    }
    
    /// Set API key - no-op (use AuthService login instead)
    public func setApiKey(_ apiKey: String) {
        // No-op - authentication is cookie-based
    }
    
    /// Alias for setApiKey
    public func setTestToken(_ token: String) {
        // No-op
    }
    
    /// Check if token is valid - always false (use AuthService.isAuthenticated)
    public var isTokenValid: Bool {
        return AuthService.shared.isAuthenticated
    }
    
    /// Clear token - no-op
    public func clearToken() {
        // No-op
    }
    
    // MARK: - Testing Support
    
    internal func reset() {
        // No-op
    }
}
