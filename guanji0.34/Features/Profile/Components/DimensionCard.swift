import SwiftUI

// MARK: - DimensionCard
// Task 10.1: 维度卡片组件
// 显示维度图标、名称、节点数量
// 支持 Level1 和 Level2 两种样式

/// Dimension card component for displaying Level1 or Level2 dimensions
public struct DimensionCard: View {
    
    // MARK: - Card Style
    
    public enum Style {
        case level1
        case level2
    }
    
    // MARK: - Properties
    
    let icon: String
    let name: String
    let description: String?
    let nodeCount: Int
    let lastUpdated: Date?
    let color: Color
    let style: Style
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize with Level1 dimension
    public init(
        level1: DimensionHierarchy.Level1,
        nodeCount: Int,
        lastUpdated: Date? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = Self.iconForLevel1(level1)
        self.name = level1.displayName
        self.description = level1.dimensionDescription
        self.nodeCount = nodeCount
        self.lastUpdated = lastUpdated
        self.color = Self.colorForLevel1(level1)
        self.style = .level1
        self.onTap = onTap
    }
    
    /// Initialize with Level2 dimension
    public init(
        level1: DimensionHierarchy.Level1,
        level2: String,
        nodeCount: Int,
        lastUpdated: Date? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = Self.iconForLevel2(level2)
        self.name = DimensionHierarchy.getLevel2DisplayName(level2)
        self.description = nil
        self.nodeCount = nodeCount
        self.lastUpdated = lastUpdated
        self.color = Self.colorForLevel1(level1)
        self.style = .level2
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: { onTap?() }) {
            content
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    @ViewBuilder
    private var content: some View {
        switch style {
        case .level1:
            level1CardContent
        case .level2:
            level2CardContent
        }
    }
    
    // MARK: - Level1 Card Content
    
    private var level1CardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and chevron
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Name and description
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Stats
            HStack {
                Text("\(nodeCount) 节点")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let lastUpdated = lastUpdated {
                    Text(lastUpdated.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(minHeight: 140)
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
    
    // MARK: - Level2 Card Content
    
    private var level2CardContent: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }
            
            // Name and count
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("\(nodeCount) 节点")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Last updated and chevron
            if let lastUpdated = lastUpdated {
                Text(lastUpdated.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Static Helpers
    
    private static func iconForLevel1(_ level1: DimensionHierarchy.Level1) -> String {
        switch level1 {
        case .self_: return "person.fill"
        case .material: return "dollarsign.circle.fill"
        case .achievements: return "star.fill"
        case .experiences: return "airplane"
        case .spirit: return "brain.head.profile"
        case .relationships: return "person.2.fill"
        case .aiPreferences: return "cpu"
        }
    }
    
    private static func colorForLevel1(_ level1: DimensionHierarchy.Level1) -> Color {
        switch level1 {
        case .self_: return Colors.indigo
        case .material: return Colors.emerald
        case .achievements: return Colors.amber
        case .experiences: return Colors.sky
        case .spirit: return Colors.violet
        case .relationships: return Colors.pink
        case .aiPreferences: return Colors.teal
        }
    }
    
    private static func iconForLevel2(_ level2: String) -> String {
        switch level2 {
        // 本体
        case "identity": return "person.text.rectangle"
        case "physical": return "heart.fill"
        case "personality": return "theatermasks.fill"
        // 物质
        case "economy": return "banknote.fill"
        case "objects_space": return "house.fill"
        case "security": return "shield.fill"
        // 成就
        case "career": return "briefcase.fill"
        case "competencies": return "lightbulb.fill"
        case "outcomes": return "trophy.fill"
        // 阅历
        case "culture_entertainment": return "book.fill"
        case "exploration": return "map.fill"
        case "history": return "clock.fill"
        // 精神
        case "ideology": return "sparkles"
        case "mental_state": return "brain"
        case "wisdom": return "lightbulb.max.fill"
        default: return "folder.fill"
        }
    }
}

// MARK: - Preview

#Preview("Level1 Cards") {
    LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ], spacing: 12) {
        DimensionCard(
            level1: .self_,
            nodeCount: 15,
            lastUpdated: Date().addingTimeInterval(-3600)
        ) {}
        
        DimensionCard(
            level1: .achievements,
            nodeCount: 8,
            lastUpdated: Date().addingTimeInterval(-86400)
        ) {}
        
        DimensionCard(
            level1: .spirit,
            nodeCount: 12,
            lastUpdated: nil
        ) {}
    }
    .padding()
}

#Preview("Level2 Cards") {
    VStack(spacing: 8) {
        DimensionCard(
            level1: .self_,
            level2: "identity",
            nodeCount: 5,
            lastUpdated: Date()
        ) {}
        
        DimensionCard(
            level1: .self_,
            level2: "physical",
            nodeCount: 3,
            lastUpdated: Date().addingTimeInterval(-7200)
        ) {}
        
        DimensionCard(
            level1: .self_,
            level2: "personality",
            nodeCount: 7,
            lastUpdated: nil
        ) {}
    }
    .padding()
}
