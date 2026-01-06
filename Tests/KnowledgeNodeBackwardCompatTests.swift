import Foundation

// MARK: - Property Tests for KnowledgeNode Backward Compatible Decoding
// Tests for migration from tracking.source.extractedFrom to node-level sourceLinks
// **Feature: swift-warnings-cleanup, Property 1: KnowledgeNode 向后兼容解码**

/// Property tests for KnowledgeNode backward compatibility
enum KnowledgeNodeBackwardCompatTests {
    
    // MARK: - Test Data Generators
    
    /// Generate a random SourceLink for testing
    static func generateRandomSourceLink() -> SourceLink {
        let sourceTypes = ["diary", "conversation", "tracker", "mindState"]
        let randomSourceType = sourceTypes.randomElement()!
        let randomId = UUID().uuidString
        let randomDayId = "2024-\(String(format: "%02d", Int.random(in: 1...12)))-\(String(format: "%02d", Int.random(in: 1...28)))"
        let randomSnippet = "Test snippet \(Int.random(in: 1...1000))"
        let randomScore = Double.random(in: 0.0...1.0)
        
        return SourceLink(
            id: randomId,
            sourceType: randomSourceType,
            sourceId: "source_\(UUID().uuidString)",
            dayId: randomDayId,
            snippet: randomSnippet,
            relevanceScore: randomScore,
            relatedEntityIds: [],
            extractedAt: Date()
        )
    }
    
    /// Generate random source links array
    static func generateRandomSourceLinks(count: Int) -> [SourceLink] {
        (0..<count).map { _ in generateRandomSourceLink() }
    }
    
    /// Create old format JSON with extractedFrom in tracking.source
    static func createOldFormatJSON(sourceLinks: [SourceLink]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // First encode the source links
        guard let sourceLinksData = try? encoder.encode(sourceLinks),
              let sourceLinksJSON = try? JSONSerialization.jsonObject(with: sourceLinksData) else {
            return nil
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        // Create old format JSON structure (without top-level sourceLinks)
        let oldFormatDict: [String: Any] = [
            "id": UUID().uuidString,
            "nodeType": "self.personality.trait",
            "nodeCategory": "common",
            "name": "Test Node \(Int.random(in: 1...1000))",
            "description": "A test node for backward compatibility",
            "tags": ["test", "backward-compat"],
            "attributes": [:],
            // Note: NO top-level sourceLinks field - this is the old format
            "tracking": [
                "source": [
                    "type": "aiExtracted",
                    "confidence": 0.85,
                    "extractedFrom": sourceLinksJSON  // Old location
                ],
                "timeline": [
                    "firstDiscovered": now,
                    "lastUpdated": now
                ],
                "verification": [
                    "confirmedByUser": false,
                    "needsReview": true
                ],
                "changeHistory": []
            ],
            "relations": [],
            "createdAt": now,
            "updatedAt": now
        ]
        
        return try? JSONSerialization.data(withJSONObject: oldFormatDict)
    }
    
    /// Create new format JSON with top-level sourceLinks
    static func createNewFormatJSON(sourceLinks: [SourceLink]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // First encode the source links
        guard let sourceLinksData = try? encoder.encode(sourceLinks),
              let sourceLinksJSON = try? JSONSerialization.jsonObject(with: sourceLinksData) else {
            return nil
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        // Create new format JSON structure (with top-level sourceLinks)
        let newFormatDict: [String: Any] = [
            "id": UUID().uuidString,
            "nodeType": "self.personality.trait",
            "contentType": "ai_tag",
            "nodeCategory": "common",
            "name": "Test Node \(Int.random(in: 1...1000))",
            "description": "A test node for new format",
            "tags": ["test", "new-format"],
            "attributes": [:],
            "sourceLinks": sourceLinksJSON,  // New location
            "relatedEntityIds": [],
            "tracking": [
                "source": [
                    "type": "aiExtracted",
                    "confidence": 0.85,
                    "extractedFrom": []  // Empty in new format
                ],
                "timeline": [
                    "firstDiscovered": now,
                    "lastUpdated": now
                ],
                "verification": [
                    "confirmedByUser": false,
                    "needsReview": true
                ],
                "changeHistory": []
            ],
            "relations": [],
            "createdAt": now,
            "updatedAt": now
        ]
        
        return try? JSONSerialization.data(withJSONObject: newFormatDict)
    }
    
    // MARK: - Property Tests
    
    /// Property 1: Old format migration preserves all source links
    /// *For any* valid old format KnowledgeNode JSON (containing tracking.source.extractedFrom
    /// but not top-level sourceLinks), the decoded KnowledgeNode's sourceLinks should contain
    /// all data from the original extractedFrom.
    /// **Validates: Requirements 2.2**
    static func testOldFormatMigrationPreservesSourceLinks(iterations: Int = 100) -> (passed: Bool, message: String, failingExample: String?) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for i in 0..<iterations {
            // Generate random source links (0 to 5)
            let linkCount = Int.random(in: 0...5)
            let originalLinks = generateRandomSourceLinks(count: linkCount)
            
            // Create old format JSON
            guard let jsonData = createOldFormatJSON(sourceLinks: originalLinks) else {
                return (false, "Failed to create old format JSON at iteration \(i)", nil)
            }
            
            // Decode
            do {
                let node = try decoder.decode(KnowledgeNode.self, from: jsonData)
                
                // Verify: sourceLinks should have same count as original
                if node.sourceLinks.count != originalLinks.count {
                    let failingExample = """
                    Iteration: \(i)
                    Original link count: \(originalLinks.count)
                    Decoded sourceLinks count: \(node.sourceLinks.count)
                    """
                    return (false, "Source link count mismatch after migration", failingExample)
                }
                
                // Verify: each original link ID should be present
                let originalIds = Set(originalLinks.map { $0.id })
                let decodedIds = Set(node.sourceLinks.map { $0.id })
                
                if originalIds != decodedIds {
                    let missing = originalIds.subtracting(decodedIds)
                    let failingExample = """
                    Iteration: \(i)
                    Missing IDs: \(missing)
                    Original IDs: \(originalIds)
                    Decoded IDs: \(decodedIds)
                    """
                    return (false, "Source link IDs don't match after migration", failingExample)
                }
                
            } catch {
                let failingExample = """
                Iteration: \(i)
                Error: \(error)
                JSON: \(String(data: jsonData, encoding: .utf8) ?? "N/A")
                """
                return (false, "Decoding failed: \(error)", failingExample)
            }
        }
        
        return (true, "Old format migration preserves all source links (\(iterations) iterations)", nil)
    }
    
    /// Property 2: New format decoding works correctly
    /// *For any* valid new format KnowledgeNode JSON (with top-level sourceLinks),
    /// the decoded KnowledgeNode's sourceLinks should match exactly.
    /// **Validates: Requirements 2.1**
    static func testNewFormatDecodingPreservesSourceLinks(iterations: Int = 100) -> (passed: Bool, message: String, failingExample: String?) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for i in 0..<iterations {
            // Generate random source links (0 to 5)
            let linkCount = Int.random(in: 0...5)
            let originalLinks = generateRandomSourceLinks(count: linkCount)
            
            // Create new format JSON
            guard let jsonData = createNewFormatJSON(sourceLinks: originalLinks) else {
                return (false, "Failed to create new format JSON at iteration \(i)", nil)
            }
            
            // Decode
            do {
                let node = try decoder.decode(KnowledgeNode.self, from: jsonData)
                
                // Verify: sourceLinks should have same count as original
                if node.sourceLinks.count != originalLinks.count {
                    let failingExample = """
                    Iteration: \(i)
                    Original link count: \(originalLinks.count)
                    Decoded sourceLinks count: \(node.sourceLinks.count)
                    """
                    return (false, "Source link count mismatch in new format", failingExample)
                }
                
                // Verify: each original link ID should be present
                let originalIds = Set(originalLinks.map { $0.id })
                let decodedIds = Set(node.sourceLinks.map { $0.id })
                
                if originalIds != decodedIds {
                    let missing = originalIds.subtracting(decodedIds)
                    let failingExample = """
                    Iteration: \(i)
                    Missing IDs: \(missing)
                    """
                    return (false, "Source link IDs don't match in new format", failingExample)
                }
                
            } catch {
                let failingExample = """
                Iteration: \(i)
                Error: \(error)
                """
                return (false, "Decoding failed: \(error)", failingExample)
            }
        }
        
        return (true, "New format decoding preserves all source links (\(iterations) iterations)", nil)
    }
    
    /// Property 3: Round-trip encoding/decoding preserves sourceLinks
    /// *For any* KnowledgeNode, encoding then decoding should preserve sourceLinks.
    /// **Validates: Requirements 2.2**
    static func testRoundTripPreservesSourceLinks(iterations: Int = 100) -> (passed: Bool, message: String, failingExample: String?) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for i in 0..<iterations {
            // Generate random source links
            let linkCount = Int.random(in: 0...5)
            let sourceLinks = generateRandomSourceLinks(count: linkCount)
            
            // Create a KnowledgeNode with sourceLinks
            let originalNode = KnowledgeNode(
                id: UUID().uuidString,
                nodeType: "self.personality.trait",
                contentType: .aiTag,
                nodeCategory: .common,
                name: "Test Node \(i)",
                description: "Round-trip test node",
                tags: ["test"],
                attributes: [:],
                sourceLinks: sourceLinks,
                relatedEntityIds: [],
                tracking: NodeTracking(
                    source: NodeSource(type: .aiExtracted, confidence: 0.85),
                    verification: NodeVerification(needsReview: true)
                ),
                relations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Encode
            guard let jsonData = try? encoder.encode(originalNode) else {
                return (false, "Failed to encode node at iteration \(i)", nil)
            }
            
            // Decode
            do {
                let decodedNode = try decoder.decode(KnowledgeNode.self, from: jsonData)
                
                // Verify: sourceLinks count should match
                if decodedNode.sourceLinks.count != originalNode.sourceLinks.count {
                    let failingExample = """
                    Iteration: \(i)
                    Original count: \(originalNode.sourceLinks.count)
                    Decoded count: \(decodedNode.sourceLinks.count)
                    """
                    return (false, "Source link count mismatch in round-trip", failingExample)
                }
                
                // Verify: IDs should match
                let originalIds = Set(originalNode.sourceLinks.map { $0.id })
                let decodedIds = Set(decodedNode.sourceLinks.map { $0.id })
                
                if originalIds != decodedIds {
                    let failingExample = """
                    Iteration: \(i)
                    Original IDs: \(originalIds)
                    Decoded IDs: \(decodedIds)
                    """
                    return (false, "Source link IDs don't match in round-trip", failingExample)
                }
                
            } catch {
                let failingExample = """
                Iteration: \(i)
                Error: \(error)
                """
                return (false, "Round-trip decoding failed: \(error)", failingExample)
            }
        }
        
        return (true, "Round-trip encoding/decoding preserves sourceLinks (\(iterations) iterations)", nil)
    }
    
    // MARK: - Run All Tests
    
    static func runAllTests() {
        print("Running KnowledgeNode Backward Compatibility Property Tests...")
        print("**Feature: swift-warnings-cleanup, Property 1: KnowledgeNode 向后兼容解码**")
        print("=" * 70)
        
        let tests: [(String, () -> (passed: Bool, message: String, failingExample: String?))] = [
            ("Property 1: Old format migration preserves source links", { testOldFormatMigrationPreservesSourceLinks(iterations: 100) }),
            ("Property 2: New format decoding preserves source links", { testNewFormatDecodingPreservesSourceLinks(iterations: 100) }),
            ("Property 3: Round-trip preserves source links", { testRoundTripPreservesSourceLinks(iterations: 100) })
        ]
        
        var passedCount = 0
        var failedCount = 0
        
        for (name, test) in tests {
            let result = test()
            if result.passed {
                print("✅ \(name): PASSED - \(result.message)")
                passedCount += 1
            } else {
                print("❌ \(name): FAILED - \(result.message)")
                if let failingExample = result.failingExample {
                    print("   Failing example:")
                    for line in failingExample.split(separator: "\n") {
                        print("   \(line)")
                    }
                }
                failedCount += 1
            }
        }
        
        print("=" * 70)
        print("Results: \(passedCount) passed, \(failedCount) failed")
        print("=" * 70)
    }
}

// Helper extension for string repetition
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
