import Foundation

// MARK: - SSE Response Parser

/// Server-Sent Events (SSE) response parser for Claudeflare Gateway
/// - Note: Parses SSE format responses from the Gateway streaming API
/// - Supports event types: content, thinking, done
/// - Requirements: 3.1, 3.2, 3.3, 3.4
public struct SSEParser {
    
    // MARK: - Constants
    
    /// SSE data line prefix
    private static let dataPrefix = "data: "
    
    /// SSE event line prefix
    private static let eventPrefix = "event: "
    
    /// SSE id line prefix
    private static let idPrefix = "id: "
    
    /// SSE stream end marker (legacy format)
    private static let doneMarker = "[DONE]"
    
    // MARK: - Event Types
    
    /// SSE event types from Claudeflare Gateway
    public enum EventType: String {
        case content = "content"
        case thinking = "thinking"
        case done = "done"
    }
    
    /// Parsed SSE event
    public struct ParsedEvent {
        public let type: EventType
        public let data: String
        public let id: String?
    }
    
    // MARK: - Public Methods
    
    /// Parse a complete SSE response string (legacy format)
    /// - Parameter response: Raw SSE response containing multiple data lines
    /// - Returns: Extracted content string with all data blocks concatenated
    /// - Requirements: 3.1, 3.4
    public static func parse(_ response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        var contentParts: [String] = []
        
        for line in lines {
            // Check if this is the [DONE] marker - stop parsing if so
            if isDone(line) {
                break
            }
            
            if let content = parseLine(line) {
                contentParts.append(content)
            }
        }
        
        return contentParts.joined()
    }
    
    /// Parse a single SSE data line (legacy format)
    /// - Parameter line: Single line from SSE response
    /// - Returns: Extracted data content, or nil if line is a control line or empty
    /// - Requirements: 3.1, 3.2, 3.3
    public static func parseLine(_ line: String) -> String? {
        // Skip empty or whitespace-only lines (Requirement 3.3)
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard !trimmedLine.isEmpty else {
            return nil
        }
        
        // Check for data prefix (Requirement 3.1)
        // First, find where the actual content starts (skip leading whitespace)
        let lineWithoutLeadingWhitespace = line.drop(while: { $0.isWhitespace })
        
        guard lineWithoutLeadingWhitespace.hasPrefix(dataPrefix) else {
            return nil
        }
        
        // Extract content after "data: " prefix - preserve trailing content exactly
        let content = String(lineWithoutLeadingWhitespace.dropFirst(dataPrefix.count))
        
        // Check for [DONE] marker (Requirement 3.2)
        if content == doneMarker {
            return nil
        }
        
        // Return the extracted content (preserving any trailing spaces)
        return content
    }
    
    /// Parse event type from a line
    /// - Parameter line: Single line from SSE response
    /// - Returns: Event type if this is an event line, nil otherwise
    public static func parseEventType(_ line: String) -> EventType? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard trimmedLine.hasPrefix(eventPrefix) else {
            return nil
        }
        let eventName = String(trimmedLine.dropFirst(eventPrefix.count)).trimmingCharacters(in: .whitespaces)
        return EventType(rawValue: eventName)
    }
    
    /// Parse data content from a line
    /// - Parameter line: Single line from SSE response
    /// - Returns: Data content if this is a data line, nil otherwise
    public static func parseDataContent(_ line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard trimmedLine.hasPrefix(dataPrefix) else {
            return nil
        }
        return String(trimmedLine.dropFirst(dataPrefix.count))
    }
    
    /// Check if a line indicates the end of the stream
    /// - Parameter line: Single line from SSE response
    /// - Returns: true if this is the [DONE] marker
    public static func isDone(_ line: String) -> Bool {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Check for legacy format: data: [DONE]
        if trimmedLine.hasPrefix(dataPrefix) {
            let content = String(trimmedLine.dropFirst(dataPrefix.count))
            return content == doneMarker
        }
        
        // Check for new format: event: done
        if trimmedLine.hasPrefix(eventPrefix) {
            let eventName = String(trimmedLine.dropFirst(eventPrefix.count)).trimmingCharacters(in: .whitespaces)
            return eventName == "done"
        }
        
        return false
    }
    
    /// Format content as SSE data lines
    /// - Parameter content: Content to format
    /// - Returns: SSE formatted string with data prefix
    /// - Note: Used for testing round-trip consistency
    public static func format(_ content: String) -> String {
        guard !content.isEmpty else {
            return ""
        }
        return "\(dataPrefix)\(content)"
    }
    
    /// Format multiple content parts as a complete SSE response
    /// - Parameter parts: Array of content strings
    /// - Returns: Complete SSE response with [DONE] marker
    public static func formatResponse(_ parts: [String]) -> String {
        var lines: [String] = []
        for part in parts {
            if !part.isEmpty {
                lines.append("\(dataPrefix)\(part)")
            }
        }
        lines.append("\(dataPrefix)\(doneMarker)")
        return lines.joined(separator: "\n")
    }
    
    /// Format content as new event-based SSE format
    /// - Parameters:
    ///   - content: Content to format
    ///   - eventType: Event type (content, thinking, done)
    ///   - id: Optional event ID
    /// - Returns: SSE formatted string with event and data lines
    public static func formatEvent(content: String, eventType: EventType, id: String? = nil) -> String {
        var lines: [String] = []
        lines.append("\(eventPrefix)\(eventType.rawValue)")
        if let id = id {
            lines.append("\(idPrefix)\(id)")
        }
        lines.append("\(dataPrefix)\(content)")
        return lines.joined(separator: "\n")
    }
}
