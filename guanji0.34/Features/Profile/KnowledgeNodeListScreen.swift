import SwiftUI

/// Knowledge node list screen - displays nodes for a specific dimension path
/// Task 9.4: 创建 KnowledgeNodeListScreen.swift（节点列表页）
public struct KnowledgeNodeListScreen: View {
    @ObservedObject var viewModel: DimensionProfileViewModel
    let level1: DimensionHierarchy.Level1
    let level2: String
    
    @State private var expandedNodeIds: Set<String> = []
    @State private var selectedContentType: NodeContentType?
    
    public init(viewModel: DimensionProfileViewModel, level1: DimensionHierarchy.Level1, level2: String) {
        self.viewModel = viewModel
        self.level1 = level1
        self.level2 = level2
    }
    
    private var groupedNodes: [NodeContentType: [KnowledgeNode]] {
        viewModel.getNodesGroupedByContentType(level1: level1, level2: level2)
    }
    
    private var allNodes: [KnowledgeNode] {
        viewModel.getNodes(level1: level1, level2: level2)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                nodeListHeader
                
                // Content type filter
                contentTypeFilter
                
                // Node list
                nodeListSection
            }
            .padding()
        }
        .background(Colors.background)
        .navigationTitle(DimensionHierarchy.getLevel2DisplayName(level2))
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header
    
    private var nodeListHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(level1.displayName) > \(DimensionHierarchy.getLevel2DisplayName(level2))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(allNodes.count) 节点")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Colors.indigo.opacity(0.1))
                    .foregroundStyle(Colors.indigo)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Content Type Filter
    
    private var contentTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedContentType == nil
                ) {
                    selectedContentType = nil
                }
                
                ForEach(NodeContentType.allCases, id: \.rawValue) { type in
                    let count = groupedNodes[type]?.count ?? 0
                    if count > 0 {
                        FilterChip(
                            title: "\(type.displayName) (\(count))",
                            isSelected: selectedContentType == type
                        ) {
                            selectedContentType = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Node List Section
    
    private var nodeListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let filteredNodes = selectedContentType == nil
                ? allNodes
                : (groupedNodes[selectedContentType!] ?? [])
            
            // Filter out child nodes (they will be shown under their parents)
            let topLevelNodes = filteredNodes.filter { $0.parentNodeId == nil }
            
            if topLevelNodes.isEmpty {
                emptyStateView
            } else {
                ForEach(topLevelNodes) { node in
                    ExpandableKnowledgeNodeRow(
                        node: node,
                        viewModel: viewModel,
                        isExpanded: expandedNodeIds.contains(node.id),
                        onToggleExpand: {
                            toggleExpand(node.id)
                        }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("暂无节点")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func toggleExpand(_ nodeId: String) {
        if expandedNodeIds.contains(nodeId) {
            expandedNodeIds.remove(nodeId)
        } else {
            expandedNodeIds.insert(nodeId)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Colors.indigo : Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expandable Knowledge Node Row

private struct ExpandableKnowledgeNodeRow: View {
    let node: KnowledgeNode
    @ObservedObject var viewModel: DimensionProfileViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    private var hasChildren: Bool {
        node.contentType == .nestedList && !(node.childNodeIds?.isEmpty ?? true)
    }
    
    private var childNodes: [KnowledgeNode] {
        viewModel.getChildNodes(parentId: node.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            NavigationLink(destination: KnowledgeNodeDetailScreen(viewModel: viewModel, node: node)) {
                HStack(spacing: 12) {
                    // Expand button for nested nodes
                    if hasChildren {
                        Button(action: onToggleExpand) {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(width: 20)
                    }
                    
                    // Content type icon
                    contentTypeIcon
                    
                    // Node info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(node.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        if let description = node.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        // Tags
                        if !node.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(node.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Colors.slateLight)
                                        .clipShape(Capsule())
                                }
                                if node.tags.count > 3 {
                                    Text("+\(node.tags.count - 3)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Rarity indicator based on mention count
                    RarityIndicator(
                        rarity: MentionRarity.from(mentionCount: node.mentionCount),
                        color: contentTypeColor,
                        style: .badge
                    )
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            // Child nodes (if expanded)
            if hasChildren && isExpanded {
                VStack(spacing: 8) {
                    ForEach(childNodes) { child in
                        ChildNodeRow(node: child, viewModel: viewModel)
                    }
                }
                .padding(.leading, 32)
                .padding(.top, 8)
            }
        }
    }
    
    private var contentTypeIcon: some View {
        Circle()
            .fill(contentTypeColor.opacity(0.1))
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: contentTypeIconName)
                    .font(.caption)
                    .foregroundStyle(contentTypeColor)
            }
    }
    
    private var contentTypeColor: Color {
        switch node.contentType {
        case .aiTag: return Colors.indigo
        case .subsystem: return Colors.emerald
        case .entityRef: return Colors.amber
        case .nestedList: return Colors.violet
        }
    }
    
    private var contentTypeIconName: String {
        switch node.contentType {
        case .aiTag: return "tag.fill"
        case .subsystem: return "gearshape.fill"
        case .entityRef: return "person.fill"
        case .nestedList: return "list.bullet"
        }
    }
}

// MARK: - Child Node Row

private struct ChildNodeRow: View {
    let node: KnowledgeNode
    @ObservedObject var viewModel: DimensionProfileViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Colors.slateLight)
                .frame(width: 6, height: 6)
            
            Text(node.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Rarity indicator based on mention count
            RarityIndicator(
                rarity: MentionRarity.from(mentionCount: node.mentionCount),
                color: Colors.indigo,
                style: .compact
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Colors.slateLight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        KnowledgeNodeListScreen(
            viewModel: DimensionProfileViewModel(),
            level1: .self_,
            level2: "identity"
        )
    }
}
