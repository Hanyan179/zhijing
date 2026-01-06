import SwiftUI

// MARK: - KnowledgeNodeCard

/// 知识节点卡片组件 - 根据 ContentType 差异化展示节点
///
/// 设计特点：
/// - 根据 NodeContentType 使用不同的展示样式
/// - 根据关联次数（mentionCount）显示不同的视觉强度（稀有度机制）
/// - 支持点击交互
/// - 支持 VoiceOver 无障碍访问
///
/// 稀有度等级（基于关联次数）：
/// - 普通 (1-2次): 基础样式
/// - 常见 (3-5次): 轻微强调
/// - 重要 (6-10次): 中等强调
/// - 核心 (11+次): 高度强调
///
/// ContentType 样式：
/// - `.aiTag`: 紧凑标签样式
/// - `.subsystem`: 带描述的卡片
/// - `.entityRef`: 带头像的卡片
/// - `.nestedList`: 可展开样式
///
/// 使用示例：
/// ```swift
/// KnowledgeNodeCard(
///     node: node,
///     color: .blue,
///     onTap: { print("Tapped: \(node.name)") }
/// )
/// ```
///
/// - SeeAlso: `NodeContentType` 节点内容类型
/// - SeeAlso: `MentionRarity` 关联次数稀有度
/// - Requirements: REQ-4.2, REQ-4.3, REQ-4.4
public struct KnowledgeNodeCard: View {
    
    // MARK: - Properties
    
    /// 知识节点
    let node: KnowledgeNode
    
    /// 主题色
    let color: Color
    
    /// 点击回调
    let onTap: () -> Void
    
    // MARK: - Computed Properties
    
    /// 节点的稀有度等级
    private var rarity: MentionRarity {
        MentionRarity.from(mentionCount: node.mentionCount)
    }
    
    // MARK: - Initialization
    
    /// 创建知识节点卡片
    /// - Parameters:
    ///   - node: 知识节点
    ///   - color: 主题色
    ///   - onTap: 点击回调
    public init(
        node: KnowledgeNode,
        color: Color,
        onTap: @escaping () -> Void
    ) {
        self.node = node
        self.color = color
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var content: some View {
        switch node.contentType {
        case .aiTag:
            AITagCardStyle(node: node, color: color, rarity: rarity)
        case .subsystem:
            SubsystemCardStyle(node: node, color: color, rarity: rarity)
        case .entityRef:
            EntityRefCardStyle(node: node, color: color, rarity: rarity)
        case .nestedList:
            NestedListCardStyle(node: node, color: color, rarity: rarity)
        }
    }
    
    /// 无障碍标签文本
    private var accessibilityLabelText: String {
        var label = "\(node.name)"
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

// MARK: - AI Tag Card Style

/// AI 标签样式 - 紧凑标签
///
/// 适用于 `.aiTag` 类型的节点
/// 特点：紧凑、简洁、适合大量展示
/// 稀有度通过边框粗细和背景透明度体现
private struct AITagCardStyle: View {
    let node: KnowledgeNode
    let color: Color
    let rarity: MentionRarity
    
    var body: some View {
        HStack(spacing: 6) {
            // 稀有度指示器（仅在有关联数据时显示）
            if rarity != .none {
                RarityIndicator(rarity: rarity, color: color, style: .compact)
            }
            
            Text(node.name)
                .font(.subheadline)
                .fontWeight(rarity.fontWeight)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(rarity.backgroundOpacity))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
        )
    }
}

// MARK: - Subsystem Card Style

/// 子系统样式 - 带描述的卡片
///
/// 适用于 `.subsystem` 类型的节点
/// 特点：显示更多信息、结构化展示
/// 稀有度通过边框和阴影强度体现
private struct SubsystemCardStyle: View {
    let node: KnowledgeNode
    let color: Color
    let rarity: MentionRarity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                Image(systemName: ContentTypeIcons.icon(for: .subsystem))
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(node.name)
                    .font(.subheadline)
                    .fontWeight(rarity.fontWeight)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // 稀有度指示器
                if rarity != .none {
                    RarityIndicator(rarity: rarity, color: color, style: .badge)
                }
            }
            
            // 描述
            if let description = node.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // 属性预览（最多显示 3 个）
            if !node.attributes.isEmpty {
                attributesPreview
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
        )
        .shadow(color: .black.opacity(rarity.shadowOpacity), radius: rarity.shadowRadius, x: 0, y: 1)
        .clipped()
    }
    
    /// 属性预览 - 使用 FlowLayout 显示所有属性标签
    private var attributesPreview: some View {
        FlowLayoutView(horizontalSpacing: 6, verticalSpacing: 4) {
            ForEach(Array(node.attributes), id: \.key) { key, value in
                Text("\(key): \(value.displayValue)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.06))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Entity Ref Card Style

/// 实体引用样式 - 带头像的卡片
///
/// 适用于 `.entityRef` 类型的节点
/// 特点：显示人物头像、关联信息
/// 稀有度通过边框和头像环体现
private struct EntityRefCardStyle: View {
    let node: KnowledgeNode
    let color: Color
    let rarity: MentionRarity
    
    var body: some View {
        HStack(spacing: 10) {
            // 头像占位（带稀有度环）
            avatarView
            
            // 信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(node.name)
                        .font(.subheadline)
                        .fontWeight(rarity.fontWeight)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // 稀有度指示器
                    if rarity != .none {
                        RarityIndicator(rarity: rarity, color: color, style: .compact)
                    }
                }
                
                if let description = node.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // 关联数量
                if !node.relatedEntityIds.isEmpty {
                    Text("\(node.relatedEntityIds.count) 个关联")
                        .font(.caption2)
                        .foregroundStyle(color)
                }
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
        )
        .shadow(color: .black.opacity(rarity.shadowOpacity), radius: rarity.shadowRadius, x: 0, y: 1)
    }
    
    /// 头像视图（带稀有度环）
    private var avatarView: some View {
        ZStack {
            // 稀有度外环
            if rarity.showRing {
                Circle()
                    .strokeBorder(color.opacity(rarity.ringOpacity), lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
            
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Nested List Card Style

/// 嵌套列表样式 - 可展开样式
///
/// 适用于 `.nestedList` 类型的节点
/// 特点：显示子节点数量、可展开指示
/// 稀有度通过边框和图标背景体现
private struct NestedListCardStyle: View {
    let node: KnowledgeNode
    let color: Color
    let rarity: MentionRarity
    
    /// 子节点数量
    private var childCount: Int {
        node.childNodeIds?.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // 图标（带稀有度背景）
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(rarity.iconBackgroundOpacity))
                
                Image(systemName: ContentTypeIcons.icon(for: .nestedList))
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            .frame(width: 32, height: 32)
            
            // 信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(node.name)
                        .font(.subheadline)
                        .fontWeight(rarity.fontWeight)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // 稀有度指示器
                    if rarity != .none {
                        RarityIndicator(rarity: rarity, color: color, style: .compact)
                    }
                }
                
                if childCount > 0 {
                    Text("\(childCount) 个子项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let description = node.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 展开指示
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(rarity.borderOpacity), lineWidth: rarity.borderWidth)
        )
        .shadow(color: .black.opacity(rarity.shadowOpacity), radius: rarity.shadowRadius, x: 0, y: 1)
    }
}

// MARK: - Mention Rarity

/// 关联次数稀有度等级
///
/// 基于节点的 mentionCount（关联原始数据次数）来确定视觉强度
/// 遵循 iOS 设计规范，使用微妙的视觉差异来体现重要性
public enum MentionRarity: Int, CaseIterable {
    /// 无关联数据
    case none = 0
    /// 普通 (1-2次关联)
    case common = 1
    /// 常见 (3-5次关联)
    case frequent = 2
    /// 重要 (6-10次关联)
    case important = 3
    /// 核心 (11+次关联)
    case core = 4
    
    /// 根据关联次数获取稀有度等级
    public static func from(mentionCount: Int) -> MentionRarity {
        switch mentionCount {
        case 0:
            return .none
        case 1...2:
            return .common
        case 3...5:
            return .frequent
        case 6...10:
            return .important
        default:
            return .core
        }
    }
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .none: return ""
        case .common: return "普通"
        case .frequent: return "常见"
        case .important: return "重要"
        case .core: return "核心"
        }
    }
    
    /// 字体粗细
    public var fontWeight: Font.Weight {
        switch self {
        case .none, .common: return .medium
        case .frequent: return .medium
        case .important: return .semibold
        case .core: return .bold
        }
    }
    
    /// 背景透明度
    public var backgroundOpacity: Double {
        switch self {
        case .none: return 0.08
        case .common: return 0.1
        case .frequent: return 0.12
        case .important: return 0.15
        case .core: return 0.18
        }
    }
    
    /// 边框透明度
    public var borderOpacity: Double {
        switch self {
        case .none: return 0.15
        case .common: return 0.2
        case .frequent: return 0.3
        case .important: return 0.4
        case .core: return 0.5
        }
    }
    
    /// 边框宽度
    public var borderWidth: CGFloat {
        switch self {
        case .none, .common: return 1
        case .frequent: return 1
        case .important: return 1.5
        case .core: return 2
        }
    }
    
    /// 阴影透明度
    public var shadowOpacity: Double {
        switch self {
        case .none, .common: return 0.03
        case .frequent: return 0.05
        case .important: return 0.08
        case .core: return 0.1
        }
    }
    
    /// 阴影半径
    public var shadowRadius: CGFloat {
        switch self {
        case .none, .common: return 2
        case .frequent: return 3
        case .important: return 4
        case .core: return 5
        }
    }
    
    /// 图标背景透明度
    public var iconBackgroundOpacity: Double {
        switch self {
        case .none: return 0.1
        case .common: return 0.15
        case .frequent: return 0.18
        case .important: return 0.22
        case .core: return 0.25
        }
    }
    
    /// 是否显示外环
    public var showRing: Bool {
        switch self {
        case .none, .common: return false
        case .frequent, .important, .core: return true
        }
    }
    
    /// 外环透明度
    public var ringOpacity: Double {
        switch self {
        case .none, .common: return 0
        case .frequent: return 0.3
        case .important: return 0.5
        case .core: return 0.7
        }
    }
}

// MARK: - RarityIndicator

/// 稀有度指示器组件
///
/// 用于在节点卡片中显示关联次数的视觉指示
/// 遵循 iOS 设计规范，使用微妙的视觉元素
public struct RarityIndicator: View {
    
    /// 显示样式
    public enum DisplayStyle {
        /// 紧凑模式 - 小圆点
        case compact
        /// 徽章模式 - 带数字的小徽章
        case badge
    }
    
    let rarity: MentionRarity
    let color: Color
    let style: DisplayStyle
    
    public var body: some View {
        switch style {
        case .compact:
            compactView
        case .badge:
            badgeView
        }
    }
    
    /// 紧凑视图 - 小圆点指示器
    private var compactView: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(rarity.rawValue, 4), id: \.self) { index in
                Circle()
                    .fill(color.opacity(dotOpacity(for: index)))
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .accessibilityLabel("\(rarity.displayName)，关联强度\(rarity.rawValue)级")
    }
    
    /// 徽章视图 - 带图标的小徽章
    private var badgeView: some View {
        HStack(spacing: 3) {
            Image(systemName: rarityIcon)
                .font(.system(size: 8, weight: .semibold))
            
            if rarity == .core {
                Text("核心")
                    .font(.system(size: 9, weight: .medium))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .accessibilityLabel("\(rarity.displayName)关键词")
    }
    
    /// 圆点大小
    private var dotSize: CGFloat {
        switch rarity {
        case .none: return 0
        case .common: return 4
        case .frequent: return 4
        case .important: return 5
        case .core: return 5
        }
    }
    
    /// 圆点透明度
    private func dotOpacity(for index: Int) -> Double {
        // 渐变效果：后面的点更亮
        let baseOpacity: Double
        switch rarity {
        case .none: baseOpacity = 0
        case .common: baseOpacity = 0.4
        case .frequent: baseOpacity = 0.5
        case .important: baseOpacity = 0.6
        case .core: baseOpacity = 0.7
        }
        return baseOpacity + Double(index) * 0.1
    }
    
    /// 稀有度图标
    private var rarityIcon: String {
        switch rarity {
        case .none: return ""
        case .common: return "circle.fill"
        case .frequent: return "star.fill"
        case .important: return "star.fill"
        case .core: return "sparkles"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct KnowledgeNodeCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                // AI Tag Style - 不同稀有度
                Group {
                    Text("AI Tag Style - 稀有度展示")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    FlowLayoutView(spacing: 8) {
                        ForEach(sampleAITagNodes) { node in
                            KnowledgeNodeCard(
                                node: node,
                                color: .blue,
                                onTap: {}
                            )
                        }
                    }
                }
                
                Divider()
                
                // Subsystem Style
                Group {
                    Text("Subsystem Style")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    KnowledgeNodeCard(
                        node: sampleSubsystemNode,
                        color: .indigo,
                        onTap: {}
                    )
                }
                
                Divider()
                
                // Entity Ref Style
                Group {
                    Text("Entity Ref Style")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    KnowledgeNodeCard(
                        node: sampleEntityRefNode,
                        color: .pink,
                        onTap: {}
                    )
                }
                
                Divider()
                
                // Nested List Style
                Group {
                    Text("Nested List Style")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    KnowledgeNodeCard(
                        node: sampleNestedListNode,
                        color: .orange,
                        onTap: {}
                    )
                }
                
                Divider()
                
                // 稀有度指示器展示
                Group {
                    Text("稀有度指示器")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        ForEach(MentionRarity.allCases.filter { $0 != .none }, id: \.rawValue) { rarity in
                            VStack(spacing: 4) {
                                RarityIndicator(rarity: rarity, color: .blue, style: .compact)
                                Text(rarity.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(MentionRarity.allCases.filter { $0 != .none }, id: \.rawValue) { rarity in
                            RarityIndicator(rarity: rarity, color: .blue, style: .badge)
                        }
                    }
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
    
    // Sample Data - 不同关联次数
    static var sampleAITagNodes: [KnowledgeNode] {
        [
            // 核心 (12次关联)
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "Swift 编程",
                description: "iOS 开发主力语言",
                sourceLinks: (0..<12).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                },
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.9))
            ),
            // 重要 (7次关联)
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "SwiftUI",
                sourceLinks: (0..<7).map { i in
                    SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
                },
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.75))
            ),
            // 常见 (4次关联)
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "产品设计",
                sourceLinks: (0..<4).map { i in
                    SourceLink(sourceType: "conversation", sourceId: "c\(i)", dayId: "2024-12-\(i+1)")
                },
                tracking: NodeTracking(source: NodeSource(type: .aiInferred, confidence: 0.5))
            ),
            // 普通 (2次关联)
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "数据分析",
                sourceLinks: [
                    SourceLink(sourceType: "diary", sourceId: "d1", dayId: "2024-12-01"),
                    SourceLink(sourceType: "diary", sourceId: "d2", dayId: "2024-12-02")
                ],
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.6))
            ),
            // 无关联
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "机器学习",
                sourceLinks: [],
                tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
            )
        ]
    }
    
    static var sampleSubsystemNode: KnowledgeNode {
        KnowledgeNode(
            nodeType: "self.identity.personal_info",
            contentType: .subsystem,
            name: "个人基础信息",
            description: "血型、星座、MBTI 等基础信息",
            attributes: [
                "血型": .string("A"),
                "星座": .string("狮子座"),
                "MBTI": .string("INTJ"),
                "身高": .int(175)
            ],
            sourceLinks: (0..<8).map { i in
                SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
            },
            tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
        )
    }
    
    static var sampleEntityRefNode: KnowledgeNode {
        KnowledgeNode(
            nodeType: "achievements.career.professional_network",
            contentType: .entityRef,
            name: "张三",
            description: "前同事，技术负责人",
            sourceLinks: (0..<5).map { i in
                SourceLink(sourceType: "conversation", sourceId: "c\(i)", dayId: "2024-12-\(i+1)")
            },
            relatedEntityIds: ["REL_001", "REL_002"],
            tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.85))
        )
    }
    
    static var sampleNestedListNode: KnowledgeNode {
        KnowledgeNode(
            nodeType: "experiences.culture_entertainment.reading",
            contentType: .nestedList,
            name: "阅读",
            description: "书籍阅读记录",
            sourceLinks: (0..<15).map { i in
                SourceLink(sourceType: "diary", sourceId: "d\(i)", dayId: "2024-12-\(i+1)")
            },
            childNodeIds: ["child_1", "child_2", "child_3"],
            tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
        )
    }
}
#endif
