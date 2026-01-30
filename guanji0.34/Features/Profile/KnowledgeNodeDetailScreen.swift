import SwiftUI

/// Knowledge node detail screen - displays full node information
/// Task 9.5: 创建 KnowledgeNodeDetailScreen.swift（节点详情页）
public struct KnowledgeNodeDetailScreen: View {
    @ObservedObject var viewModel: DimensionProfileViewModel
    let node: KnowledgeNode
    
    @State private var selectedSourceLink: SourceLink?
    @State private var selectedRelationId: String?
    
    public init(viewModel: DimensionProfileViewModel, node: KnowledgeNode) {
        self.viewModel = viewModel
        self.node = node
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with name and confidence
                nodeHeader
                
                // Description section
                if let description = node.description, !description.isEmpty {
                    descriptionSection(description)
                }
                
                // Tags section
                if !node.tags.isEmpty {
                    tagsSection
                }
                
                // Attributes section
                if !node.attributes.isEmpty {
                    attributesSection
                }
                
                // Source links section
                if !node.sourceLinks.isEmpty {
                    sourceLinksSection
                }
                
                // Related entities section
                if !node.relatedEntityIds.isEmpty {
                    relatedEntitiesSection
                }
                
                // Metadata section
                metadataSection
            }
            .padding()
        }
        .background(Colors.background)
        .navigationTitle(node.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Node Header
    
    private var nodeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Content type badge
                HStack(spacing: 4) {
                    Image(systemName: contentTypeIcon)
                        .font(.caption)
                    Text(node.contentType.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(contentTypeColor.opacity(0.1))
                .foregroundStyle(contentTypeColor)
                .clipShape(Capsule())
                
                Spacer()
                
                // Rarity badge (replaces confidence)
                rarityBadge
            }
            
            Text(node.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Dimension path
            if let path = node.typePath {
                Text(path.fullDisplayPath)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// 节点的稀有度等级
    private var rarity: MentionRarity {
        MentionRarity.from(mentionCount: node.mentionCount)
    }
    
    private var rarityBadge: some View {
        Group {
            if rarity != .none {
                HStack(spacing: 4) {
                    RarityIndicator(rarity: rarity, color: contentTypeColor, style: .compact)
                    Text("\(node.mentionCount) 条关联")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(contentTypeColor.opacity(0.1))
                .foregroundStyle(contentTypeColor)
                .clipShape(Capsule())
            } else {
                Text("暂无关联")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("描述", icon: "text.alignleft")
            
            Text(description)
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("标签", icon: "tag.fill")
            
            NodeDetailFlowLayout(spacing: 8) {
                ForEach(node.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Colors.indigo.opacity(0.1))
                        .foregroundStyle(Colors.indigo)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Attributes Section
    
    private var attributesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("属性", icon: "list.bullet.rectangle")
            
            VStack(spacing: 0) {
                ForEach(Array(node.attributes.keys.sorted()), id: \.self) { key in
                    if let value = node.attributes[key] {
                        AttributeRow(key: key, value: value)
                        
                        if key != node.attributes.keys.sorted().last {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Source Links Section
    
    private var sourceLinksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("来源溯源 (\(node.sourceLinks.count))", icon: "link")
            
            VStack(spacing: 8) {
                ForEach(node.sourceLinks) { link in
                    SourceLinkRow(link: link) {
                        selectedSourceLink = link
                    }
                }
            }
        }
    }
    
    // MARK: - Related Entities Section
    
    private var relatedEntitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("关联人物 (\(node.relatedEntityIds.count))", icon: "person.2.fill")
            
            VStack(spacing: 8) {
                ForEach(node.relatedEntityIds, id: \.self) { entityId in
                    RelatedEntityRow(entityId: entityId) {
                        selectedRelationId = entityId
                    }
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("元数据", icon: "info.circle")
            
            VStack(spacing: 0) {
                MetadataRow(label: "节点ID", value: node.id)
                Divider().padding(.horizontal)
                MetadataRow(label: "节点类型", value: node.nodeType)
                Divider().padding(.horizontal)
                MetadataRow(label: "节点分类", value: node.nodeCategory == .common ? "通用" : "个人")
                Divider().padding(.horizontal)
                MetadataRow(label: "关联数据", value: "\(node.mentionCount) 条")
                Divider().padding(.horizontal)
                MetadataRow(label: "创建时间", value: node.createdAt.formatted(date: .abbreviated, time: .shortened))
                Divider().padding(.horizontal)
                MetadataRow(label: "更新时间", value: node.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Colors.indigo)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
    
    private var contentTypeIcon: String {
        switch node.contentType {
        case .aiTag: return "tag.fill"
        case .subsystem: return "gearshape.fill"
        case .entityRef: return "person.fill"
        case .nestedList: return "list.bullet"
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
}

// MARK: - Attribute Row

private struct AttributeRow: View {
    let key: String
    let value: AttributeValue
    
    var body: some View {
        HStack {
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value.displayValue)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}



// MARK: - Related Entity Row

private struct RelatedEntityRow: View {
    let entityId: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Colors.amber.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Colors.amber)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("关联人物")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Text(entityId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .buttonStyle(.plain)
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding()
    }
}

// MARK: - Node Detail Flow Layout

private struct NodeDetailFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        KnowledgeNodeDetailScreen(
            viewModel: DimensionProfileViewModel(),
            node: KnowledgeNode(
                nodeType: "self.personality.self_assessment",
                name: "内向型人格",
                description: "倾向于独处，在安静的环境中更能集中精力",
                tags: ["性格", "MBTI", "内向"],
                attributes: [
                    "MBTI类型": .string("INTJ"),
                    "社交偏好": .string("小群体")
                ],
                sourceLinks: [
                    SourceLink(
                        sourceType: "diary",
                        sourceId: "entry_001",
                        dayId: "2024-12-30",
                        snippet: "今天参加了一个大型聚会，感觉很累...",
                        relevanceScore: 0.85
                    )
                ]
            )
        )
    }
}
