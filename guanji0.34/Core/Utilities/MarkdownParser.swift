import Foundation
import Markdown

/// Wrapper around swift-markdown library with streaming support
/// Provides parsing functionality for Markdown content in AI responses
/// All methods are nonisolated to allow calling from any actor context
public enum MarkdownParser {
    
    /// Parse Markdown string using swift-markdown
    /// - Parameter markdown: The Markdown string to parse
    /// - Returns: A parsed Document AST
    nonisolated public static func parse(_ markdown: String) -> Document {
        return Document(parsing: markdown)
    }
    
    /// Parse incrementally for streaming (handles incomplete syntax)
    /// - Parameter markdown: The Markdown string to parse
    /// - Returns: Tuple of parsed document and flag indicating if syntax is complete
    nonisolated public static func parseIncremental(_ markdown: String) -> (document: Document, isComplete: Bool) {
        let isComplete = !hasIncompleteSyntax(markdown)
        let doc = Document(parsing: markdown)
        return (doc, isComplete)
    }
    
    /// Check if the Markdown string has incomplete syntax
    /// - Parameter text: The text to check
    /// - Returns: True if there is incomplete syntax (e.g., unclosed code blocks)
    nonisolated public static func hasIncompleteSyntax(_ text: String) -> Bool {
        // Check for unclosed code blocks (odd number of ```)
        let codeBlockDelimiters = text.components(separatedBy: "```")
        let codeBlockCount = codeBlockDelimiters.count - 1
        if codeBlockCount % 2 != 0 {
            return true
        }
        
        // Check for unclosed inline code (odd number of single backticks not part of ```)
        // First, remove all ``` to avoid counting them
        let withoutCodeBlocks = text.replacingOccurrences(of: "```", with: "")
        let backtickCount = withoutCodeBlocks.filter { $0 == "`" }.count
        if backtickCount % 2 != 0 {
            return true
        }
        
        return false
    }
}
