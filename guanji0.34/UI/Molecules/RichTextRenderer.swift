import SwiftUI
import Markdown
#if canImport(UIKit)
import UIKit
#endif

/// Renders Markdown Document as SwiftUI views
/// Converts swift-markdown Document AST to native SwiftUI components
public struct RichTextRenderer: View {
    let document: Document
    let isUserMessage: Bool
    
    public init(document: Document, isUserMessage: Bool = false) {
        self.document = document
        self.isUserMessage = isUserMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                MarkdownBlockView(markup: child, isUserMessage: isUserMessage)
            }
        }
    }
}

/// Routes individual Markdown blocks to their specific renderers
struct MarkdownBlockView: View {
    let markup: Markup
    let isUserMessage: Bool
    let indentLevel: Int
    
    init(markup: Markup, isUserMessage: Bool, indentLevel: Int = 0) {
        self.markup = markup
        self.isUserMessage = isUserMessage
        self.indentLevel = indentLevel
    }
    
    var body: some View {
        Group {
            if let heading = markup as? Heading {
                HeadingView(heading: heading, isUserMessage: isUserMessage)
            } else if let paragraph = markup as? Paragraph {
                ParagraphView(paragraph: paragraph, isUserMessage: isUserMessage)
            } else if let codeBlock = markup as? CodeBlock {
                CodeBlockView(codeBlock: codeBlock)
            } else if let list = markup as? UnorderedList {
                UnorderedListView(list: list, isUserMessage: isUserMessage, indentLevel: indentLevel)
            } else if let list = markup as? OrderedList {
                OrderedListView(list: list, isUserMessage: isUserMessage, indentLevel: indentLevel)
            } else if let quote = markup as? BlockQuote {
                BlockQuoteView(quote: quote, isUserMessage: isUserMessage)
            } else if let table = markup as? Markdown.Table {
                MarkdownTableView(table: table, isUserMessage: isUserMessage)
            } else if markup is ThematicBreak {
                ThematicBreakView()
            } else {
                // Fallback: render as plain text for unknown markup types
                Text(markup.format())
                    .font(Typography.body)
                    .foregroundColor(isUserMessage ? .white : Colors.slateText)
            }
        }
    }
}

/// Renders code blocks with syntax highlighting and copy functionality
/// **Feature: ai-rich-content-rendering**
/// **Validates: Requirements 1.4, 2.1-2.4, 4.1-4.4**
struct CodeBlockView: View {
    let codeBlock: CodeBlock
    @State private var copied = false
    
    private var language: String? {
        codeBlock.language
    }
    
    private var code: String {
        codeBlock.code
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            headerView
            
            // Scrollable code content area
            codeContentView
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Colors.slate500.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Language label
            Text(SyntaxHighlighter.displayName(for: language))
                .font(Typography.caption)
                .foregroundColor(Colors.slate500)
            
            Spacer()
            
            // Copy button
            Button(action: copyCode) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundColor(copied ? Colors.emerald : Colors.slate500)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copied ? Localization.tr("AI.Code.Copied") : Localization.tr("AI.Code.Copy"))
            .accessibilityHint(Localization.tr("AI.Code.CopyHint"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Colors.slateLight)
    }
    
    // MARK: - Code Content View
    
    private var codeContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(highlightedCode)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
        }
        .background(Colors.cardBackground)
    }
    
    // MARK: - Syntax Highlighting
    
    private var highlightedCode: AttributedString {
        SyntaxHighlighter.highlight(code, language: language)
    }
    
    // MARK: - Copy Functionality
    
    private func copyCode() {
        // Copy raw code to clipboard (without syntax highlighting markup)
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        // Show checkmark
        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        
        // Auto-reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copied = false
            }
        }
    }
}

// MARK: - Convenience initializer for direct use

extension CodeBlockView {
    /// Initialize with language and code strings directly
    init(language: String?, code: String) {
        // Create a temporary CodeBlock for initialization
        let markdown = "```\(language ?? "")\n\(code)\n```"
        let doc = Document(parsing: markdown)
        if let codeBlock = doc.children.first(where: { $0 is CodeBlock }) as? CodeBlock {
            self.codeBlock = codeBlock
        } else {
            // Fallback: create a minimal code block
            let fallbackDoc = Document(parsing: "```\n\(code)\n```")
            self.codeBlock = fallbackDoc.children.first(where: { $0 is CodeBlock }) as! CodeBlock
        }
    }
}

/// Renders Markdown tables with borders, cell padding, and horizontal scrolling
/// **Feature: ai-rich-content-rendering**
/// **Validates: Requirements 8.1-8.4**
struct MarkdownTableView: View {
    let table: Markdown.Table
    let isUserMessage: Bool
    
    init(table: Markdown.Table, isUserMessage: Bool = false) {
        self.table = table
        self.isUserMessage = isUserMessage
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                MarkdownTableRowView(
                    cells: Array(table.head.cells),
                    isHeader: true,
                    columnAlignments: columnAlignments,
                    isUserMessage: isUserMessage
                )
                
                // Body rows
                ForEach(Array(table.body.rows.enumerated()), id: \.offset) { _, row in
                    MarkdownTableRowView(
                        cells: Array(row.cells),
                        isHeader: false,
                        columnAlignments: columnAlignments,
                        isUserMessage: isUserMessage
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(6)
        }
    }
    
    // MARK: - Column Alignments
    
    /// Extract column alignments from table using columnAlignments property
    private var columnAlignments: [Markdown.Table.ColumnAlignment?] {
        return table.columnAlignments
    }
    
    // MARK: - Colors
    
    private var borderColor: Color {
        isUserMessage ? Color.white.opacity(0.3) : Colors.slate500.opacity(0.3)
    }
}

// MARK: - MarkdownTableRowView

/// Renders a single table row (header or body)
struct MarkdownTableRowView: View {
    let cells: [Markdown.Table.Cell]
    let isHeader: Bool
    let columnAlignments: [Markdown.Table.ColumnAlignment?]
    let isUserMessage: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                MarkdownTableCellView(
                    cell: cell,
                    isHeader: isHeader,
                    alignment: safeAlignment(at: index),
                    isUserMessage: isUserMessage,
                    isLastColumn: index == cells.count - 1
                )
            }
        }
        .background(rowBackground)
    }
    
    private func safeAlignment(at index: Int) -> Markdown.Table.ColumnAlignment? {
        guard index < columnAlignments.count else { return nil }
        return columnAlignments[index]
    }
    
    private var rowBackground: Color {
        if isHeader {
            return isUserMessage ? Color.white.opacity(0.1) : Colors.slateLight
        }
        return Color.clear
    }
}

// MARK: - MarkdownTableCellView

/// Renders a single table cell with proper alignment and styling
struct MarkdownTableCellView: View {
    let cell: Markdown.Table.Cell
    let isHeader: Bool
    let alignment: Markdown.Table.ColumnAlignment?
    let isUserMessage: Bool
    let isLastColumn: Bool
    
    var body: some View {
        HStack {
            if horizontalAlignment == .trailing {
                Spacer(minLength: 0)
            }
            
            Text(cellContent)
                .font(isHeader ? Typography.body.bold() : Typography.body)
                .foregroundColor(textColor)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if horizontalAlignment == .leading {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 60)
        .overlay(
            Rectangle()
                .fill(borderColor)
                .frame(width: 1),
            alignment: .trailing
        )
        .overlay(
            Rectangle()
                .fill(borderColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Cell Content
    
    private var cellContent: AttributedString {
        InlineFormatter.format(children: Array(cell.children), isUserMessage: isUserMessage)
    }
    
    // MARK: - Alignment
    
    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .left, nil:
            return .leading
        case .right:
            return .trailing
        case .center:
            return .center
        }
    }
    
    // MARK: - Colors
    
    private var textColor: Color {
        isUserMessage ? .white : Colors.slateText
    }
    
    private var borderColor: Color {
        isUserMessage ? Color.white.opacity(0.2) : Colors.slate500.opacity(0.2)
    }
}

// MARK: - Table Utilities

/// Utility functions for table processing
/// Also aliased as TableUtilities for backward compatibility
enum MarkdownTableUtilities {
    
    /// Get the cell count from a table's header row
    static func headerCellCount(from table: Markdown.Table) -> Int {
        return Array(table.head.cells).count
    }
    
    /// Get all row cell counts from a table (including header)
    static func allRowCellCounts(from table: Markdown.Table) -> [Int] {
        var counts: [Int] = []
        
        counts.append(Array(table.head.cells).count)
        
        for row in table.body.rows {
            counts.append(Array(row.cells).count)
        }
        
        return counts
    }
    
    /// Check if all rows have consistent cell counts
    static func hasConsistentCellCounts(table: Markdown.Table) -> Bool {
        let counts = allRowCellCounts(from: table)
        guard let first = counts.first else { return true }
        return counts.allSatisfy { $0 == first }
    }
    
    /// Normalize cell counts by padding rows with fewer cells
    /// Returns the expected cell count (from header) and whether normalization was needed
    static func normalizedCellCounts(table: Markdown.Table) -> (expectedCount: Int, needsNormalization: Bool) {
        let headerCount = headerCellCount(from: table)
        let allCounts = allRowCellCounts(from: table)
        let needsNormalization = allCounts.contains { $0 != headerCount }
        return (headerCount, needsNormalization)
    }
}

/// Alias for backward compatibility with tests
typealias TableUtilities = MarkdownTableUtilities

/// Renders horizontal rule / thematic break
struct ThematicBreakView: View {
    var body: some View {
        Divider()
            .padding(.vertical, 8)
    }
}


// MARK: - HeadingView

/// Renders Markdown headings (H1-H6) with appropriate font sizes
/// Enhanced styling for better visual hierarchy like Gemini
struct HeadingView: View {
    let heading: Heading
    let isUserMessage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headingText)
                .font(fontForLevel(heading.level))
                .fontWeight(weightForLevel(heading.level))
                .foregroundColor(isUserMessage ? .white : Colors.slateText)
                .lineSpacing(4)
        }
        .padding(.top, topPaddingForLevel(heading.level))
        .padding(.bottom, bottomPaddingForLevel(heading.level))
    }
    
    private var headingText: String {
        heading.children.compactMap { child -> String? in
            if let text = child as? Markdown.Text {
                return text.string
            } else if let code = child as? InlineCode {
                return code.code
            } else if let strong = child as? Strong {
                return strong.plainText
            } else if let emphasis = child as? Emphasis {
                return emphasis.plainText
            }
            return child.format()
        }.joined()
    }
    
    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 22, weight: .bold, design: .rounded)
        case 2: return .system(size: 19, weight: .bold, design: .default)
        case 3: return .system(size: 17, weight: .semibold, design: .default)
        case 4: return .system(size: 16, weight: .semibold, design: .default)
        case 5: return .system(size: 15, weight: .medium, design: .default)
        case 6: return .system(size: 14, weight: .medium, design: .default)
        default: return Typography.body
        }
    }
    
    private func weightForLevel(_ level: Int) -> Font.Weight {
        switch level {
        case 1, 2: return .bold
        case 3, 4: return .semibold
        default: return .medium
        }
    }
    
    private func topPaddingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 12
        case 2: return 10
        case 3: return 8
        default: return 4
        }
    }
    
    private func bottomPaddingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 4
        case 2: return 2
        default: return 0
        }
    }
}


// MARK: - ParagraphView

/// Renders paragraphs with inline formatting (bold, italic, code, links)
/// Enhanced with better line spacing for readability
struct ParagraphView: View {
    let paragraph: Paragraph
    let isUserMessage: Bool
    @State private var tappedURL: URL?
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Text(attributedContent)
            .font(Typography.body)
            .foregroundColor(isUserMessage ? .white : Colors.slateText)
            .lineSpacing(4)
            .environment(\.openURL, OpenURLAction { url in
                openURL(url)
                return .handled
            })
    }
    
    private var attributedContent: AttributedString {
        InlineFormatter.format(children: Array(paragraph.children), isUserMessage: isUserMessage)
    }
}

// MARK: - InlineFormatter

/// Utility for formatting inline Markdown elements to AttributedString
enum InlineFormatter {
    
    /// Format inline children to AttributedString
    static func format(children: [Markup], isUserMessage: Bool) -> AttributedString {
        var result = AttributedString()
        
        for child in children {
            result += formatInline(child, isUserMessage: isUserMessage)
        }
        
        // Post-process to handle any unrendered ** patterns
        result = postProcessBoldPatterns(result, isUserMessage: isUserMessage)
        
        return result
    }
    
    private static func formatInline(_ markup: Markup, isUserMessage: Bool) -> AttributedString {
        if let text = markup as? Markdown.Text {
            return AttributedString(text.string)
        }
        
        if let strong = markup as? Strong {
            var attr = format(children: Array(strong.children), isUserMessage: isUserMessage)
            attr.font = .body.bold()
            return attr
        }
        
        if let emphasis = markup as? Emphasis {
            var attr = format(children: Array(emphasis.children), isUserMessage: isUserMessage)
            attr.font = .body.italic()
            return attr
        }
        
        if let code = markup as? InlineCode {
            var attr = AttributedString(code.code)
            attr.font = .system(.body, design: .monospaced)
            if !isUserMessage {
                attr.backgroundColor = Colors.slateLight
            }
            return attr
        }
        
        if let link = markup as? Markdown.Link {
            var attr = format(children: Array(link.children), isUserMessage: isUserMessage)
            if let destination = link.destination, let url = URL(string: destination) {
                attr.link = url
                attr.foregroundColor = isUserMessage ? .white : Colors.blue
                attr.underlineStyle = .single
            }
            return attr
        }
        
        if markup is SoftBreak {
            return AttributedString(" ")
        }
        
        if markup is LineBreak {
            return AttributedString("\n")
        }
        
        if let image = markup as? Markdown.Image {
            // For now, show alt text for images
            let altText = image.plainText
            var attr = AttributedString(altText.isEmpty ? "[Image]" : "[\(altText)]")
            attr.foregroundColor = Colors.slate500
            return attr
        }
        
        // Fallback for unknown inline types
        return AttributedString(markup.format())
    }
    
    /// Post-process AttributedString to handle unrendered ** bold patterns
    /// This catches cases where swift-markdown fails to parse ** as Strong
    /// 
    /// **Feature: ai-conversation-fixes**
    /// **Validates: Requirements 4.1, 4.3, 4.5**
    ///
    /// Edge cases handled:
    /// - Patterns at string start/end
    /// - Multiple consecutive bold patterns
    /// - Unclosed patterns (displays raw **)
    /// - Empty content between ** (displays raw ****)
    /// - Content with newlines (displays raw **)
    /// - Content that is purely whitespace (displays raw **)
    private static func postProcessBoldPatterns(_ input: AttributedString, isUserMessage: Bool) -> AttributedString {
        let plainString = String(input.characters)
        
        // Check if there are any ** patterns that weren't rendered
        guard plainString.contains("**") else {
            return input
        }
        
        var result = AttributedString()
        var scanner = plainString.startIndex
        
        while scanner < plainString.endIndex {
            // Find opening **
            guard let openStart = plainString.range(of: "**", range: scanner..<plainString.endIndex) else {
                // No more **, append rest of string
                let remainingText = String(plainString[scanner...])
                result += AttributedString(remainingText)
                break
            }
            
            // Append text before **
            if scanner < openStart.lowerBound {
                let beforeText = String(plainString[scanner..<openStart.lowerBound])
                result += AttributedString(beforeText)
            }
            
            // Find closing **
            let searchStart = openStart.upperBound
            guard searchStart < plainString.endIndex,
                  let closeStart = plainString.range(of: "**", range: searchStart..<plainString.endIndex) else {
                // No closing **, append ** literally and continue from after opening **
                result += AttributedString("**")
                scanner = openStart.upperBound
                continue
            }
            
            // Extract content between ** **
            let boldContent = String(plainString[searchStart..<closeStart.lowerBound])
            
            // Validate: non-empty, no newlines, not just whitespace
            let isValidBoldContent = !boldContent.isEmpty &&
                                     !boldContent.contains("\n") &&
                                     !boldContent.trimmingCharacters(in: .whitespaces).isEmpty
            
            if isValidBoldContent {
                // Apply bold formatting
                var boldAttr = AttributedString(boldContent)
                boldAttr.font = .body.bold()
                result += boldAttr
                scanner = closeStart.upperBound
            } else {
                // Invalid pattern, keep ** literally and continue scanning from after opening **
                result += AttributedString("**")
                scanner = openStart.upperBound
            }
        }
        
        return result
    }
    
    /// Extract all links from inline content
    static func extractLinks(from children: [Markup]) -> [(text: String, url: URL)] {
        var links: [(text: String, url: URL)] = []
        
        for child in children {
            links += extractLinksRecursive(from: child)
        }
        
        return links
    }
    
    private static func extractLinksRecursive(from markup: Markup) -> [(text: String, url: URL)] {
        var links: [(text: String, url: URL)] = []
        
        if let link = markup as? Markdown.Link {
            if let destination = link.destination, let url = URL(string: destination) {
                links.append((text: link.plainText, url: url))
            }
        }
        
        for child in markup.children {
            links += extractLinksRecursive(from: child)
        }
        
        return links
    }
}


// MARK: - UnorderedListView

/// Renders unordered (bullet) lists with proper indentation and nested list support
/// Enhanced spacing for better visual hierarchy
struct UnorderedListView: View {
    let list: UnorderedList
    let isUserMessage: Bool
    let indentLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                ListItemView(
                    item: item,
                    isUserMessage: isUserMessage,
                    indentLevel: indentLevel,
                    bulletStyle: .unordered(level: indentLevel)
                )
            }
        }
        .padding(.leading, indentLevel > 0 ? 20 : 0)
    }
    
    private var itemSpacing: CGFloat {
        indentLevel == 0 ? 10 : 6
    }
}

// MARK: - OrderedListView

/// Renders ordered (numbered) lists with sequential numbering and nested list support
/// Enhanced spacing for better visual hierarchy
struct OrderedListView: View {
    let list: OrderedList
    let isUserMessage: Bool
    let indentLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                ListItemView(
                    item: item,
                    isUserMessage: isUserMessage,
                    indentLevel: indentLevel,
                    bulletStyle: .ordered(number: index + 1)
                )
            }
        }
        .padding(.leading, indentLevel > 0 ? 20 : 0)
    }
    
    private var itemSpacing: CGFloat {
        indentLevel == 0 ? 10 : 6
    }
}

// MARK: - ListItemView

/// Renders individual list items with bullet/number and content
/// Enhanced with better bullet styling and spacing
struct ListItemView: View {
    let item: ListItem
    let isUserMessage: Bool
    let indentLevel: Int
    let bulletStyle: BulletStyle
    
    enum BulletStyle {
        case unordered(level: Int)
        case ordered(number: Int)
        
        var text: String {
            switch self {
            case .unordered(let level):
                // Different bullet styles for different levels
                switch level {
                case 0: return "•"
                case 1: return "◦"
                default: return "▪"
                }
            case .ordered(let number):
                return "\(number)."
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(bulletStyle.text)
                .font(bulletFont)
                .foregroundColor(bulletColor)
                .frame(minWidth: bulletStyle.minWidth, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderChild(child)
                }
            }
        }
    }
    
    private var bulletFont: Font {
        switch bulletStyle {
        case .unordered:
            return .system(size: 14, weight: .medium)
        case .ordered:
            return Typography.body
        }
    }
    
    private var bulletColor: Color {
        if isUserMessage {
            return .white.opacity(0.9)
        }
        switch bulletStyle {
        case .unordered(let level):
            return level == 0 ? Colors.slate600 : Colors.slate500
        case .ordered:
            return Colors.slate600
        }
    }
    
    @ViewBuilder
    private func renderChild(_ child: Markup) -> some View {
        if let paragraph = child as? Paragraph {
            ParagraphView(paragraph: paragraph, isUserMessage: isUserMessage)
        } else if let nestedUnordered = child as? UnorderedList {
            UnorderedListView(
                list: nestedUnordered,
                isUserMessage: isUserMessage,
                indentLevel: indentLevel + 1
            )
            .padding(.top, 4)
        } else if let nestedOrdered = child as? OrderedList {
            OrderedListView(
                list: nestedOrdered,
                isUserMessage: isUserMessage,
                indentLevel: indentLevel + 1
            )
            .padding(.top, 4)
        } else {
            MarkdownBlockView(
                markup: child,
                isUserMessage: isUserMessage,
                indentLevel: indentLevel + 1
            )
        }
    }
}

private extension ListItemView.BulletStyle {
    var minWidth: CGFloat {
        switch self {
        case .unordered:
            return 14
        case .ordered:
            return 22
        }
    }
}


// MARK: - BlockQuoteView

/// Renders block quotes with left border accent and indented layout
struct BlockQuoteView: View {
    let quote: BlockQuote
    let isUserMessage: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left border accent
            Rectangle()
                .fill(isUserMessage ? Color.white.opacity(0.5) : Colors.slate500)
                .frame(width: 3)
                .cornerRadius(1.5)
            
            // Quote content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(quote.children.enumerated()), id: \.offset) { _, child in
                    renderQuoteChild(child)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func renderQuoteChild(_ child: Markup) -> some View {
        if let paragraph = child as? Paragraph {
            Text(InlineFormatter.format(children: Array(paragraph.children), isUserMessage: isUserMessage))
                .font(Typography.body)
                .foregroundColor(isUserMessage ? .white.opacity(0.85) : Colors.slate600)
                .italic()
        } else if let nestedQuote = child as? BlockQuote {
            BlockQuoteView(quote: nestedQuote, isUserMessage: isUserMessage)
        } else {
            MarkdownBlockView(markup: child, isUserMessage: isUserMessage)
        }
    }
}
