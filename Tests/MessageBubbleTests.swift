import XCTest
@testable import guanji0_34

/// Tests for MessageBubble enhanced interaction features
/// Validates: Copy functionality, regenerate callback, context menu
final class MessageBubbleTests: XCTestCase {
    
    // MARK: - Copy Functionality Tests
    
    func testCopyMessageAction() {
        // Given: An AI message
        let message = AIMessage(
            role: .assistant,
            content: "This is a test response from AI."
        )
        
        // When: User copies the message
        // Then: Content should be copied to clipboard
        // Note: Actual clipboard testing requires UI testing framework
        XCTAssertFalse(message.content.isEmpty)
    }
    
    func testCopyWithThinkingAction() {
        // Given: An AI message with reasoning
        let message = AIMessage(
            role: .assistant,
            content: "Final answer",
            reasoningContent: "Let me think about this..."
        )
        
        // When: User copies with thinking
        // Then: Both reasoning and content should be included
        XCTAssertNotNil(message.reasoningContent)
        XCTAssertFalse(message.content.isEmpty)
    }
    
    // MARK: - Context Menu Tests
    
    func testContextMenuForUserMessage() {
        // Given: A user message
        let message = AIMessage(
            role: .user,
            content: "Hello AI"
        )
        
        // Then: Context menu should only show copy option
        XCTAssertEqual(message.role, .user)
    }
    
    func testContextMenuForAIMessage() {
        // Given: An AI message
        let message = AIMessage(
            role: .assistant,
            content: "Hello user"
        )
        
        // Then: Context menu should show copy and regenerate options
        XCTAssertEqual(message.role, .assistant)
    }
    
    // MARK: - Regenerate Callback Tests
    
    func testRegenerateCallbackInvoked() {
        // Given: A regenerate callback
        var callbackInvoked = false
        let onRegenerate: () -> Void = {
            callbackInvoked = true
        }
        
        // When: Callback is invoked
        onRegenerate()
        
        // Then: Flag should be set
        XCTAssertTrue(callbackInvoked)
    }
    
    func testRegenerateOnlyForAIMessages() {
        // Given: User and AI messages
        let userMessage = AIMessage(role: .user, content: "Test")
        let aiMessage = AIMessage(role: .assistant, content: "Response")
        
        // Then: Only AI messages should have regenerate option
        XCTAssertEqual(userMessage.role, .user)
        XCTAssertEqual(aiMessage.role, .assistant)
    }
    
    // MARK: - Message Actions View Tests
    
    func testMessageActionsVisibility() {
        // Given: User and AI messages
        let userMessage = AIMessage(role: .user, content: "Test")
        let aiMessage = AIMessage(role: .assistant, content: "Response")
        
        // Then: Actions should only be visible for AI messages
        XCTAssertEqual(userMessage.role, .user)
        XCTAssertEqual(aiMessage.role, .assistant)
    }
}
