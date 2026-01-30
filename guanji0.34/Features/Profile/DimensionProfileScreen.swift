import SwiftUI

/// Main dimension profile screen - displays 5 Level 1 dimensions as cards
/// Task 9.1: 创建 DimensionProfileScreen.swift（主画像页面）
public struct DimensionProfileScreen: View {
    @StateObject private var viewModel = DimensionProfileViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User basic info header
                    userInfoHeader
                    
                    // Level 1 dimension cards
                    dimensionCardsSection
                }
                .padding()
            }
            .background(Colors.background)
            .navigationTitle("维度画像")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - User Info Header
    
    private var userInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Avatar placeholder
                Circle()
                    .fill(Colors.indigo.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(Colors.indigo)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let name = viewModel.userBasicInfo.name {
                        Text(name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text("用户画像")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 8) {
                        if let occupation = viewModel.userBasicInfo.occupation {
                            Label(occupation, systemImage: "briefcase.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let city = viewModel.userBasicInfo.city {
                            Label(city, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Total nodes count
            let totalNodes = viewModel.level1Cards.reduce(0) { $0 + $1.stats.nodeCount }
            Text("共 \(totalNodes) 个知识节点")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Dimension Cards Section
    
    private var dimensionCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("维度概览")
                .font(.headline)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.level1Cards) { card in
                    NavigationLink(destination: Level2DimensionScreen(viewModel: viewModel, level1: card.level1)) {
                        DimensionCardContent(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Dimension Card Content

private struct DimensionCardContent: View {
    let card: Level1DimensionCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and name
            HStack {
                Image(systemName: card.icon)
                    .font(.title2)
                    .foregroundStyle(card.color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.stats.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(card.level1.dimensionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Stats
            HStack {
                Text("\(card.stats.nodeCount) 节点")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let lastUpdated = card.stats.lastUpdated {
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
                .stroke(card.color.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Preview

#Preview {
    DimensionProfileScreen()
}
