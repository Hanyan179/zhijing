import Foundation
import Markdown

// MARK: - Property-Based Testing for MarkdownParser
// **Feature: ai-rich-content-rendering**
// These tests verify the correctness properties of the Markdown parsing system

/// Test utilities for generating random Markdown content
enum MarkdownTestGenerators {
    
    /// Generate a random string of specified length
    static func randomString(length: Int = 20) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate a random heading (# to ######)
    static func randomHeading() -> String {
        let level = Int.random(in: 1...6)
        let hashes = String(repeating: "#", count: level)
        return "\(hashes) \(randomString(length: Int.random(in: 5...30)))"
    }
    
    /// Generate a random bullet list
    static func randomBulletList(itemCount: Int = 3) -> String {
        let items = (0..<itemCount).map { _ in "- \(randomString(length: Int.random(in: 5...20)))" }
        return items.joined(separator: "\n")
    }
    
    /// Generate a random numbered list
    static func randomNumberedList(itemCount: Int = 3) -> String {
        let items = (0..<itemCount).enumerated().map { index, _ in 
            "\(index + 1). \(randomString(length: Int.random(in: 5...20)))" 
        }
        return items.joined(separator: "\n")
    }
    
    /// Generate a random code block with complete syntax
    static func randomCodeBlock() -> String {
        let languages = ["swift", "python", "javascript", "json", ""]
        let language = languages.randomElement()!
        let codeLines = (0..<Int.random(in: 1...5)).map { _ in 
            "    \(randomString(length: Int.random(in: 10...40)))" 
        }
        return "```\(language)\n\(codeLines.joined(separator: "\n"))\n```"
    }
    
    /// Generate a random inline code
    static func randomInlineCode() -> String {
        return "`\(randomString(length: Int.random(in: 3...15)))`"
    }
    
    /// Generate a random block quote
    static func randomBlockQuote() -> String {
        let lines = (0..<Int.random(in: 1...3)).map { _ in 
            "> \(randomString(length: Int.random(in: 10...40)))" 
        }
        return lines.joined(separator: "\n")
    }
    
    /// Generate random bold text
    static func randomBold() -> String {
        return "**\(randomString(length: Int.random(in: 3...15)))**"
    }
    
    /// Generate random italic text
    static func randomItalic() -> String {
        return "*\(randomString(length: Int.random(in: 3...15)))*"
    }
    
    /// Generate a random link
    static func randomLink() -> String {
        return "[\(randomString(length: Int.random(in: 3...15)))](https://example.com/\(randomString(length: 5)))"
    }
    
    /// Generate a complete valid Markdown document
    static func randomCompleteMarkdown() -> String {
        var parts: [String] = []
        
        // Add random elements
        let elementCount = Int.random(in: 2...8)
        for _ in 0..<elementCount {
            let elementType = Int.random(in: 0...8)
            switch elementType {
            case 0: parts.append(randomHeading())
            case 1: parts.append(randomString(length: Int.random(in: 20...100)))
            case 2: parts.append(randomBulletList(itemCount: Int.random(in: 2...5)))
            case 3: parts.append(randomNumberedList(itemCount: Int.random(in: 2...5)))
            case 4: parts.append(randomCodeBlock())
            case 5: parts.append(randomBlockQuote())
            case 6: parts.append("Some text with \(randomBold()) and \(randomItalic()) formatting.")
            case 7: parts.append("Check out this \(randomLink()) for more info.")
            default: parts.append(randomString(length: Int.random(in: 10...50)))
            }
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    /// Generate Markdown with incomplete code block (for testing streaming)
    static func randomIncompleteCodeBlock() -> String {
        let language = ["swift", "python", "javascript"].randomElement()!
        let code = randomString(length: Int.random(in: 10...50))
        // Missing closing ```
        return "```\(language)\n\(code)"
    }
    
    /// Generate Markdown with incomplete inline code
    static func randomIncompleteInlineCode() -> String {
        return "Some text with `incomplete code"
    }
}


// MARK: - Property Tests for MarkdownParser

/// Property-based tests for MarkdownParser
/// **Feature: ai-rich-content-rendering**
enum MarkdownParserPropertyTests {
    
    /// **Property 1: Markdown parsing is idempotent for complete syntax**
    /// **Validates: Requirements 1.1-1.9**
    /// For any valid Markdown string with complete syntax, parsing it multiple
    /// times should produce identical AST structures.
    static func testMarkdownParsingIdempotence(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate random complete Markdown
            let markdown = MarkdownTestGenerators.randomCompleteMarkdown()
            
            // Parse multiple times
            let firstParse = MarkdownParser.parse(markdown)
            let secondParse = MarkdownParser.parse(markdown)
            let thirdParse = MarkdownParser.parse(markdown)
            
            // Convert to debug strings for comparison
            let firstDebug = firstParse.debugDescription()
            let secondDebug = secondParse.debugDescription()
            let thirdDebug = thirdParse.debugDescription()
            
            // Verify idempotence
            guard firstDebug == secondDebug else {
                return (false, "First and second parse differ for: \(markdown.prefix(100))...")
            }
            
            guard secondDebug == thirdDebug else {
                return (false, "Second and third parse differ for: \(markdown.prefix(100))...")
            }
            
            // Also verify child count is consistent
            guard firstParse.childCount == secondParse.childCount,
                  secondParse.childCount == thirdParse.childCount else {
                return (false, "Child count differs across parses for: \(markdown.prefix(100))...")
            }
        }
        
        return (true, nil)
    }
    
    /// **Property 2: Incremental parsing converges to complete parsing**
    /// **Validates: Requirements 3.1, 3.2, 3.3**
    /// For any Markdown string, the result of incremental parsing on the
    /// complete string should equal the result of complete parsing.
    static func testIncrementalParsingConvergence(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate random complete Markdown
            let markdown = MarkdownTestGenerators.randomCompleteMarkdown()
            
            // Parse using both methods
            let completeParse = MarkdownParser.parse(markdown)
            let (incrementalParse, isComplete) = MarkdownParser.parseIncremental(markdown)
            
            // For complete syntax, isComplete should be true
            guard isComplete else {
                // Check if it's actually incomplete
                if !MarkdownParser.hasIncompleteSyntax(markdown) {
                    return (false, "Complete markdown marked as incomplete: \(markdown.prefix(100))...")
                }
                // If it has incomplete syntax, that's expected - skip this iteration
                continue
            }
            
            // Compare AST structures
            let completeDebug = completeParse.debugDescription()
            let incrementalDebug = incrementalParse.debugDescription()
            
            guard completeDebug == incrementalDebug else {
                return (false, "Complete and incremental parse differ for: \(markdown.prefix(100))...")
            }
            
            // Verify child counts match
            guard completeParse.childCount == incrementalParse.childCount else {
                return (false, "Child count differs: complete=\(completeParse.childCount), incremental=\(incrementalParse.childCount)")
            }
        }
        
        return (true, nil)
    }
    
    /// Additional test: Verify incomplete syntax detection
    /// This tests the hasIncompleteSyntax helper function
    static func testIncompleteSyntaxDetection(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Test 1: Complete code blocks should be detected as complete
            let completeCodeBlock = MarkdownTestGenerators.randomCodeBlock()
            if MarkdownParser.hasIncompleteSyntax(completeCodeBlock) {
                return (false, "Complete code block marked as incomplete: \(completeCodeBlock)")
            }
            
            // Test 2: Incomplete code blocks should be detected as incomplete
            let incompleteCodeBlock = MarkdownTestGenerators.randomIncompleteCodeBlock()
            if !MarkdownParser.hasIncompleteSyntax(incompleteCodeBlock) {
                return (false, "Incomplete code block marked as complete: \(incompleteCodeBlock)")
            }
            
            // Test 3: Complete inline code should be detected as complete
            let completeInline = MarkdownTestGenerators.randomInlineCode()
            if MarkdownParser.hasIncompleteSyntax(completeInline) {
                return (false, "Complete inline code marked as incomplete: \(completeInline)")
            }
            
            // Test 4: Incomplete inline code should be detected as incomplete
            let incompleteInline = MarkdownTestGenerators.randomIncompleteInlineCode()
            if !MarkdownParser.hasIncompleteSyntax(incompleteInline) {
                return (false, "Incomplete inline code marked as complete: \(incompleteInline)")
            }
            
            // Test 5: Plain text should be complete
            let plainText = MarkdownTestGenerators.randomString(length: Int.random(in: 10...100))
            if MarkdownParser.hasIncompleteSyntax(plainText) {
                return (false, "Plain text marked as incomplete: \(plainText)")
            }
        }
        
        return (true, nil)
    }
    
    /// Test streaming simulation: parsing progressively longer prefixes
    static func testStreamingParsingBehavior(iterations: Int = 50) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate a complete markdown document
            let fullMarkdown = MarkdownTestGenerators.randomCompleteMarkdown()
            
            // Simulate streaming by parsing progressively longer prefixes
            var lastChildCount = 0
            var lastWasComplete = false
            
            // Parse at various points (25%, 50%, 75%, 100%)
            let checkpoints = [0.25, 0.5, 0.75, 1.0]
            
            for checkpoint in checkpoints {
                let endIndex = Int(Double(fullMarkdown.count) * checkpoint)
                let prefix = String(fullMarkdown.prefix(endIndex))
                
                let (doc, isComplete) = MarkdownParser.parseIncremental(prefix)
                
                // At 100%, if the original was complete, this should be complete
                if checkpoint == 1.0 && !MarkdownParser.hasIncompleteSyntax(fullMarkdown) {
                    guard isComplete else {
                        return (false, "Full document marked as incomplete: \(fullMarkdown.prefix(100))...")
                    }
                }
                
                // Child count should generally be non-decreasing as we add more content
                // (though this isn't strictly guaranteed due to how markdown parsing works)
                let currentChildCount = doc.childCount
                
                // Store for next iteration
                lastChildCount = currentChildCount
                lastWasComplete = isComplete
            }
            
            // Final parse should match complete parse
            let finalParse = MarkdownParser.parse(fullMarkdown)
            let (incrementalFinal, _) = MarkdownParser.parseIncremental(fullMarkdown)
            
            guard finalParse.childCount == incrementalFinal.childCount else {
                return (false, "Final child count mismatch: parse=\(finalParse.childCount), incremental=\(incrementalFinal.childCount)")
            }
        }
        
        return (true, nil)
    }
    
    /// Run all property tests and print results
    static func runAllTests() {
        print("Running MarkdownParser Property Tests...")
        print("=" * 50)
        
        // Test 1: Parsing Idempotence
        let idempotenceResult = testMarkdownParsingIdempotence()
        if idempotenceResult.passed {
            print("✅ Property 1 (Markdown Parsing Idempotence): PASSED")
        } else {
            print("❌ Property 1 (Markdown Parsing Idempotence): FAILED")
            if let failing = idempotenceResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Test 2: Incremental Parsing Convergence
        let convergenceResult = testIncrementalParsingConvergence()
        if convergenceResult.passed {
            print("✅ Property 2 (Incremental Parsing Convergence): PASSED")
        } else {
            print("❌ Property 2 (Incremental Parsing Convergence): FAILED")
            if let failing = convergenceResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Incomplete Syntax Detection
        let syntaxDetectionResult = testIncompleteSyntaxDetection()
        if syntaxDetectionResult.passed {
            print("✅ Additional (Incomplete Syntax Detection): PASSED")
        } else {
            print("❌ Additional (Incomplete Syntax Detection): FAILED")
            if let failing = syntaxDetectionResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Streaming Parsing Behavior
        let streamingResult = testStreamingParsingBehavior()
        if streamingResult.passed {
            print("✅ Additional (Streaming Parsing Behavior): PASSED")
        } else {
            print("❌ Additional (Streaming Parsing Behavior): FAILED")
            if let failing = streamingResult.failingExample {
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
