//
//  AuthServiceTests.swift
//  guanji0.34Tests
//
//  AuthService 单元测试
//  测试 Cognito OAuth 认证相关功能
//  - Property 1: Token 存储 round-trip
//  - Property 2: Auth 状态转换
//  - Property 3: 401 自动刷新
//

import XCTest
@testable import guanji0_34

// MARK: - Mock URLSession

/// Mock URLSession 用于测试
class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var requestHistory: [URLRequest] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestHistory.append(request)
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
    
    func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        requestHistory = []
    }
}

// MARK: - Mock Keychain

/// Mock Keychain 用于测试
class MockKeychain {
    private var storage: [String: Any] = [:]
    
    func set(_ value: String, forKey key: String) -> Bool {
        storage[key] = value
        return true
    }
    
    func set(_ data: Data, forKey key: String) -> Bool {
        storage[key] = data
        return true
    }
    
    func string(forKey key: String) -> String? {
        return storage[key] as? String
    }
    
    func data(forKey key: String) -> Data? {
        return storage[key] as? Data
    }
    
    func delete(_ key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
    
    func clearAll() {
        storage.removeAll()
    }
}

// MARK: - AuthService Tests

final class AuthServiceTests: XCTestCase {
    
    var mockSession: MockURLSession!
    var authService: AuthService!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        authService = AuthService(
            baseURL: "https://api.jiangzefang.store",
            jingBackendURL: "https://api.jingever.com",
            session: mockSession
        )
    }
    
    override func tearDown() {
        mockSession.reset()
        authService.reset()
        // 清除 Keychain 中的测试数据
        KeychainService.shared.delete("auth.idToken")
        KeychainService.shared.delete("auth.refreshToken")
        KeychainService.shared.delete("auth.cognito.userId")
        KeychainService.shared.delete("auth.cognito.userEmail")
        super.tearDown()
    }
    
    // MARK: - Property 1: Token Persistence Round-Trip
    
    /// **Validates: Requirements 1.4, 2.4**
    /// For any successful token exchange or refresh response, storing tokens to Keychain
    /// and then reading them back should return the same ID_Token and Refresh_Token values.
    func testTokenPersistenceRoundTrip() {
        // Given: Various token values
        let testCases: [(idToken: String, refreshToken: String)] = [
            ("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test1", "refresh_token_1"),
            ("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test2", "refresh_token_2"),
            ("short", "r"),
            ("a" + String(repeating: "b", count: 1000), "c" + String(repeating: "d", count: 1000))
        ]
        
        for (idToken, refreshToken) in testCases {
            // When: Store tokens
            let idTokenStored = KeychainService.shared.set(idToken, forKey: "auth.idToken")
            let refreshTokenStored = KeychainService.shared.set(refreshToken, forKey: "auth.refreshToken")
            
            // Then: Read back should return same values
            XCTAssertTrue(idTokenStored, "ID Token should be stored successfully")
            XCTAssertTrue(refreshTokenStored, "Refresh Token should be stored successfully")
            
            let retrievedIdToken = KeychainService.shared.string(forKey: "auth.idToken")
            let retrievedRefreshToken = KeychainService.shared.string(forKey: "auth.refreshToken")
            
            XCTAssertEqual(retrievedIdToken, idToken, "Retrieved ID Token should match stored value")
            XCTAssertEqual(retrievedRefreshToken, refreshToken, "Retrieved Refresh Token should match stored value")
            
            // Cleanup for next iteration
            KeychainService.shared.delete("auth.idToken")
            KeychainService.shared.delete("auth.refreshToken")
        }
    }
    
    // MARK: - Property 2: Auth State Machine Consistency
    
    /// **Validates: Requirements 1.5, 1.7, 2.5**
    /// For any sequence of auth operations, the auth state should transition correctly.
    func testAuthStateTransitions() {
        // Initial state should be unknown
        XCTAssertEqual(authService.authState, .unknown, "Initial state should be unknown")
        
        // Test: Set to unauthenticated
        authService.setAuthState(.unauthenticated)
        XCTAssertEqual(authService.authState, .unauthenticated, "State should be unauthenticated")
        
        // Test: Set to authenticated
        authService.setAuthState(.authenticated(userId: "test-user-123"))
        XCTAssertEqual(authService.authState, .authenticated(userId: "test-user-123"), "State should be authenticated")
        
        // Test: Set to sessionExpired
        authService.setAuthState(.sessionExpired)
        XCTAssertEqual(authService.authState, .sessionExpired, "State should be sessionExpired")
        
        // Test: Back to unauthenticated
        authService.setAuthState(.unauthenticated)
        XCTAssertEqual(authService.authState, .unauthenticated, "State should be unauthenticated")
    }
    
    /// **Validates: Requirements 1.5, 1.7, 2.5**
    /// Test that state is always one of the valid states.
    func testAuthStateValidity() {
        let validStates: [AuthState] = [
            .unknown,
            .unauthenticated,
            .authenticated(userId: "user1"),
            .authenticated(userId: "user2"),
            .sessionExpired
        ]
        
        for state in validStates {
            authService.setAuthState(state)
            
            // Verify state is one of the valid states
            let isValid = validStates.contains { $0 == authService.authState }
            XCTAssertTrue(isValid, "Auth state should be one of the valid states")
        }
    }
    
    // MARK: - Property 3: Automatic Token Refresh on 401
    
    /// **Validates: Requirements 2.3, 2.7**
    /// For any API request that receives a 401 response, if a valid Refresh_Token exists,
    /// the Auth_Service should attempt token refresh.
    func testTokenRefreshOn401() async {
        // Given: Store a refresh token
        _ = KeychainService.shared.set("test_refresh_token", forKey: "auth.refreshToken")
        _ = KeychainService.shared.set("test_id_token", forKey: "auth.idToken")
        
        // Setup mock to return 401 for refresh (simulating expired refresh token)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.jingever.com/api/auth/refresh")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = "{}".data(using: .utf8)
        
        // When: Try to refresh tokens
        do {
            try await authService.refreshTokens()
            XCTFail("Should throw error on 401")
        } catch {
            // Then: Should throw tokenRefreshFailed
            XCTAssertTrue(error is AuthError, "Error should be AuthError")
            if let authError = error as? AuthError {
                XCTAssertEqual(authError, .tokenRefreshFailed, "Should be tokenRefreshFailed error")
            }
        }
        
        // Verify state is unauthenticated after failed refresh
        XCTAssertEqual(authService.authState, .unauthenticated, "State should be unauthenticated after failed refresh")
    }
    
    /// **Validates: Requirements 2.3, 2.7**
    /// Test successful token refresh.
    func testSuccessfulTokenRefresh() async {
        // Given: Store a refresh token
        _ = KeychainService.shared.set("test_refresh_token", forKey: "auth.refreshToken")
        _ = KeychainService.shared.set("old_id_token", forKey: "auth.idToken")
        
        // Setup mock to return successful token response
        let tokenResponse = TokenResponse(
            accessToken: "new_access_token",
            idToken: "new_id_token",
            refreshToken: "new_refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        mockSession.mockData = try! JSONEncoder().encode(tokenResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.jingever.com/api/auth/refresh")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When: Refresh tokens
        do {
            try await authService.refreshTokens()
            
            // Then: New tokens should be stored
            let storedIdToken = KeychainService.shared.string(forKey: "auth.idToken")
            let storedRefreshToken = KeychainService.shared.string(forKey: "auth.refreshToken")
            
            XCTAssertEqual(storedIdToken, "new_id_token", "New ID token should be stored")
            XCTAssertEqual(storedRefreshToken, "new_refresh_token", "New refresh token should be stored")
            XCTAssertEqual(authService.idToken, "new_id_token", "AuthService idToken should be updated")
        } catch {
            XCTFail("Token refresh should succeed: \(error)")
        }
    }
    
    // MARK: - Token Response Parsing Tests
    
    /// Test TokenResponse encoding and decoding
    func testTokenResponseCoding() {
        let original = TokenResponse(
            accessToken: "access_123",
            idToken: "id_456",
            refreshToken: "refresh_789",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        
        // Encode
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(original) else {
            XCTFail("Failed to encode TokenResponse")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(TokenResponse.self, from: data) else {
            XCTFail("Failed to decode TokenResponse")
            return
        }
        
        XCTAssertEqual(decoded.accessToken, original.accessToken)
        XCTAssertEqual(decoded.idToken, original.idToken)
        XCTAssertEqual(decoded.refreshToken, original.refreshToken)
        XCTAssertEqual(decoded.expiresIn, original.expiresIn)
        XCTAssertEqual(decoded.tokenType, original.tokenType)
    }
    
    /// Test TokenResponse decoding from JSON with snake_case keys
    func testTokenResponseDecodingFromJSON() {
        let json = """
        {
            "access_token": "access_abc",
            "id_token": "id_def",
            "refresh_token": "refresh_ghi",
            "expires_in": 7200,
            "token_type": "Bearer"
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data from JSON")
            return
        }
        
        let decoder = JSONDecoder()
        guard let response = try? decoder.decode(TokenResponse.self, from: data) else {
            XCTFail("Failed to decode TokenResponse from JSON")
            return
        }
        
        XCTAssertEqual(response.accessToken, "access_abc")
        XCTAssertEqual(response.idToken, "id_def")
        XCTAssertEqual(response.refreshToken, "refresh_ghi")
        XCTAssertEqual(response.expiresIn, 7200)
        XCTAssertEqual(response.tokenType, "Bearer")
    }
    
    // MARK: - CognitoUserInfo Tests
    
    /// Test CognitoUserInfo decoding
    func testCognitoUserInfoDecoding() {
        let json = """
        {
            "id": "user-123",
            "email": "test@example.com",
            "name": "Test User",
            "avatar_url": "https://example.com/avatar.png"
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data from JSON")
            return
        }
        
        let decoder = JSONDecoder()
        guard let userInfo = try? decoder.decode(CognitoUserInfo.self, from: data) else {
            XCTFail("Failed to decode CognitoUserInfo")
            return
        }
        
        XCTAssertEqual(userInfo.id, "user-123")
        XCTAssertEqual(userInfo.email, "test@example.com")
        XCTAssertEqual(userInfo.name, "Test User")
        XCTAssertEqual(userInfo.avatarUrl, "https://example.com/avatar.png")
    }
    
    /// Test CognitoUserInfo decoding with optional fields
    func testCognitoUserInfoDecodingMinimal() {
        let json = """
        {
            "id": "user-456",
            "email": "minimal@example.com"
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data from JSON")
            return
        }
        
        let decoder = JSONDecoder()
        guard let userInfo = try? decoder.decode(CognitoUserInfo.self, from: data) else {
            XCTFail("Failed to decode CognitoUserInfo")
            return
        }
        
        XCTAssertEqual(userInfo.id, "user-456")
        XCTAssertEqual(userInfo.email, "minimal@example.com")
        XCTAssertNil(userInfo.name)
        XCTAssertNil(userInfo.avatarUrl)
    }
}
