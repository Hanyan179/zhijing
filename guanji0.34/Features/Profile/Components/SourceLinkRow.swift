import SwiftUI

// MARK: - SourceLinkRow
// Task 10.4: 溯源链接行组件
// 显示 dayId（日期）、snippet（摘要）、relevanceScore（相关度）
// 支持点击跳转到原始来源

/// Source link row component for displaying source traceability
public struct SourceLinkRow: View {
    
    // MARK: - Properties
    
    let link: SourceLink
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        link: SourceLink,
        onTap: (() -> Void)? = nil
    ) {
        self.link = link
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                // Header: source type badge + date + chevron
                headerRow
                
                // Snippet
                if let snippet = link.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Relevance score
                if let score = link.relevanceScore {
                    relevanceScoreView(score)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack {
            // Source type badge
            sourceTypeBadge
            
            Spacer()
            
            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Chevron
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    // MARK: - Source Type Badge
    
    private var sourceTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: sourceTypeIcon)
                .font(.caption2)
            Text(sourceTypeDisplayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sourceTypeColor.opacity(0.1))
        .foregroundStyle(sourceTypeColor)
        .clipShape(Capsule())
    }
    
    private var sourceTypeDisplayName: String {
        switch link.sourceType {
        case "diary": return "日记"
        case "conversation": return "对话"
        case "tracker": return "追踪器"
        case "mindState": return "心情"
        default: return link.sourceType
        }
    }
    
    private var sourceTypeIcon: String {
        switch link.sourceType {
        case "diary": return "book.fill"
        case "conversation": return "bubble.left.and.bubble.right.fill"
        case "tracker": return "chart.line.uptrend.xyaxis"
        case "mindState": return "heart.fill"
        default: return "doc.fill"
        }
    }
    
    private var sourceTypeColor: Color {
        switch link.sourceType {
        case "diary": return Colors.indigo
        case "conversation": return Colors.emerald
        case "tracker": return Colors.amber
        case "mindState": return Colors.violet
        default: return Colors.sky
        }
    }
    
    // MARK: - Formatted Date
    
    private var formattedDate: String {
        // dayId format: "YYYY-MM-DD"
        let components = link.dayId.split(separator: "-")
        if components.count == 3,
           let year = Int(components[0]),
           let month = Int(components[1]),
           let day = Int(components[2]) {
            return "\(year)年\(month)月\(day)日"
        }
        return link.dayId
    }
    
    // MARK: - Relevance Score View
    
    private func relevanceScoreView(_ score: Double) -> some View {
        HStack(spacing: 6) {
            Text("相关度")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(relevanceColor(score))
                        .frame(width: geometry.size.width * score, height: 4)
                }
            }
            .frame(width: 60, height: 4)
            
            Text("\(Int(score * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func relevanceColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return Colors.green
        case 0.6..<0.8: return Colors.emerald
        case 0.4..<0.6: return Colors.amber
        default: return Colors.orange
        }
    }
}

// MARK: - Compact Source Link Row

/// Compact version of source link row for inline display
public struct CompactSourceLinkRow: View {
    
    let link: SourceLink
    let onTap: (() -> Void)?
    
    public init(link: SourceLink, onTap: (() -> Void)? = nil) {
        self.link = link
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                // Source type icon
                Image(systemName: sourceTypeIcon)
                    .font(.caption)
                    .foregroundStyle(sourceTypeColor)
                
                // Date
                Text(link.dayId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Snippet preview
                if let snippet = link.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Relevance score
                if let score = link.relevanceScore {
                    Text("\(Int(score * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    private var sourceTypeIcon: String {
        switch link.sourceType {
        case "diary": return "book.fill"
        case "conversation": return "bubble.left.and.bubble.right.fill"
        case "tracker": return "chart.line.uptrend.xyaxis"
        case "mindState": return "heart.fill"
        default: return "doc.fill"
        }
    }
    
    private var sourceTypeColor: Color {
        switch link.sourceType {
        case "diary": return Colors.indigo
        case "conversation": return Colors.emerald
        case "tracker": return Colors.amber
        case "mindState": return Colors.violet
        default: return Colors.sky
        }
    }
}

// MARK: - Preview

#Preview("Source Link Rows") {
    VStack(spacing: 12) {
        SourceLinkRow(
            link: SourceLink(
                sourceType: "diary",
                sourceId: "entry_001",
                dayId: "2024-12-30",
                snippet: "今天参加了一个大型聚会，感觉很累。发现自己还是更喜欢小范围的社交活动。",
                relevanceScore: 0.85
            )
        ) {}
        
        SourceLinkRow(
            link: SourceLink(
                sourceType: "conversation",
                sourceId: "msg_002",
                dayId: "2024-12-28",
                snippet: "和 AI 讨论了关于职业规划的问题，提到了对技术领域的热情。",
                relevanceScore: 0.72
            )
        ) {}
        
        SourceLinkRow(
            link: SourceLink(
                sourceType: "tracker",
                sourceId: "track_003",
                dayId: "2024-12-25",
                snippet: "记录了今天的运动数据",
                relevanceScore: 0.45
            )
        ) {}
        
        SourceLinkRow(
            link: SourceLink(
                sourceType: "mindState",
                sourceId: "mood_004",
                dayId: "2024-12-20",
                snippet: nil,
                relevanceScore: 0.90
            )
        ) {}
    }
    .padding()
}

#Preview("Compact Source Link Rows") {
    VStack(spacing: 8) {
        CompactSourceLinkRow(
            link: SourceLink(
                sourceType: "diary",
                sourceId: "entry_001",
                dayId: "2024-12-30",
                snippet: "今天参加了一个大型聚会...",
                relevanceScore: 0.85
            )
        ) {}
        
        CompactSourceLinkRow(
            link: SourceLink(
                sourceType: "conversation",
                sourceId: "msg_002",
                dayId: "2024-12-28",
                snippet: "和 AI 讨论了职业规划...",
                relevanceScore: 0.72
            )
        ) {}
    }
    .padding()
}
