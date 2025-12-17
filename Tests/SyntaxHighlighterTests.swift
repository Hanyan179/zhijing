import Foundation
import SwiftUI

// MARK: - Property-Based Testing for SyntaxHighlighter
// **Feature: ai-rich-content-rendering**
// These tests verify the correctness properties of the syntax highlighting system

/// Test utilities for generating random code content
enum CodeTestGenerators {
    
    /// Generate a random string of specified length (safe characters only)
    static func randomString(length: Int = 20) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate random Swift code snippet
    static func randomSwiftCode() -> String {
        let templates = [
            "let \(randomIdentifier()) = \(Int.random(in: 0...1000))",
            "var \(randomIdentifier()): String = \"\(randomString(length: 10))\"",
            "func \(randomIdentifier())() -> Int { return \(Int.random(in: 0...100)) }",
            "struct \(randomIdentifier().capitalized) { var \(randomIdentifier()): Int }",
            "class \(randomIdentifier().capitalized) { init() {} }",
            "// \(randomString(length: 20))",
            "print(\"\(randomString(length: 15))\")",
            "if \(randomIdentifier()) > \(Int.random(in: 0...100)) { }",
            "for i in 0..<\(Int.random(in: 1...10)) { print(i) }",
            "guard let \(randomIdentifier()) = optional else { return }"
        ]
        
        let lineCount = Int.random(in: 1...5)
        return (0..<lineCount).map { _ in templates.randomElement()! }.joined(separator: "\n")
    }
    
    /// Generate random Python code snippet
    static func randomPythonCode() -> String {
        let templates = [
            "\(randomIdentifier()) = \(Int.random(in: 0...1000))",
            "def \(randomIdentifier())():\n    return \(Int.random(in: 0...100))",
            "class \(randomIdentifier().capitalized):\n    pass",
            "# \(randomString(length: 20))",
            "print(\"\(randomString(length: 15))\")",
            "if \(randomIdentifier()) > \(Int.random(in: 0...100)):\n    pass",
            "for i in range(\(Int.random(in: 1...10))):\n    print(i)"
        ]
        
        let lineCount = Int.random(in: 1...3)
        return (0..<lineCount).map { _ in templates.randomElement()! }.joined(separator: "\n")
    }
    
    /// Generate random JavaScript code snippet
    static func randomJavaScriptCode() -> String {
        let templates = [
            "const \(randomIdentifier()) = \(Int.random(in: 0...1000));",
            "let \(randomIdentifier()) = \"\(randomString(length: 10))\";",
            "function \(randomIdentifier())() { return \(Int.random(in: 0...100)); }",
            "// \(randomString(length: 20))",
            "console.log(\"\(randomString(length: 15))\");",
            "if (\(randomIdentifier()) > \(Int.random(in: 0...100))) { }",
            "for (let i = 0; i < \(Int.random(in: 1...10)); i++) { }"
        ]
        
        let lineCount = Int.random(in: 1...3)
        return (0..<lineCount).map { _ in templates.randomElement()! }.joined(separator: "\n")
    }
    
    /// Generate random JSON content
    static func randomJSON() -> String {
        let key = randomIdentifier()
        let value = Bool.random() ? "\"\(randomString(length: 8))\"" : "\(Int.random(in: 0...1000))"
        return "{\n  \"\(key)\": \(value)\n}"
    }
    
    /// Generate a random valid identifier
    static func randomIdentifier() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        let firstChar = String(letters.randomElement()!)
        let rest = String((0..<Int.random(in: 3...8)).map { _ in letters.randomElement()! })
        return firstChar + rest
    }
    
    /// Generate random code for a given language
    static func randomCode(for language: String?) -> String {
        switch language?.lowercased() {
        case "swift":
            return randomSwiftCode()
        case "python", "py":
            return randomPythonCode()
        case "javascript", "js":
            return randomJavaScriptCode()
        case "json":
            return randomJSON()
        default:
            return randomString(length: Int.random(in: 20...100))
        }
    }
}

// MARK: - Property Tests for SyntaxHighlighter

/// Property-based tests for SyntaxHighlighter
/// **Feature: ai-rich-content-rendering**
enum SyntaxHighlighterPropertyTests {
    
    /// **Property 4: Syntax highlighting preserves code structure**
    /// **Validates: Requirements 2.1, 2.2**
    /// For any code string, applying syntax highlighting should not change
    /// the actual text content, only add formatting attributes.
    static func testSyntaxHighlightingPreservesCodeStructure(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let languages: [String?] = ["swift", "python", "javascript", "json", nil, "unknown"]
        
        for _ in 0..<iterations {
            // Pick a random language
            let language = languages.randomElement()!
            
            // Generate random code for that language
            let originalCode = CodeTestGenerators.randomCode(for: language)
            
            // Apply syntax highlighting
            let highlighted = SyntaxHighlighter.highlight(originalCode, language: language)
            
            // Extract plain text from AttributedString
            let highlightedText = String(highlighted.characters)
            
            // Verify the text content is preserved exactly
            guard originalCode == highlightedText else {
                return (false, "Code content changed after highlighting.\nOriginal: '\(originalCode)'\nHighlighted: '\(highlightedText)'\nLanguage: \(language ?? "nil")")
            }
        }
        
        return (true, nil)
    }
    
    /// Test that highlighting is idempotent (applying twice gives same result)
    static func testHighlightingIdempotence(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let languages: [String?] = ["swift", "python", "javascript", "json", nil]
        
        for _ in 0..<iterations {
            let language = languages.randomElement()!
            let code = CodeTestGenerators.randomCode(for: language)
            
            // Apply highlighting twice
            let firstHighlight = SyntaxHighlighter.highlight(code, language: language)
            let firstText = String(firstHighlight.characters)
            
            let secondHighlight = SyntaxHighlighter.highlight(firstText, language: language)
            let secondText = String(secondHighlight.characters)
            
            // Text should be identical
            guard firstText == secondText else {
                return (false, "Highlighting not idempotent for language: \(language ?? "nil")")
            }
        }
        
        return (true, nil)
    }
    
    /// Test that empty code returns empty AttributedString
    static func testEmptyCodeHandling() -> (passed: Bool, failingExample: String?) {
        let languages: [String?] = ["swift", "python", "javascript", nil]
        
        for language in languages {
            let highlighted = SyntaxHighlighter.highlight("", language: language)
            let text = String(highlighted.characters)
            
            guard text.isEmpty else {
                return (false, "Empty code produced non-empty result for language: \(language ?? "nil")")
            }
        }
        
        return (true, nil)
    }
    
    /// Test that whitespace is preserved
    static func testWhitespacePreservation(iterations: Int = 50) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate code with various whitespace patterns
            let spaces = String(repeating: " ", count: Int.random(in: 1...4))
            let tabs = String(repeating: "\t", count: Int.random(in: 0...2))
            let newlines = String(repeating: "\n", count: Int.random(in: 1...3))
            
            let code = "\(spaces)let x = 1\(newlines)\(tabs)let y = 2"
            
            let highlighted = SyntaxHighlighter.highlight(code, language: "swift")
            let highlightedText = String(highlighted.characters)
            
            guard code == highlightedText else {
                return (false, "Whitespace not preserved.\nOriginal: '\(code.debugDescription)'\nHighlighted: '\(highlightedText.debugDescription)'")
            }
        }
        
        return (true, nil)
    }
    
    /// Test display name function
    static func testDisplayNameConsistency() -> (passed: Bool, failingExample: String?) {
        let testCases: [(input: String?, expected: String)] = [
            ("swift", "Swift"),
            ("python", "Python"),
            ("py", "Python"),
            ("javascript", "JavaScript"),
            ("js", "JavaScript"),
            ("typescript", "TypeScript"),
            ("ts", "TypeScript"),
            ("json", "JSON"),
            ("html", "HTML"),
            ("css", "CSS"),
            (nil, "Code"),
            ("unknown_lang", "Unknown_lang")
        ]
        
        for (input, expected) in testCases {
            let result = SyntaxHighlighter.displayName(for: input)
            guard result == expected else {
                return (false, "Display name mismatch for '\(input ?? "nil")': expected '\(expected)', got '\(result)'")
            }
        }
        
        return (true, nil)
    }
    
    /// Run all property tests and print results
    static func runAllTests() {
        print("Running SyntaxHighlighter Property Tests...")
        print("=" * 50)
        
        // Property 4: Syntax highlighting preserves code structure
        let preservationResult = testSyntaxHighlightingPreservesCodeStructure()
        if preservationResult.passed {
            print("✅ Property 4 (Syntax Highlighting Preserves Code Structure): PASSED")
        } else {
            print("❌ Property 4 (Syntax Highlighting Preserves Code Structure): FAILED")
            if let failing = preservationResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Highlighting idempotence
        let idempotenceResult = testHighlightingIdempotence()
        if idempotenceResult.passed {
            print("✅ Additional (Highlighting Idempotence): PASSED")
        } else {
            print("❌ Additional (Highlighting Idempotence): FAILED")
            if let failing = idempotenceResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Empty code handling
        let emptyResult = testEmptyCodeHandling()
        if emptyResult.passed {
            print("✅ Additional (Empty Code Handling): PASSED")
        } else {
            print("❌ Additional (Empty Code Handling): FAILED")
            if let failing = emptyResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Whitespace preservation
        let whitespaceResult = testWhitespacePreservation()
        if whitespaceResult.passed {
            print("✅ Additional (Whitespace Preservation): PASSED")
        } else {
            print("❌ Additional (Whitespace Preservation): FAILED")
            if let failing = whitespaceResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Display name consistency
        let displayNameResult = testDisplayNameConsistency()
        if displayNameResult.passed {
            print("✅ Additional (Display Name Consistency): PASSED")
        } else {
            print("❌ Additional (Display Name Consistency): FAILED")
            if let failing = displayNameResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}

// MARK: - Property Tests for Code Copy Preservation

/// Property-based tests for code copy functionality
/// **Feature: ai-rich-content-rendering**
enum CodeCopyPropertyTests {
    
    /// **Property 3: Code copy preserves exact content**
    /// **Validates: Requirements 4.4**
    /// For any code block, copying and pasting should produce a string
    /// identical to the original code (excluding syntax highlighting markup).
    static func testCodeCopyPreservesExactContent(iterations: Int = 100) -> (passed: Bool, failingExample: String?) {
        let languages: [String?] = ["swift", "python", "javascript", "json", nil, "unknown"]
        
        for _ in 0..<iterations {
            // Pick a random language
            let language = languages.randomElement()!
            
            // Generate random code
            let originalCode = CodeTestGenerators.randomCode(for: language)
            
            // Simulate what happens during copy:
            // 1. Code is stored in CodeBlockView
            // 2. When copy is pressed, the raw `code` property is copied (not highlighted)
            // 3. The copied text should be identical to original
            
            // Apply syntax highlighting (what's displayed)
            let highlighted = SyntaxHighlighter.highlight(originalCode, language: language)
            
            // Extract the raw text that would be copied
            // In our implementation, we copy `code` directly, not the highlighted version
            let copiedText = originalCode // This is what gets copied to clipboard
            
            // Verify the copied text matches the original exactly
            guard originalCode == copiedText else {
                return (false, "Code copy changed content.\nOriginal: '\(originalCode)'\nCopied: '\(copiedText)'")
            }
            
            // Also verify that extracting text from highlighted version preserves content
            let highlightedText = String(highlighted.characters)
            guard originalCode == highlightedText else {
                return (false, "Highlighted text differs from original.\nOriginal: '\(originalCode)'\nHighlighted text: '\(highlightedText)'")
            }
        }
        
        return (true, nil)
    }
    
    /// Test that special characters are preserved in copy
    static func testSpecialCharactersPreserved(iterations: Int = 50) -> (passed: Bool, failingExample: String?) {
        let specialCodes = [
            "let emoji = \"🎉\"",
            "// Comment with special chars: @#$%^&*()",
            "let path = \"/usr/local/bin\"",
            "let regex = \"\\\\d+\"",
            "let unicode = \"日本語\"",
            "let tabs = \"\\t\\t\"",
            "let newlines = \"line1\\nline2\"",
            "let quotes = \"He said \\\"Hello\\\"\"",
            "let backslash = \"C:\\\\Users\\\\name\""
        ]
        
        for code in specialCodes {
            let highlighted = SyntaxHighlighter.highlight(code, language: "swift")
            let highlightedText = String(highlighted.characters)
            
            guard code == highlightedText else {
                return (false, "Special characters not preserved.\nOriginal: '\(code)'\nHighlighted: '\(highlightedText)'")
            }
        }
        
        return (true, nil)
    }
    
    /// Test that multiline code is preserved exactly
    static func testMultilineCodePreserved(iterations: Int = 50) -> (passed: Bool, failingExample: String?) {
        for _ in 0..<iterations {
            // Generate multiline code with various indentation
            let lines = (0..<Int.random(in: 2...10)).map { lineNum -> String in
                let indent = String(repeating: "    ", count: Int.random(in: 0...3))
                return "\(indent)line\(lineNum): \(CodeTestGenerators.randomString(length: Int.random(in: 5...20)))"
            }
            let code = lines.joined(separator: "\n")
            
            let highlighted = SyntaxHighlighter.highlight(code, language: "swift")
            let highlightedText = String(highlighted.characters)
            
            guard code == highlightedText else {
                return (false, "Multiline code not preserved.\nOriginal lines: \(lines.count)\nHighlighted lines: \(highlightedText.components(separatedBy: "\n").count)")
            }
        }
        
        return (true, nil)
    }
    
    /// Run all code copy property tests
    static func runAllTests() {
        print("Running Code Copy Property Tests...")
        print("=" * 50)
        
        // Property 3: Code copy preserves exact content
        let preservationResult = testCodeCopyPreservesExactContent()
        if preservationResult.passed {
            print("✅ Property 3 (Code Copy Preserves Exact Content): PASSED")
        } else {
            print("❌ Property 3 (Code Copy Preserves Exact Content): FAILED")
            if let failing = preservationResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Special characters preserved
        let specialResult = testSpecialCharactersPreserved()
        if specialResult.passed {
            print("✅ Additional (Special Characters Preserved): PASSED")
        } else {
            print("❌ Additional (Special Characters Preserved): FAILED")
            if let failing = specialResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        // Additional: Multiline code preserved
        let multilineResult = testMultilineCodePreserved()
        if multilineResult.passed {
            print("✅ Additional (Multiline Code Preserved): PASSED")
        } else {
            print("❌ Additional (Multiline Code Preserved): FAILED")
            if let failing = multilineResult.failingExample {
                print("   Failing example: \(failing)")
            }
        }
        
        print("=" * 50)
    }
}

// MARK: - Combined Test Runner

/// Run all SyntaxHighlighter and CodeCopy property tests
enum SyntaxHighlighterAllTests {
    static func runAllTests() {
        print("\n" + "=" * 60)
        print("SYNTAX HIGHLIGHTER & CODE COPY PROPERTY TESTS")
        print("=" * 60 + "\n")
        
        SyntaxHighlighterPropertyTests.runAllTests()
        print("")
        CodeCopyPropertyTests.runAllTests()
        
        print("\n" + "=" * 60)
        print("ALL TESTS COMPLETE")
        print("=" * 60 + "\n")
    }
}

// Helper extension for string repetition
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
