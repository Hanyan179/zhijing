import Foundation
import SwiftUI
import Splash

/// Syntax highlighter for code blocks using Splash library
/// Provides syntax highlighting for Swift and basic highlighting for other languages
public enum SyntaxHighlighter {
    
    // MARK: - Theme Configuration
    
    /// Custom theme matching Guanji design system
    private static var guanjiTheme: Splash.Theme {
        return Theme(
            font: Font(size: 14),
            plainTextColor: Splash.Color(
                red: 0.2,
                green: 0.2,
                blue: 0.2,
                alpha: 1.0
            ),
            tokenColors: [
                .keyword: Splash.Color(red: 139/255, green: 92/255, blue: 246/255, alpha: 1.0),      // violet
                .string: Splash.Color(red: 244/255, green: 63/255, blue: 94/255, alpha: 1.0),       // rose
                .type: Splash.Color(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0),        // teal
                .call: Splash.Color(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0),        // blue
                .number: Splash.Color(red: 234/255, green: 88/255, blue: 12/255, alpha: 1.0),       // orange
                .comment: Splash.Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),                // gray
                .property: Splash.Color(red: 79/255, green: 70/255, blue: 229/255, alpha: 1.0),     // indigo
                .dotAccess: Splash.Color(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),              // slate600
                .preprocessing: Splash.Color(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0) // amber
            ],
            backgroundColor: Splash.Color(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        )
    }
    
    // MARK: - Public API
    
    /// Highlight code with syntax coloring
    /// - Parameters:
    ///   - code: The code string to highlight
    ///   - language: Optional language identifier (e.g., "swift", "python")
    /// - Returns: AttributedString with syntax highlighting applied
    public static func highlight(_ code: String, language: String?) -> AttributedString {
        guard let lang = language?.lowercased(), !lang.isEmpty else {
            return AttributedString(code)
        }
        
        switch lang {
        case "swift":
            return highlightSwift(code)
        case "python", "javascript", "js", "typescript", "ts", "json", "html", "css":
            return highlightGeneric(code, language: lang)
        default:
            return AttributedString(code)
        }
    }
    
    /// Get the display name for a language
    /// - Parameter language: The language identifier
    /// - Returns: Human-readable language name
    public static func displayName(for language: String?) -> String {
        guard let lang = language?.lowercased() else {
            return "Code"
        }
        
        switch lang {
        case "swift": return "Swift"
        case "python", "py": return "Python"
        case "javascript", "js": return "JavaScript"
        case "typescript", "ts": return "TypeScript"
        case "json": return "JSON"
        case "html": return "HTML"
        case "css": return "CSS"
        case "bash", "sh", "shell": return "Shell"
        case "sql": return "SQL"
        case "ruby", "rb": return "Ruby"
        case "go": return "Go"
        case "rust", "rs": return "Rust"
        case "kotlin", "kt": return "Kotlin"
        case "java": return "Java"
        case "c": return "C"
        case "cpp", "c++": return "C++"
        case "csharp", "cs", "c#": return "C#"
        case "php": return "PHP"
        case "yaml", "yml": return "YAML"
        case "xml": return "XML"
        case "markdown", "md": return "Markdown"
        default: return lang.capitalized
        }
    }
    
    // MARK: - Private Implementation
    
    /// Highlight Swift code using Splash
    private static func highlightSwift(_ code: String) -> AttributedString {
        let highlighter = Splash.SyntaxHighlighter<AttributedStringOutputFormat>(
            format: AttributedStringOutputFormat(theme: guanjiTheme)
        )
        let highlighted = highlighter.highlight(code)
        return AttributedString(highlighted)
    }
    
    /// Basic highlighting for non-Swift languages
    /// Applies simple pattern-based coloring for common syntax elements
    private static func highlightGeneric(_ code: String, language: String) -> AttributedString {
        var attributed = AttributedString(code)
        
        // Apply monospace font
        attributed.font = .system(.body, design: .monospaced)
        
        // For now, return plain monospace text
        // Future enhancement: add regex-based highlighting for common patterns
        // like strings, numbers, and comments
        
        return attributed
    }
}

// MARK: - Splash Output Format

/// Custom output format for Splash that produces AttributedString
public struct AttributedStringOutputFormat: OutputFormat {
    public let theme: Splash.Theme
    
    public init(theme: Splash.Theme) {
        self.theme = theme
    }
    
    public func makeBuilder() -> Builder {
        return Builder(theme: theme)
    }
}

extension AttributedStringOutputFormat {
    public struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var result = NSMutableAttributedString()
        
        init(theme: Splash.Theme) {
            self.theme = theme
        }
        
        public mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = theme.tokenColors[type] ?? theme.plainTextColor
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: platformColor(from: color),
                .font: platformFont(from: theme.font)
            ]
            result.append(NSAttributedString(string: token, attributes: attributes))
        }
        
        public mutating func addPlainText(_ text: String) {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: platformColor(from: theme.plainTextColor),
                .font: platformFont(from: theme.font)
            ]
            result.append(NSAttributedString(string: text, attributes: attributes))
        }
        
        public mutating func addWhitespace(_ whitespace: String) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: platformFont(from: theme.font)
            ]
            result.append(NSAttributedString(string: whitespace, attributes: attributes))
        }
        
        public func build() -> NSAttributedString {
            return result
        }
        
        // MARK: - Platform Helpers
        
        private func platformColor(from splashColor: Splash.Color) -> Any {
            // Splash.Color is a typealias for UIColor/NSColor
            // so we can return it directly
            return splashColor
        }
        
        private func platformFont(from splashFont: Splash.Font) -> Any {
            #if canImport(UIKit)
            return UIFont.monospacedSystemFont(ofSize: CGFloat(splashFont.size), weight: .regular)
            #elseif canImport(AppKit)
            return NSFont.monospacedSystemFont(ofSize: CGFloat(splashFont.size), weight: .regular)
            #endif
        }
    }
}
