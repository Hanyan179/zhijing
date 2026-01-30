import SwiftUI

// MARK: - ChildNodesSection

/// 子节点区块 - 显示嵌套列表的子节点
///
/// 设计特点：
/// - 显示子节点列表
/// - 支持点击查看子节点详情
/// - 显示子节点的基本信息和稀有度（基于关联次数）
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// ChildNodesSection(
///     childIds: node.childNodeIds ?? [],
///     color: .blue,
///     nodeProvider: { id in viewModel.getNode(id: id) },
///     onNodeTap: { node in
///         // 显示子节点详情
///     }
/// )
/// ```
///
/// - SeeAlso: `KnowledgeNode` 知识节点模型
/// - SeeAlso: `MentionRarity` 关联次数稀有度
/// - Requirements: REQ-7.5
public struct ChildNodesSection: View {
    
    // MARK: - Properties
    
    /// 子节点 ID 列表
    let childIds: [String]
    
    /// 主题色
    let color: Color
    
    /// 节点提供者（根据 ID 获取节点）
    var nodeProvider: ((String) -> KnowledgeNode?)?
    
    /// 节点点击回调
    var onNodeTap: ((KnowledgeNode) -> Void)?
    
    // MARK: - Computed Properties
    
    /// 子节点列表
    private var childNodes: [KnowledgeNode] {
        childIds.compactMap { nodeProvider?($0) }
    }
    
    // MARK: - Initialization
    
    /// 创建子节点区块
    /// - Parameters:
    ///   - childIds: 子节点 ID 列表
    ///   - color: 主题色
    ///   - nodeProvider: 节点提供者
    ///   - onNodeTap: 节点点击回调
    public init(
        childIds: [String],
        color: Color = .blue,
        nodeProvider: ((String) -> KnowledgeNode?)? = nil,
        onNodeTap: ((KnowledgeNode) -> Void)? = nil
    ) {
        self.childIds = childIds
        self.color = color
        self.nodeProvider = nodeProvider
        self.onNodeTap = onNodeTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 区块标题
            sectionHeader
            
            // 子节点列表
            if childIds.isEmpty {
                emptyStateView
            } else if nodeProvider != nil {
                childNodesListView
            } else {
                childIdsListView
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 区块标题
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "list.bullet.indent")
                .foregroundStyle(color)
            
            Text("子节点")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(childIds.count) 项")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("暂无子节点")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    /// 子节点列表视图（有节点数据）
    private var childNodesListView: some View {
        VStack(spacing: 10) {
            ForEach(childNodes) { node in
                ChildNodeRow(
                    node: node,
                    color: color,
                    onTap: {
                        onNodeTap?(node)
                    }
                )
            }
        }
    }
    
    /// 子节点 ID 列表视图（无节点数据时的降级显示）
    private var childIdsListView: some View {
        VStack(spacing: 8) {
            ForEach(childIds, id: \.self) { childId in
                ChildIdRow(
                    childId: childId,
                    color: color
                )
            }
        }
    }
}

// MARK: - ChildNodeRow

/// 子节点行组件
private struct ChildNodeRow: View {
    
    // MARK: - Properties
    
    let node: KnowledgeNode
    let color: Color
    var onTap: (() -> Void)?
    
    /// 节点的稀有度等级
    private var rarity: MentionRarity {
        MentionRarity.from(mentionCount: node.mentionCount)
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Content
    
    private var content: some View {
        HStack(spacing: 12) {
            // 内容类型图标
            iconView
            
            // 节点信息
            VStack(alignment: .leading, spacing: 4) {
                // 名称
                Text(node.name)
                    .font(.subheadline)
                    .fontWeight(rarity.fontWeight)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 描述或类型
                if let description = node.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(node.contentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 稀有度指示器（替代置信度）
            if rarity != .none {
                RarityIndicator(rarity: rarity, color: color, style: .compact)
            }
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
        )
    }
    
    /// 图标视图
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(rarity.iconBackgroundOpacity))
            
            Image(systemName: ContentTypeIcons.icon(for: node.contentType))
                .font(.caption)
                .foregroundStyle(color)
        }
        .frame(width: 32, height: 32)
    }
    
    /// 无障碍标签文本
    private var accessibilityLabelText: String {
        var label = "子节点：\(node.name)"
        if let description = node.description {
            label += "，\(description)"
        }
        label += "，\(node.contentType.displayName)"
        if node.mentionCount > 0 {
            label += "，关联\(node.mentionCount)条数据"
        }
        return label
    }
}

// MARK: - ChildIdRow

/// 子节点 ID 行组件（降级显示）
private struct ChildIdRow: View {
    
    let childId: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                
                Image(systemName: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(color)
            }
            .frame(width: 32, height: 32)
            
            // ID
            Text(childId)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // 状态指示
            Text("未加载")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - ChildNodesCompact

/// 子节点紧凑视图
///
/// 适用于空间有限的场景，只显示数量和简要信息
public struct ChildNodesCompact: View {
    
    let childIds: [String]
    let color: Color
    var onTap: (() -> Void)?
    
    public init(
        childIds: [String],
        color: Color = .blue,
        onTap: (() -> Void)? = nil
    ) {
        self.childIds = childIds
        self.color = color
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text("\(childIds.count) 个子项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(childIds.count) 个子节点")
        .accessibilityHint("双击查看全部子节点")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct ChildNodesSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 有子节点（带节点数据）
                ChildNodesSection(
                    childIds: sampleChildIds,
                    color: .blue,
                    nodeProvider: { id in
                        sampleChildNodes.first { $0.id == id }
                    },
                    onNodeTap: { node in
                        print("Tapped: \(node.name)")
                    }
                )
                
                Divider()
                
                // 有子节点（无节点数据，降级显示）
                ChildNodesSection(
                    childIds: sampleChildIds,
                    color: .orange
                )
                
                Divider()
                
                // 空状态
                ChildNodesSection(
                    childIds: [],
                    color: .purple
                )
                
                Divider()
                
                // 紧凑视图
                VStack(alignment: .leading, spacing: 12) {
                    Text("紧凑视图")
                        .font(.headline)
                    
                    ChildNodesCompact(
                        childIds: sampleChildIds,
                        color: .green
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleChildIds: [String] {
        ["child_001", "child_002", "child_003"]
    }
    
    static var sampleChildNodes: [KnowledgeNode] {
        [
            KnowledgeNode(
                id: "child_001",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《三体》",
                description: "刘慈欣的科幻巨作，震撼人心",
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.9))
            ),
            KnowledgeNode(
                id: "child_002",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《人类简史》",
                description: "尤瓦尔·赫拉利的历史著作",
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.85))
            ),
            KnowledgeNode(
                id: "child_003",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《原则》",
                description: "瑞·达利欧的人生和工作原则",
                tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
            )
        ]
    }
}
#endif
