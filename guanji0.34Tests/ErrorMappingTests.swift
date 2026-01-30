//
//  ErrorMappingTests.swift
//  guanji0.34Tests
//
//  错误映射单元测试
//  测试 HTTP 状态码和网络错误到用户友好消息的映射
//  - Property 7: 错误码到消息的映射
//  - Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
//

import XCTest
@testable import guanji0_34

// MARK: - Error Mapping Tests

final class ErrorMappingTests: XCTestCase {
    
    // MARK: - Property 7: Error Code to Message Mapping
    
    /// **Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5**
    /// For any HTTP error response with status code in {401, 429, 500} or network error,
    /// the displayed error message should match the predefined user-friendly message.
    
    // MARK: - HTTP 401 → Session Expired
    
    /// **Validates: Requirements 7.1**
    /// Test that HTTP 401 maps to "会话已过期，请重新登录"
    func testHTTP401MapsToSessionExpiredMessage() {
        // Given: HTTP 401 status code
        let statusCode = 401
        
        // When: Map to APIError
        let error = ErrorMapper.fromStatusCode(statusCode)
        
        // Then: Should be sessionExpired with correct message
        XCTAssertEqual(error, .sessionExpired, "401 should map to sessionExpired")
        XCTAssertEqual(error.errorDescription, "会话已过期，请重新登录",
                      "401 message should be '会话已过期，请重新登录'")
    }
    
    /// **Validates: Requirements 7.1**
    /// Test that ClaudeflareError.authenticationError has correct message
    func testClaudeflareAuthErrorMessage() {
        // Given: ClaudeflareError.authenticationError
        let error = ClaudeflareError.authenticationError
        
        // Then: Should have correct message
        XCTAssertEqual(error.errorDescription, "会话已过期，请重新登录",
                      "authenticationError message should be '会话已过期，请重新登录'")
    }
    
    // MARK: - HTTP 429 → Quota Exceeded
    
    /// **Validates: Requirements 7.2**
    /// Test that HTTP 429 maps to "使用额度已用完，请稍后再试"
    func testHTTP429MapsToQuotaExceededMessage() {
        // Given: HTTP 429 status code
        let statusCode = 429
        
        // When: Map to APIError
        let error = ErrorMapper.fromStatusCode(statusCode)
        
        // Then: Should be quotaExceeded with correct message
        XCTAssertEqual(error, .quotaExceeded, "429 should map to quotaExceeded")
        XCTAssertEqual(error.errorDescription, "使用额度已用完，请稍后再试",
                      "429 message should be '使用额度已用完，请稍后再试'")
    }
    
    /// **Validates: Requirements 7.2**
    /// Test that ClaudeflareError.quotaExceeded has correct message
    func testClaudeflareQuotaExceededMessage() {
        // Given: ClaudeflareError.quotaExceeded
        let error = ClaudeflareError.quotaExceeded
        
        // Then: Should have correct message
        XCTAssertEqual(error.errorDescription, "使用额度已用完，请稍后再试",
                      "quotaExceeded message should be '使用额度已用完，请稍后再试'")
    }
    
    // MARK: - HTTP 500 → Server Error
    
    /// **Validates: Requirements 7.3**
    /// Test that HTTP 500 maps to "服务器错误，请稍后重试"
    func testHTTP500MapsToServerErrorMessage() {
        // Given: HTTP 500 status code
        let statusCode = 500
        
        // When: Map to APIError
        let error = ErrorMapper.fromStatusCode(statusCode)
        
        // Then: Should be serverError with correct message
        XCTAssertEqual(error, .serverError(500), "500 should map to serverError(500)")
        XCTAssertEqual(error.errorDescription, "服务器错误，请稍后重试",
                      "500 message should be '服务器错误，请稍后重试'")
    }
    
    /// **Validates: Requirements 7.3**
    /// Test that HTTP 502/503 maps to service unavailable message
    func testHTTP502And503MapsToServiceUnavailableMessage() {
        // Test 502
        let error502 = ErrorMapper.fromStatusCode(502)
        XCTAssertEqual(error502, .serverError(502), "502 should map to serverError(502)")
        XCTAssertEqual(error502.errorDescription, "服务暂时不可用，请稍后重试",
                      "502 message should be '服务暂时不可用，请稍后重试'")
        
        // Test 503
        let error503 = ErrorMapper.fromStatusCode(503)
        XCTAssertEqual(error503, .serverError(503), "503 should map to serverError(503)")
        XCTAssertEqual(error503.errorDescription, "服务暂时不可用，请稍后重试",
                      "503 message should be '服务暂时不可用，请稍后重试'")
    }
    
    /// **Validates: Requirements 7.3**
    /// Test that ClaudeflareError.serverError has correct messages
    func testClaudeflareServerErrorMessages() {
        // Test 500
        let error500 = ClaudeflareError.serverError(500)
        XCTAssertEqual(error500.errorDescription, "服务器错误，请稍后重试",
                      "serverError(500) message should be '服务器错误，请稍后重试'")
        
        // Test 502
        let error502 = ClaudeflareError.serverError(502)
        XCTAssertEqual(error502.errorDescription, "服务暂时不可用，请稍后重试",
                      "serverError(502) message should be '服务暂时不可用，请稍后重试'")
        
        // Test 503
        let error503 = ClaudeflareError.serverError(503)
        XCTAssertEqual(error503.errorDescription, "服务暂时不可用，请稍后重试",
                      "serverError(503) message should be '服务暂时不可用，请稍后重试'")
    }
    
    // MARK: - Network Error → Network Unavailable
    
    /// **Validates: Requirements 7.4**
    /// Test that network errors map to "网络连接失败，请检查网络"
    func testNetworkErrorMapsToNetworkUnavailableMessage() {
        // Given: URLError.notConnectedToInternet
        let urlError = URLError(.notConnectedToInternet)
        
        // When: Map to APIError
        let error = ErrorMapper.fromURLError(urlError)
        
        // Then: Should be networkUnavailable with correct message
        XCTAssertEqual(error, .networkUnavailable, "notConnectedToInternet should map to networkUnavailable")
        XCTAssertEqual(error.errorDescription, "网络连接失败，请检查网络",
                      "Network error message should be '网络连接失败，请检查网络'")
    }
    
    /// **Validates: Requirements 7.4**
    /// Test that network connection lost maps correctly
    func testNetworkConnectionLostMapsCorrectly() {
        // Given: URLError.networkConnectionLost
        let urlError = URLError(.networkConnectionLost)
        
        // When: Map to APIError
        let error = ErrorMapper.fromURLError(urlError)
        
        // Then: Should be networkUnavailable with correct message
        XCTAssertEqual(error, .networkUnavailable, "networkConnectionLost should map to networkUnavailable")
        XCTAssertEqual(error.errorDescription, "网络连接失败，请检查网络",
                      "Network error message should be '网络连接失败，请检查网络'")
    }
    
    /// **Validates: Requirements 7.4**
    /// Test that ClaudeflareError.networkError has correct message
    func testClaudeflareNetworkErrorMessage() {
        // Given: ClaudeflareError.networkError
        let error = ClaudeflareError.networkError("Connection failed")
        
        // Then: Should have correct message (ignoring the detail)
        XCTAssertEqual(error.errorDescription, "网络连接失败，请检查网络",
                      "networkError message should be '网络连接失败，请检查网络'")
    }
    
    // MARK: - Error Code Logging Tests
    
    /// **Validates: Requirements 7.5, 7.6**
    /// Test that error codes are correctly generated for logging
    func testErrorCodesForLogging() {
        // Test APIError error codes
        XCTAssertEqual(APIError.sessionExpired.errorCode, "API_401_SESSION_EXPIRED")
        XCTAssertEqual(APIError.quotaExceeded.errorCode, "API_429_QUOTA_EXCEEDED")
        XCTAssertEqual(APIError.serverError(500).errorCode, "API_500_SERVER_ERROR")
        XCTAssertEqual(APIError.networkUnavailable.errorCode, "NET_NO_CONNECTION")
        XCTAssertEqual(APIError.requestTimeout.errorCode, "NET_TIMEOUT")
    }
    
    /// **Validates: Requirements 7.5, 7.6**
    /// Test that ClaudeflareError error codes are correctly generated
    func testClaudeflareErrorCodesForLogging() {
        XCTAssertEqual(ClaudeflareError.authenticationError.errorCode, "CHAT_401_AUTH_ERROR")
        XCTAssertEqual(ClaudeflareError.quotaExceeded.errorCode, "CHAT_429_QUOTA_EXCEEDED")
        XCTAssertEqual(ClaudeflareError.serverError(500).errorCode, "CHAT_500_SERVER_ERROR")
        XCTAssertEqual(ClaudeflareError.networkError("test").errorCode, "CHAT_NETWORK_ERROR")
    }
    
    // MARK: - Comprehensive Status Code Mapping Tests
    
    /// **Validates: Requirements 7.1, 7.2, 7.3**
    /// Test all required status codes map to correct messages
    func testAllRequiredStatusCodeMappings() {
        // Define expected mappings
        let expectedMappings: [(Int, String)] = [
            (401, "会话已过期，请重新登录"),
            (429, "使用额度已用完，请稍后再试"),
            (500, "服务器错误，请稍后重试"),
            (502, "服务暂时不可用，请稍后重试"),
            (503, "服务暂时不可用，请稍后重试")
        ]
        
        for (statusCode, expectedMessage) in expectedMappings {
            let error = ErrorMapper.fromStatusCode(statusCode)
            XCTAssertEqual(error.errorDescription, expectedMessage,
                          "Status code \(statusCode) should map to '\(expectedMessage)'")
        }
    }
    
    // MARK: - AuthError Mapping Tests
    
    /// **Validates: Requirements 7.1**
    /// Test that AuthError.sessionExpired maps correctly
    func testAuthErrorSessionExpiredMapping() {
        let authError = AuthError.sessionExpired
        let apiError = ErrorMapper.fromAuthError(authError)
        
        XCTAssertEqual(apiError, .sessionExpired)
        XCTAssertEqual(apiError.errorDescription, "会话已过期，请重新登录")
    }
    
    /// **Validates: Requirements 7.2**
    /// Test that AuthError.rateLimited maps correctly
    func testAuthErrorRateLimitedMapping() {
        let authError = AuthError.rateLimited
        let apiError = ErrorMapper.fromAuthError(authError)
        
        XCTAssertEqual(apiError, .quotaExceeded)
        XCTAssertEqual(apiError.errorDescription, "使用额度已用完，请稍后再试")
    }
    
    /// **Validates: Requirements 7.3**
    /// Test that AuthError.serviceUnavailable maps correctly
    func testAuthErrorServiceUnavailableMapping() {
        let authError = AuthError.serviceUnavailable
        let apiError = ErrorMapper.fromAuthError(authError)
        
        XCTAssertEqual(apiError, .serverError(503))
        XCTAssertEqual(apiError.errorDescription, "服务暂时不可用，请稍后重试")
    }
    
    /// **Validates: Requirements 7.4**
    /// Test that AuthError.networkError maps correctly
    func testAuthErrorNetworkErrorMapping() {
        let authError = AuthError.networkError("Connection failed")
        let apiError = ErrorMapper.fromAuthError(authError)
        
        XCTAssertEqual(apiError, .networkUnavailable)
        XCTAssertEqual(apiError.errorDescription, "网络连接失败，请检查网络")
    }
    
    // MARK: - ClaudeflareError Mapping Tests
    
    /// **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
    /// Test ClaudeflareError to APIError mapping
    func testClaudeflareErrorToAPIErrorMapping() {
        // Test authenticationError → sessionExpired
        let authError = ErrorMapper.fromClaudeflareError(.authenticationError)
        XCTAssertEqual(authError, .sessionExpired)
        
        // Test quotaExceeded → quotaExceeded
        let quotaError = ErrorMapper.fromClaudeflareError(.quotaExceeded)
        XCTAssertEqual(quotaError, .quotaExceeded)
        
        // Test serverError → serverError
        let serverError = ErrorMapper.fromClaudeflareError(.serverError(500))
        XCTAssertEqual(serverError, .serverError(500))
        
        // Test networkError → networkUnavailable
        let networkError = ErrorMapper.fromClaudeflareError(.networkError("test"))
        XCTAssertEqual(networkError, .networkUnavailable)
    }
    
    // MARK: - User-Friendly Message Constants Tests
    
    /// **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
    /// Test that UserFriendlyErrorMessage constants match expected values
    func testUserFriendlyErrorMessageConstants() {
        XCTAssertEqual(UserFriendlyErrorMessage.sessionExpired, "会话已过期，请重新登录")
        XCTAssertEqual(UserFriendlyErrorMessage.quotaExceeded, "使用额度已用完，请稍后再试")
        XCTAssertEqual(UserFriendlyErrorMessage.serverError, "服务器错误，请稍后重试")
        XCTAssertEqual(UserFriendlyErrorMessage.networkError, "网络连接失败，请检查网络")
        XCTAssertEqual(UserFriendlyErrorMessage.serviceUnavailable, "服务暂时不可用，请稍后重试")
    }
    
    // MARK: - Timeout Error Tests
    
    /// Test that timeout errors map correctly
    func testTimeoutErrorMapping() {
        // Given: URLError.timedOut
        let urlError = URLError(.timedOut)
        
        // When: Map to APIError
        let error = ErrorMapper.fromURLError(urlError)
        
        // Then: Should be requestTimeout
        XCTAssertEqual(error, .requestTimeout)
        XCTAssertEqual(error.errorDescription, "请求超时，请检查网络后重试")
    }
    
    // MARK: - Cannot Connect Error Tests
    
    /// Test that cannot connect errors map correctly
    func testCannotConnectErrorMapping() {
        // Given: URLError.cannotConnectToHost
        let urlError = URLError(.cannotConnectToHost)
        
        // When: Map to APIError
        let error = ErrorMapper.fromURLError(urlError)
        
        // Then: Should be cannotConnectToHost
        XCTAssertEqual(error, .cannotConnectToHost)
        XCTAssertEqual(error.errorDescription, "无法连接到服务器，请稍后重试")
    }
}
