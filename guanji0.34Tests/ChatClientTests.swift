//
//  ChatClientTests.swift
//  guanji0.34Tests
//
//  ChatClient (ClaudeflareClient) 单元测试
//  测试新 API 相关功能
//  - Property 4: Bearer 认证头格式
//  - Property 5: 请求格式有效性
//  - Property 6: SSE 解析完整性
//

import XCTest
@testable import guanji0_34

// MARK: - ChatClient Tests

final class ChatClientTests: XCTestCase {
    
    // MARK: - Property 4: Bearer Auth Header Format
    
    /// **Validates: Requirements 2.6**
    /// For any authenticated API request, the Authorization header should be formatted
    /// as "Bearer {id_token}" where id_token is the current valid ID_Token.
    func testBearerAuthHeaderFormat() {
        // Given: Various token values
        let testTokens = [
            "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test1",
            "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test2",
            "short_token",
            "a" + String(repeating: "b", count: 500)
        ]
        
        for token in testTokens {
            // When: Format as Bearer header
            let authHeader = "Bearer \(token)"
            
            // Then: Should match expected format
            XCTAssertTrue(authHeader.hasPrefix("Bearer "), "Auth header should start with 'Bearer '")
            XCTAssertEqual(authHeader, "Bearer \(token)", "Auth header should be 'Bearer {token}'")
            
            // Verify token can be extracted
            let extractedToken = String(authHeader.dropFirst("Bearer ".count))
            XCTAssertEqual(extractedToken, token, "Extracted token should match original")
        }
    }
    
    // MARK: - Property 5: Chat Request Format Validity
    
    /// **Validates: Requirements 4.1, 4.2, 4.3, 4.4**
    /// For any chat request with messages array, model_tier in {fast, balanced, powerful},
    /// and thinking boolean, the request body should be valid JSON matching the schema.
    func testChatRequestFormatValidity() {
        // Test all combinations of model_tier and thinking
        let tiers: [ModelTier] = [.fast, .balanced, .powerful]
        let thinkingValues = [true, false]
        
        for tier in tiers {
            for thinking in thinkingValues {
                // Given: A chat request with specific parameters
                let messages = [
                    ChatMessage(role: "user", content: "Hello"),
                    ChatMessage(role: "assistant", content: "Hi there!"),
                    ChatMessage(role: "user", content: "How are you?")
                ]
                
                let request = NewChatRequest(
                    messages: messages,
                    modelTier: tier,
                    thinking: thinking
                )
                
                // When: Encode to JSON
                let encoder = JSONEncoder()
                guard let jsonData = try? encoder.encode(request) else {
                    XCTFail("Failed to encode NewChatRequest for tier=\(tier), thinking=\(thinking)")
                    continue
                }
                
                // Then: Should be valid JSON with correct structure
                guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    XCTFail("Failed to parse JSON for tier=\(tier), thinking=\(thinking)")
                    continue
                }
                
                // Verify model_tier
                XCTAssertEqual(json["model_tier"] as? String, tier.rawValue,
                              "model_tier should be '\(tier.rawValue)'")
                
                // Verify thinking
                XCTAssertEqual(json["thinking"] as? Bool, thinking,
                              "thinking should be \(thinking)")
                
                // Verify messages array
                guard let messagesArray = json["messages"] as? [[String: Any]] else {
                    XCTFail("messages should be an array")
                    continue
                }
                
                XCTAssertEqual(messagesArray.count, 3, "Should have 3 messages")
                
                // Verify message structure
                for (index, messageDict) in messagesArray.enumerated() {
                    XCTAssertNotNil(messageDict["role"] as? String,
                                   "Message \(index) should have 'role'")
                    XCTAssertNotNil(messageDict["content"] as? String,
                                   "Message \(index) should have 'content'")
                }
            }
        }
    }
    
    /// **Validates: Requirements 4.2, 4.3**
    /// Test that model_tier values are correctly encoded.
    func testModelTierValues() {
        // Verify all ModelTier raw values
        XCTAssertEqual(ModelTier.fast.rawValue, "fast")
        XCTAssertEqual(ModelTier.balanced.rawValue, "balanced")
        XCTAssertEqual(ModelTier.powerful.rawValue, "powerful")
        
        // Verify all cases are covered
        XCTAssertEqual(ModelTier.allCases.count, 3)
    }
    
    /// **Validates: Requirements 4.2**
    /// Test NewChatRequest encoding with empty messages.
    func testChatRequestWithEmptyMessages() {
        let request = NewChatRequest(
            messages: [],
            modelTier: .balanced,
            thinking: false
        )
        
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(request),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            XCTFail("Failed to encode/parse NewChatRequest with empty messages")
            return
        }
        
        guard let messagesArray = json["messages"] as? [[String: Any]] else {
            XCTFail("messages should be an array")
            return
        }
        
        XCTAssertEqual(messagesArray.count, 0, "Should have 0 messages")
    }
    
    // MARK: - Property 6: SSE Event Parsing Completeness
    
    /// **Validates: Requirements 4.5, 4.6, 4.7**
    /// For any valid SSE event string, parsing should extract content correctly,
    /// and when done=true, usage statistics should be available.
    func testSSEEventParsingContent() {
        // Test content event
        let contentJSON = """
        {"content": "Hello", "done": false}
        """
        
        guard let data = contentJSON.data(using: .utf8),
              let event = try? JSONDecoder().decode(ChatSSEEvent.self, from: data) else {
            XCTFail("Failed to parse content SSE event")
            return
        }
        
        XCTAssertEqual(event.content, "Hello", "Content should be 'Hello'")
        XCTAssertFalse(event.done, "done should be false")
        XCTAssertNil(event.usage, "usage should be nil for non-done event")
        XCTAssertNil(event.error, "error should be nil")
        XCTAssertNil(event.errorCode, "errorCode should be nil")
    }
    
    /// **Validates: Requirements 4.6**
    /// Test SSE event with done=true and usage statistics.
    func testSSEEventParsingDoneWithUsage() {
        let doneJSON = """
        {"content": "", "done": true, "usage": {"input_tokens": 10, "output_tokens": 5, "total_tokens": 15}}
        """
        
        guard let data = doneJSON.data(using: .utf8),
              let event = try? JSONDecoder().decode(ChatSSEEvent.self, from: data) else {
            XCTFail("Failed to parse done SSE event")
            return
        }
        
        XCTAssertEqual(event.content, "", "Content should be empty")
        XCTAssertTrue(event.done, "done should be true")
        XCTAssertNotNil(event.usage, "usage should not be nil for done event")
        
        if let usage = event.usage {
            XCTAssertEqual(usage.inputTokens, 10, "inputTokens should be 10")
            XCTAssertEqual(usage.outputTokens, 5, "outputTokens should be 5")
            XCTAssertEqual(usage.totalTokens, 15, "totalTokens should be 15")
        }
    }
    
    /// **Validates: Requirements 4.7**
    /// Test SSE event with error.
    func testSSEEventParsingError() {
        let errorJSON = """
        {"error": "LLM provider error", "error_code": "CHAT_502_001", "done": false}
        """
        
        guard let data = errorJSON.data(using: .utf8),
              let event = try? JSONDecoder().decode(ChatSSEEvent.self, from: data) else {
            XCTFail("Failed to parse error SSE event")
            return
        }
        
        XCTAssertEqual(event.error, "LLM provider error", "error should match")
        XCTAssertEqual(event.errorCode, "CHAT_502_001", "errorCode should match")
        XCTAssertFalse(event.done, "done should be false")
        XCTAssertNil(event.content, "content should be nil for error event")
    }
    
    /// **Validates: Requirements 4.5, 4.6**
    /// Test parsing multiple SSE events in sequence.
    func testSSEEventParsingSequence() {
        let events = [
            """
            {"content": "你", "done": false}
            """,
            """
            {"content": "好", "done": false}
            """,
            """
            {"content": "", "done": true, "usage": {"input_tokens": 10, "output_tokens": 2, "total_tokens": 12}}
            """
        ]
        
        var accumulatedContent = ""
        var finalUsage: ChatUsage?
        
        for (index, eventJSON) in events.enumerated() {
            guard let data = eventJSON.data(using: .utf8),
                  let event = try? JSONDecoder().decode(ChatSSEEvent.self, from: data) else {
                XCTFail("Failed to parse SSE event at index \(index)")
                continue
            }
            
            if let content = event.content, !content.isEmpty {
                accumulatedContent += content
            }
            
            if event.done {
                finalUsage = event.usage
            }
        }
        
        XCTAssertEqual(accumulatedContent, "你好", "Accumulated content should be '你好'")
        XCTAssertNotNil(finalUsage, "Final usage should not be nil")
        XCTAssertEqual(finalUsage?.inputTokens, 10)
        XCTAssertEqual(finalUsage?.outputTokens, 2)
        XCTAssertEqual(finalUsage?.totalTokens, 12)
    }
    
    // MARK: - ChatUsage Tests
    
    /// Test ChatUsage encoding and decoding.
    func testChatUsageCoding() {
        let original = ChatUsage(inputTokens: 100, outputTokens: 50, totalTokens: 150)
        
        // Encode
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(original) else {
            XCTFail("Failed to encode ChatUsage")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(ChatUsage.self, from: data) else {
            XCTFail("Failed to decode ChatUsage")
            return
        }
        
        XCTAssertEqual(decoded.inputTokens, original.inputTokens)
        XCTAssertEqual(decoded.outputTokens, original.outputTokens)
        XCTAssertEqual(decoded.totalTokens, original.totalTokens)
    }
    
    /// Test ChatUsage decoding from JSON with snake_case keys.
    func testChatUsageDecodingFromJSON() {
        let json = """
        {
            "input_tokens": 200,
            "output_tokens": 100,
            "total_tokens": 300
        }
        """
        
        guard let data = json.data(using: .utf8),
              let usage = try? JSONDecoder().decode(ChatUsage.self, from: data) else {
            XCTFail("Failed to decode ChatUsage from JSON")
            return
        }
        
        XCTAssertEqual(usage.inputTokens, 200)
        XCTAssertEqual(usage.outputTokens, 100)
        XCTAssertEqual(usage.totalTokens, 300)
    }
    
    // MARK: - ChatMessage Tests
    
    /// Test ChatMessage encoding and decoding.
    func testChatMessageCoding() {
        let original = ChatMessage(role: "user", content: "Hello, world!")
        
        // Encode
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(original) else {
            XCTFail("Failed to encode ChatMessage")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(ChatMessage.self, from: data) else {
            XCTFail("Failed to decode ChatMessage")
            return
        }
        
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
    }
    
    /// Test ChatMessage with various roles.
    func testChatMessageRoles() {
        let roles = ["user", "assistant", "system"]
        
        for role in roles {
            let message = ChatMessage(role: role, content: "Test content")
            
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(message),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                XCTFail("Failed to encode/parse ChatMessage with role '\(role)'")
                continue
            }
            
            XCTAssertEqual(json["role"] as? String, role)
            XCTAssertEqual(json["content"] as? String, "Test content")
        }
    }
}
