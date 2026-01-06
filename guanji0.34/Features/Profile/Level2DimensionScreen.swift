import SwiftUI

/// Level 2 dimension list screen - displays secondary dimensions for a selected Level 1
/// Task 9.3: 创建 Level2DimensionScreen.swift（二级维度列表页）
public struct Level2DimensionScreen: View {
    @ObservedObject var viewModel: DimensionProfileViewModel
    let level1: DimensionHierarchy.Level1
    
    public init(viewModel: DimensionProfileViewModel, level1: DimensionHierarchy.Level1) {
        self.viewModel = viewModel
        self.level1 = level1
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with dimension info
                dimensionHeader
                
                // Level 2 dimension list
                level2List
            }
            .padding()
        }
        .background(Colors.background)
        .navigationTitle(level1.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Dimension Header
    
    private var dimensionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(level1.englishName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let totalNodes = viewModel.getLevel2Stats(for: level1).reduce(0) { $0 + $1.nodeCount }
                Text("\(totalNodes) 节点")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Colors.indigo.opacity(0.1))
                    .foregroundStyle(Colors.indigo)
                    .clipShape(Capsule())
            }
            
            Text(level1.dimensionDescription)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Level 2 List
    
    private var level2List: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("二级维度")
                .font(.headline)
                .foregroundStyle(.primary)
            
            let stats = viewModel.getLevel2Stats(for: level1)
            
            ForEach(stats) { stat in
                NavigationLink(destination: KnowledgeNodeListScreen(
                    viewModel: viewModel,
                    level1: level1,
                    level2: stat.dimension
                )) {
                    Level2DimensionRowContent(stat: stat)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Level 2 Dimension Row Content

private struct Level2DimensionRowContent: View {
    let stat: DimensionStats
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Colors.indigo.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: iconForLevel2(stat.dimension))
                        .foregroundStyle(Colors.indigo)
                }
            
            // Name and description
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text("\(stat.nodeCount) 节点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let lastUpdated = stat.lastUpdated {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(lastUpdated.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func iconForLevel2(_ level2: String) -> String {
        switch level2 {
        // 本体
        case "identity": return "person.text.rectangle"
        case "physical": return "heart.fill"
        case "personality": return "brain"
        // 物质
        case "economy": return "banknote"
        case "objects_space": return "house.fill"
        case "security": return "shield.fill"
        // 成就
        case "career": return "briefcase.fill"
        case "competencies": return "star.fill"
        case "outcomes": return "trophy.fill"
        // 阅历
        case "culture_entertainment": return "book.fill"
        case "exploration": return "map.fill"
        case "history": return "clock.fill"
        // 精神
        case "ideology": return "lightbulb.fill"
        case "mental_state": return "heart.text.square.fill"
        case "wisdom": return "sparkles"
        default: return "folder.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Level2DimensionScreen(
            viewModel: DimensionProfileViewModel(),
            level1: .self_
        )
    }
}
