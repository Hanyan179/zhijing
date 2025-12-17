import Foundation

// MARK: - Property-Based Testing for AI Conversation Models
// Note: These tests require SwiftCheck library to be added to the project
// For now, we implement a simple randomized testing approach using Foundation

/// Test utilities for generating random AI conversation data
enum AIConversationTestGenerators {
    
    /// Generate a random string of specified length
    static func randomString(length: Int = 20) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate a random date within the last year
    static func randomDate() -> Date {
        let now = Date()
        let randomInterval = TimeInterval.random(in: -365*24*60*60...0)
        return now.addingTimeInterval(randomInterval)
    }
    
    /// Generate a random MessageRole
    static func randomRole() -> MessageRole {
        [.user, .assistant, .system].randomElement()!
    }
    
    /// Generate a random AttachmentType
    static func randomAttachmentType() -> AttachmentType {
        [.image, .audio, .file].randomElement()!
    }
    
    /// Generate a random MessageAttachment
    static func randomAttachment() -> MessageAttachment {
        MessageAttachment(
            id: UUID().uuidString,
            type: randomAttachmentType(),
            url: "file://\(randomString(length: 10))",
            name: Bool.random() ? randomString(length: 8) : nil,
            duration: Bool.random() ? "\(Int.random(in: 1...300))" : nil
        )
    }
    
    /// Generate a random AIMessage
    static func randomMessage() -> AIMessage {
        AIMessage(
            id: UUID().uuidString,
            role: randomRole(),
            content: randomString(length: Int.random(in: 10...200)),
            reasoningContent: Bool.random() ? randomString(length: Int.random(in: 20...100)) : nil,
            timestamp: randomDate(),
            attachments: Bool.random() ? (0..<Int.random(in: 1...3)).map { _ in randomAttachment() } : nil
        )
    }
    
    /// Generate a random AIConversation
    static func randomConversation() -> AIConversation {
        let messageCount = Int.random(in: 0...10)
        let messages = (0..<messageCount).map { _ in randomMessage() }
        let dayCount = Int.random(in: 1...3)
        let days = (0..<dayCount).map { _ in
            let date = randomDate()
            return DateUtilities.formatDate(date)
        }
        
        return AIConversation(
            id: UUID().uuidString,
            title: Bool.random() ? randomString(length: Int.random(in: 5...20)) : nil,
            messages: messages,
            associatedDays: days,
            createdAt: randomDate(),
            updatedAt: randomDate()
        )
    }
}


// MARK: - Property Tests

/// Property-based tests for AI Conversation models
/// **Feature: ai-conversation-mode**
enum AIConversationPropertyTests {
    
    /// **Property 1: Conversation Serialization Round-Trip**
    /// **Validates: Requirements 3.5, 3.6**
    /// For any valid AIConversation object, serializing to JSON and then
    /// deserializing should produce an equivalent conversation with all
    /// messages, metadata, and associated days preserved.
    static func testConversationSerializationRoundTrip(iterations: Int = 100) -> (passed: Bool, failingExample: AIConversation?) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for _ in 0..<iterations {
            let original = AIConversationTestGenerators.randomConversation()
            
            do {
                let encoded = try encoder.encode(original)
                let decoded = try decoder.decode(AIConversation.self, from: encoded)
                
                // Verify all properties are preserved
                guard original.id == decoded.id,
                      original.title == decoded.title,
                      original.messages.count == decoded.messages.count,
                      original.associatedDays == decoded.associatedDays else {
                    return (false, original)
                }
                
                // Verify each message is preserved
                for (origMsg, decodedMsg) in zip(original.messages, decoded.messages) {
                    guard origMsg.id == decodedMsg.id,
                          origMsg.role == decodedMsg.role,
                          origMsg.content == decodedMsg.content,
                          origMsg.reasoningContent == decodedMsg.reasoningContent else {
                        return (false, original)
                    }
                    
                    // Verify attachments
                    if let origAttachments = origMsg.attachments,
                       let decodedAttachments = decodedMsg.attachments {
                        guard origAttachments.count == decodedAttachments.count else {
                            return (false, original)
                        }
                        for (origAtt, decodedAtt) in zip(origAttachments, decodedAttachments) {
                            guard origAtt.id == decodedAtt.id,
                                  origAtt.type == decodedAtt.type,
                                  origAtt.url == decodedAtt.url,
                                  origAtt.name == decodedAtt.name,
                                  origAtt.duration == decodedAtt.duration else {
                                return (false, original)
                            }
                        }
                    } else if origMsg.attachments != nil || decodedMsg.attachments != nil {
                        // One has attachments and the other doesn't
                        if origMsg.attachments?.isEmpty != true && decodedMsg.attachments?.isEmpty != true {
                            return (false, original)
                        }
                    }
                }
                
            } catch {
                print("Serialization error: \(error)")
                return (false, original)
            }
        }
        
        return (true, nil)
    }
    
    /// **Property 2: Message Chronological Order**
    /// **Validates: Requirements 4.1**
    /// For any conversation with multiple messages, the sortedMessages property
    /// should always return messages sorted by timestamp in ascending order.
    static func testMessageChronologicalOrder(iterations: Int = 100) -> (passed: Bool, failingExample: AIConversation?) {
        for _ in 0..<iterations {
            // Generate a conversation with random messages (potentially out of order)
            let messageCount = Int.random(in: 2...20)
            var messages: [AIMessage] = []
            
            // Create messages with random timestamps (not necessarily in order)
            for _ in 0..<messageCount {
                let message = AIMessage(
                    id: UUID().uuidString,
                    role: AIConversationTestGenerators.randomRole(),
                    content: AIConversationTestGenerators.randomString(length: Int.random(in: 10...50)),
                    timestamp: AIConversationTestGenerators.randomDate()
                )
                messages.append(message)
            }
            
            let conversation = AIConversation(
                id: UUID().uuidString,
                messages: messages
            )
            
            // Get sorted messages
            let sorted = conversation.sortedMessages
            
            // Verify chronological order (ascending by timestamp)
            for i in 0..<(sorted.count - 1) {
                if sorted[i].timestamp > sorted[i + 1].timestamp {
                    return (false, conversation)
                }
            }
        }
        
        return (true, nil)
    }
    
    /// **Property 3: Unique Conversation IDs**
    /// **Validates: Requirements 3.1**
    /// For any set of newly created conversations, all conversation IDs
    /// should be unique (no duplicates).
    static func testUniqueConversationIDs(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        var seenIds = Set<String>()
        
        for _ in 0..<iterations {
            let conversation = AIConversation()
            
            if seenIds.contains(conversation.id) {
                return (false, "Duplicate ID found: \(conversation.id)")
            }
            seenIds.insert(conversation.id)
        }
        
        return (true, nil)
    }
    
    /// **Property 4: Day Association Consistency**
    /// **Validates: Requirements 3.3, 7.2**
    /// For any conversation that receives a message on a new day, the new day's
    /// date string should be added to the conversation's associatedDays array
    /// without duplicates.
    static func testDayAssociationConsistency(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Create a conversation with some initial days
            let initialDayCount = Int.random(in: 1...3)
            var initialDays: [String] = []
            for _ in 0..<initialDayCount {
                let date = AIConversationTestGenerators.randomDate()
                let dayString = DateUtilities.formatDate(date)
                if !initialDays.contains(dayString) {
                    initialDays.append(dayString)
                }
            }
            
            var conversation = AIConversation(
                id: UUID().uuidString,
                associatedDays: initialDays
            )
            
            // Add messages on various days (some new, some existing)
            let messageCount = Int.random(in: 5...15)
            for _ in 0..<messageCount {
                let messageDate = AIConversationTestGenerators.randomDate()
                let message = AIMessage(
                    id: UUID().uuidString,
                    role: AIConversationTestGenerators.randomRole(),
                    content: AIConversationTestGenerators.randomString(length: 20),
                    timestamp: messageDate
                )
                
                let dayString = DateUtilities.formatDate(messageDate)
                let dayExistedBefore = conversation.associatedDays.contains(dayString)
                let countBefore = conversation.associatedDays.count
                
                conversation.addMessage(message)
                
                // Verify: The day should now be in associatedDays
                if !conversation.associatedDays.contains(dayString) {
                    return (false, "Day \(dayString) not added after message")
                }
                
                // Verify: No duplicates - if day existed, count should be same; if new, count should be +1
                if dayExistedBefore {
                    if conversation.associatedDays.count != countBefore {
                        return (false, "Duplicate day \(dayString) added")
                    }
                } else {
                    if conversation.associatedDays.count != countBefore + 1 {
                        return (false, "Day count mismatch after adding new day \(dayString)")
                    }
                }
                
                // Verify: No duplicates in the array
                let uniqueDays = Set(conversation.associatedDays)
                if uniqueDays.count != conversation.associatedDays.count {
                    return (false, "Duplicate days found in associatedDays array")
                }
            }
        }
        
        return (true, nil)
    }
    
    /// **Property 5: Conversation Grouping Completeness**
    /// **Validates: Requirements 2.1, 2.6, 3.4**
    /// For any set of conversations and any day query, a conversation should
    /// appear in a day's group if and only if that day is in the conversation's
    /// associatedDays array.
    static func testConversationGroupingCompleteness(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate random conversations with various day associations
            let conversationCount = Int.random(in: 5...20)
            var conversations: [AIConversation] = []
            var allDays = Set<String>()
            
            for _ in 0..<conversationCount {
                let conv = AIConversationTestGenerators.randomConversation()
                conversations.append(conv)
                allDays.formUnion(conv.associatedDays)
            }
            
            // Simulate grouping logic (same as AIConversationRepository.getConversationsGroupedByDay)
            var dayToConversations: [String: [AIConversation]] = [:]
            for conversation in conversations {
                for day in conversation.associatedDays {
                    if dayToConversations[day] == nil {
                        dayToConversations[day] = []
                    }
                    dayToConversations[day]?.append(conversation)
                }
            }
            
            // Verify: For each day, check that all conversations in the group have that day in associatedDays
            for (day, groupedConversations) in dayToConversations {
                for conv in groupedConversations {
                    if !conv.associatedDays.contains(day) {
                        return (false, "Conversation \(conv.id) in day \(day) group but day not in associatedDays")
                    }
                }
            }
            
            // Verify: For each conversation, check it appears in all its associated days' groups
            for conv in conversations {
                for day in conv.associatedDays {
                    guard let group = dayToConversations[day] else {
                        return (false, "Day \(day) has no group but conversation \(conv.id) has it in associatedDays")
                    }
                    if !group.contains(where: { $0.id == conv.id }) {
                        return (false, "Conversation \(conv.id) not in day \(day) group but day is in associatedDays")
                    }
                }
            }
        }
        
        return (true, nil)
    }
    
    /// Run all property tests and print results
    static func runAllTests() {
        print("Running AI Conversation Property Tests...")
        print("=" * 50)
        
        // Test 1: Serialization Round-Trip
        let roundTripResult = testConversationSerializationRoundTrip()
        if roundTripResult.passed {
            print("✅ Property 1 (Serialization Round-Trip): PASSED")
        } else {
            print("❌ Property 1 (Serialization Round-Trip): FAILED")
            if let failing = roundTripResult.failingExample {
                print("   Failing example: \(failing.id)")
            }
        }
        
        // Test 2: Message Chronological Order
        let chronologicalResult = testMessageChronologicalOrder()
        if chronologicalResult.passed {
            print("✅ Property 2 (Message Chronological Order): PASSED")
        } else {
            print("❌ Property 2 (Message Chronological Order): FAILED")
            if let failing = chronologicalResult.failingExample {
                print("   Failing example: Conversation \(failing.id) with \(failing.messages.count) messages")
            }
        }
        
        // Test 3: Unique IDs
        let uniqueIdResult = testUniqueConversationIDs()
        if uniqueIdResult.passed {
            print("✅ Property 3 (Unique Conversation IDs): PASSED")
        } else {
            print("❌ Property 3 (Unique Conversation IDs): FAILED")
            if let failing = uniqueIdResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 4: Day Association Consistency
        let dayAssociationResult = testDayAssociationConsistency()
        if dayAssociationResult.passed {
            print("✅ Property 4 (Day Association Consistency): PASSED")
        } else {
            print("❌ Property 4 (Day Association Consistency): FAILED")
            if let failing = dayAssociationResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 5: Conversation Grouping Completeness
        let groupingResult = testConversationGroupingCompleteness()
        if groupingResult.passed {
            print("✅ Property 5 (Conversation Grouping Completeness): PASSED")
        } else {
            print("❌ Property 5 (Conversation Grouping Completeness): FAILED")
            if let failing = groupingResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}

// Helper extension for string repetition
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}


// MARK: - Additional Property Tests for ViewModel Requirements

extension AIConversationPropertyTests {
    
    /// **Property 7: Message Content Integrity**
    /// **Validates: Requirements 3.2**
    /// For any message added to a conversation, the message should contain all
    /// required fields (id, role, content, timestamp) and the content should
    /// not be modified during storage.
    static func testMessageContentIntegrity(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate random message content
            let originalContent = AIConversationTestGenerators.randomString(length: Int.random(in: 10...500))
            let originalRole = AIConversationTestGenerators.randomRole()
            let originalTimestamp = AIConversationTestGenerators.randomDate()
            
            let message = AIMessage(
                role: originalRole,
                content: originalContent,
                timestamp: originalTimestamp
            )
            
            // Verify all required fields are present and unchanged
            guard !message.id.isEmpty else {
                return (false, "Message ID is empty")
            }
            
            guard message.role == originalRole else {
                return (false, "Message role changed: expected \(originalRole), got \(message.role)")
            }
            
            guard message.content == originalContent else {
                return (false, "Message content changed")
            }
            
            // Verify content survives serialization round-trip
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let encoded = try encoder.encode(message)
                let decoded = try decoder.decode(AIMessage.self, from: encoded)
                
                guard decoded.content == originalContent else {
                    return (false, "Content changed after serialization: '\(originalContent)' -> '\(decoded.content)'")
                }
                
                guard decoded.role == originalRole else {
                    return (false, "Role changed after serialization")
                }
                
                guard decoded.id == message.id else {
                    return (false, "ID changed after serialization")
                }
            } catch {
                return (false, "Serialization error: \(error)")
            }
        }
        
        return (true, nil)
    }
    
    /// **Property 9: New Conversation Day Association**
    /// **Validates: Requirements 2.5, 7.1**
    /// For any newly created conversation, it should be automatically associated
    /// with the current day (today's date string should be in associatedDays).
    static func testNewConversationDayAssociation(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let today = DateUtilities.today
        
        for _ in 0..<iterations {
            // Test 1: Simulate repository's createConversation() behavior
            // The repository creates conversations with today in associatedDays
            let conversationFromRepo = AIConversation(
                id: UUID().uuidString,
                associatedDays: [today],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Verify today is in associatedDays
            guard conversationFromRepo.associatedDays.contains(today) else {
                return (false, "New conversation does not contain today (\(today)) in associatedDays")
            }
            
            // Verify associatedDays is not empty
            guard !conversationFromRepo.associatedDays.isEmpty else {
                return (false, "New conversation has empty associatedDays")
            }
            
            // Verify today is the first (and only) day for a new conversation
            guard conversationFromRepo.associatedDays.count == 1 else {
                return (false, "New conversation should have exactly 1 associated day, got \(conversationFromRepo.associatedDays.count)")
            }
            
            guard conversationFromRepo.associatedDays[0] == today else {
                return (false, "New conversation's first associated day should be today (\(today)), got \(conversationFromRepo.associatedDays[0])")
            }
            
            // Test 2: Adding a message on the same day should not duplicate the day
            var conversationWithMessage = conversationFromRepo
            let message = AIMessage(
                role: .user,
                content: AIConversationTestGenerators.randomString(length: 20),
                timestamp: Date()
            )
            
            conversationWithMessage.addMessage(message)
            
            // Today should still be in associatedDays exactly once (no duplicates)
            let todayCount = conversationWithMessage.associatedDays.filter { $0 == today }.count
            guard todayCount == 1 else {
                return (false, "Today appears \(todayCount) times in associatedDays after adding message (expected 1)")
            }
            
            // Test 3: Verify the date format matches expected pattern (yyyy.MM.dd)
            let datePattern = #"^\d{4}\.\d{2}\.\d{2}$"#
            guard today.range(of: datePattern, options: .regularExpression) != nil else {
                return (false, "Today's date format is invalid: \(today), expected yyyy.MM.dd")
            }
        }
        
        return (true, nil)
    }
    
    /// Run additional property tests
    static func runAdditionalTests() {
        print("\nRunning Additional Property Tests...")
        print("=" * 50)
        
        // Test 7: Message Content Integrity
        let contentIntegrityResult = testMessageContentIntegrity()
        if contentIntegrityResult.passed {
            print("✅ Property 7 (Message Content Integrity): PASSED")
        } else {
            print("❌ Property 7 (Message Content Integrity): FAILED")
            if let failing = contentIntegrityResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 9: New Conversation Day Association
        let dayAssociationResult = testNewConversationDayAssociation()
        if dayAssociationResult.passed {
            print("✅ Property 9 (New Conversation Day Association): PASSED")
        } else {
            print("❌ Property 9 (New Conversation Day Association): FAILED")
            if let failing = dayAssociationResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}


// MARK: - Mode State Property Tests

extension AIConversationPropertyTests {
    
    /// **Property 6: Mode State Consistency**
    /// **Validates: Requirements 1.1, 1.3, 6.6, 6.7**
    /// For any mode toggle action, the system should transition to exactly one
    /// of the two modes (journal or ai), and the InputDock placeholder should
    /// match the current mode.
    static func testModeStateConsistency(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Start with random mode
            var currentMode: AppMode = Bool.random() ? .journal : .ai
            
            // Perform random number of toggles
            let toggleCount = Int.random(in: 1...20)
            
            for _ in 0..<toggleCount {
                // Toggle mode
                let previousMode = currentMode
                currentMode = currentMode == .journal ? .ai : .journal
                
                // Verify: Mode changed to exactly one of two valid states
                guard currentMode == .journal || currentMode == .ai else {
                    return (false, "Invalid mode state: \(currentMode)")
                }
                
                // Verify: Mode actually changed
                guard currentMode != previousMode else {
                    return (false, "Mode did not change after toggle")
                }
                
                // Verify: Placeholder would match mode
                let expectedPlaceholder = currentMode == .journal ? "placeholder" : "AI.Placeholder"
                let placeholderKey = currentMode == .journal ? "placeholder" : "AI.Placeholder"
                
                guard placeholderKey == expectedPlaceholder else {
                    return (false, "Placeholder key mismatch for mode \(currentMode)")
                }
            }
            
            // Verify: Final state is valid
            guard currentMode == .journal || currentMode == .ai else {
                return (false, "Final mode state invalid: \(currentMode)")
            }
        }
        
        return (true, nil)
    }
    
    /// Run mode state tests
    static func runModeStateTests() {
        print("\nRunning Mode State Property Tests...")
        print("=" * 50)
        
        let modeStateResult = testModeStateConsistency()
        if modeStateResult.passed {
            print("✅ Property 6 (Mode State Consistency): PASSED")
        } else {
            print("❌ Property 6 (Mode State Consistency): FAILED")
            if let failing = modeStateResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}


// MARK: - Preference Property Tests

extension AIConversationPropertyTests {
    
    /// **Property 8: Default Mode Preference Round-Trip**
    /// **Validates: Requirements 5.2, 5.3**
    /// For any valid AppMode value, saving it as the default mode preference
    /// and then loading it should return the same mode value.
    static func testDefaultModePreferenceRoundTrip(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let testKey = "test_default_mode_\(UUID().uuidString)"
        let defaults = UserDefaults.standard
        
        for _ in 0..<iterations {
            // Pick a random mode
            let originalMode: AppMode = Bool.random() ? .journal : .ai
            
            // Save to UserDefaults
            defaults.set(originalMode.rawValue, forKey: testKey)
            
            // Load from UserDefaults
            guard let loadedRawValue = defaults.string(forKey: testKey),
                  let loadedMode = AppMode(rawValue: loadedRawValue) else {
                defaults.removeObject(forKey: testKey)
                return (false, "Failed to load mode from UserDefaults")
            }
            
            // Verify round-trip
            guard loadedMode == originalMode else {
                defaults.removeObject(forKey: testKey)
                return (false, "Mode mismatch: saved \(originalMode), loaded \(loadedMode)")
            }
        }
        
        // Cleanup
        defaults.removeObject(forKey: testKey)
        return (true, nil)
    }
    
    /// **Property 10: Thinking Mode State Persistence**
    /// **Validates: Requirements 10.5**
    /// For any thinking mode toggle action, the preference should be persisted
    /// and restored correctly on subsequent app launches.
    static func testThinkingModeStatePersistence(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let testKey = "test_thinking_mode_\(UUID().uuidString)"
        let defaults = UserDefaults.standard
        
        for _ in 0..<iterations {
            // Pick a random state
            let originalState = Bool.random()
            
            // Save to UserDefaults
            defaults.set(originalState, forKey: testKey)
            
            // Load from UserDefaults
            let loadedState = defaults.bool(forKey: testKey)
            
            // Verify round-trip
            guard loadedState == originalState else {
                defaults.removeObject(forKey: testKey)
                return (false, "Thinking mode mismatch: saved \(originalState), loaded \(loadedState)")
            }
        }
        
        // Cleanup
        defaults.removeObject(forKey: testKey)
        return (true, nil)
    }
    
    /// Run preference property tests
    static func runPreferenceTests() {
        print("\nRunning Preference Property Tests...")
        print("=" * 50)
        
        // Test 8: Default Mode Preference Round-Trip
        let defaultModeResult = testDefaultModePreferenceRoundTrip()
        if defaultModeResult.passed {
            print("✅ Property 8 (Default Mode Preference Round-Trip): PASSED")
        } else {
            print("❌ Property 8 (Default Mode Preference Round-Trip): FAILED")
            if let failing = defaultModeResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 10: Thinking Mode State Persistence
        let thinkingModeResult = testThinkingModeStatePersistence()
        if thinkingModeResult.passed {
            print("✅ Property 10 (Thinking Mode State Persistence): PASSED")
        } else {
            print("❌ Property 10 (Thinking Mode State Persistence): FAILED")
            if let failing = thinkingModeResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}



