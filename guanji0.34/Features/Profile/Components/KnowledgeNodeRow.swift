import SwiftUI

// MARK: - KnowledgeNodeRow
// Task 10.2: 节点行组件
// 显示节点名称、contentType 图标、稀有度指示器（基于关联次数）
// ai_tag: sparkles 图标
// subsystem: gearshape 图标
// entity_ref: person.fill 图标
// nested_list: list.bullet 图标

/// Knowledge node row component for displaying node in a list
public struct KnowledgeNodeRow: View {
    
    // MARK: - Properties
    
    let node: KnowledgeNode
    let showRarity: Bool
    let onTap: (() -> Void)?
    
    /// 节点的稀有度等级
    private var rarity: MentionRarity {
        MentionRarity.from(mentionCount: node.mentionCount)
    }
    
    // MARK: - Initialization
    
    public init(
        node: KnowledgeNode,
        showRarity: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.node = node
        self.showRarity = showRarity
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Content type icon
                contentTypeIcon
                
                // Node info
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.name)
                        .font(.subheadline)
                        .fontWeight(rarity.fontWeight)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let description = node.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Tags (if any)
                    if !node.tags.isEmpty {
                        tagsView
                    }
                }
                
                Spacer()
                
                // Rarity indicator (replaces confidence badge)
                if showRarity && rarity != .none {
                    RarityIndicator(rarity: rarity, color: contentTypeColor, style: .compact)
                }
                
                // Chevron
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(contentTypeColor.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    // MARK: - Content Type Icon
    
    private var contentTypeIcon: some View {
        Circle()
            .fill(contentTypeColor.opacity(rarity.iconBackgroundOpacity))
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: contentTypeIconName)
                    .font(.body)
                    .foregroundStyle(contentTypeColor)
            }
    }
    
    private var contentTypeIconName: String {
        switch node.contentType {
        case .aiTag: return "sparkles"
        case .subsystem: return "gearshape"
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
    
    // MARK: - Tags View
    
    private var tagsView: some View {
        HStack(spacing: 4) {
            ForEach(node.tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Colors.indigo.opacity(0.1))
                    .foregroundStyle(Colors.indigo)
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

// MARK: - Preview

#Preview("AI Tag Node - Different Rarities") {
    VStack(spacing: 8) {
        // 核心 (12次关联)
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "self.personality.self_assessment",
                contentType: .aiTag,
                name: "内向型人格",
                description: "倾向于独处，在安静的环境中更能集中精力",
                tags: ["性格", "MBTI", "内向"],
                sourceLinks: (0..<12).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                },
                tracking: NodeTracking(
                    source: NodeSource(type: .aiExtracted, confidence: 0.85)
                )
            )
        ) {}
        
        // 常见 (4次关联)
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "Swift 编程",
                description: "熟练掌握 Swift 语言和 iOS 开发",
                tags: ["技能", "编程"],
                sourceLinks: (0..<4).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                },
                tracking: NodeTracking(
                    source: NodeSource(type: .aiExtracted, confidence: 0.65)
                )
            )
        ) {}
        
        // 无关联
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "数据分析",
                description: "用户手动添加的技能",
                tags: ["技能"],
                sourceLinks: [],
                tracking: NodeTracking(
                    source: NodeSource(type: .userInput, confidence: 1.0)
                )
            )
        ) {}
    }
    .padding()
}

#Preview("Different Content Types") {
    VStack(spacing: 8) {
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "self.identity.personal_info",
                contentType: .subsystem,
                name: "个人基本信息",
                description: "姓名、血型、生日等基础信息",
                sourceLinks: (0..<8).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                }
            )
        ) {}
        
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "relationships.family",
                contentType: .entityRef,
                name: "家人",
                description: "关联的家庭成员",
                sourceLinks: (0..<3).map { i in
                    SourceLink(sourceType: "conversation", sourceId: "c\(i)", dayId: "2024-12-\(i+1)")
                }
            )
        ) {}
        
        KnowledgeNodeRow(
            node: KnowledgeNode(
                nodeType: "experiences.culture_entertainment",
                contentType: .nestedList,
                name: "阅读书单",
                description: "包含多本书籍的阅读记录",
                sourceLinks: (0..<15).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                }
            )
        ) {}
    }
    .padding()
}
