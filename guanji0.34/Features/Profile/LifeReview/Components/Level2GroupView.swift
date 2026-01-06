import SwiftUI

// MARK: - Level2GroupView

/// L2 分组视图 - 显示 Level 2 维度下的所有节点
///
/// 设计特点：
/// - 显示 L2 维度标题
/// - 使用 FlowLayout 布局节点卡片
/// - 支持节点点击回调
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// Level2GroupView(
///     group: level2Group,
///     color: .blue,
///     onNodeTap: { node in
///         print("Tapped: \(node.name)")
///     }
/// )
/// ```
///
/// - SeeAlso: `Level2Group` L2 分组数据模型
/// - SeeAlso: `KnowledgeNodeCard` 节点卡片组件
/// - Requirements: REQ-2.2, REQ-4
public struct Level2GroupView: View {
    
    // MARK: - Properties
    
    /// L2 分组数据
    let group: Level2Group
    
    /// 主题色
    let color: Color
    
    /// 节点点击回调
    let onNodeTap: (KnowledgeNode) -> Void
    
    /// 是否显示标题
    var showTitle: Bool = true
    
    /// 节点间距
    var spacing: CGFloat = 8
    
    // MARK: - Initialization
    
    /// 创建 L2 分组视图
    /// - Parameters:
    ///   - group: L2 分组数据
    ///   - color: 主题色
    ///   - onNodeTap: 节点点击回调
    public init(
        group: Level2Group,
        color: Color,
        onNodeTap: @escaping (KnowledgeNode) -> Void
    ) {
        self.group = group
        self.color = color
        self.onNodeTap = onNodeTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // L2 标题
            if showTitle {
                titleView
            }
            
            // 节点列表
            nodesView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 标题视图
    private var titleView: some View {
        HStack(spacing: 8) {
            // 标题文本
            Text(group.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            // 节点数量
            Text("(\(group.nodeCount))")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.displayName)，共\(group.nodeCount)个节点")
    }
    
    /// 节点列表视图
    private var nodesView: some View {
        nodesContent
    }
    
    /// 节点内容视图 - 根据类型分组布局
    private var nodesContent: some View {
        let aiTagNodes = group.nodes.filter { $0.contentType == .aiTag }
        let otherNodes = group.nodes.filter { $0.contentType != .aiTag }
        
        return VStack(alignment: .leading, spacing: spacing) {
            // AI 标签使用流式布局
            if !aiTagNodes.isEmpty {
                FlowLayoutView(spacing: spacing) {
                    ForEach(aiTagNodes) { node in
                        KnowledgeNodeCard(
                            node: node,
                            color: color,
                            onTap: { onNodeTap(node) }
                        )
                    }
                }
            }
            
            // 其他类型（subsystem、entityRef、nestedList）单独占一行
            ForEach(otherNodes) { node in
                KnowledgeNodeCard(
                    node: node,
                    color: color,
                    onTap: { onNodeTap(node) }
                )
            }
        }
    }
    
    /// 流式布局节点（保留兼容）
    private var flowLayoutNodes: some View {
        nodesContent
    }
    
    /// 垂直布局节点（保留兼容）
    private var verticalLayoutNodes: some View {
        nodesContent
    }
}

// MARK: - Level2GroupView Modifiers

extension Level2GroupView {
    
    /// 设置是否显示标题
    /// - Parameter show: 是否显示
    /// - Returns: 修改后的视图
    public func showTitle(_ show: Bool) -> Level2GroupView {
        var view = self
        view.showTitle = show
        return view
    }
    
    /// 设置节点间距
    /// - Parameter spacing: 间距值
    /// - Returns: 修改后的视图
    public func nodeSpacing(_ spacing: CGFloat) -> Level2GroupView {
        var view = self
        view.spacing = spacing
        return view
    }
}

// MARK: - Level2GroupCompactView

/// L2 分组紧凑视图 - 仅显示节点，不显示标题
///
/// 适用于空间有限或已有外部标题的场景
public struct Level2GroupCompactView: View {
    
    let group: Level2Group
    let color: Color
    let onNodeTap: (KnowledgeNode) -> Void
    
    public init(
        group: Level2Group,
        color: Color,
        onNodeTap: @escaping (KnowledgeNode) -> Void
    ) {
        self.group = group
        self.color = color
        self.onNodeTap = onNodeTap
    }
    
    public var body: some View {
        Level2GroupView(
            group: group,
            color: color,
            onNodeTap: onNodeTap
        )
        .showTitle(false)
    }
}

// MARK: - Level2GroupExpandableView

/// L2 分组可展开视图 - 支持展开/收起
///
/// 适用于节点数量较多的场景
public struct Level2GroupExpandableView: View {
    
    let group: Level2Group
    let color: Color
    let onNodeTap: (KnowledgeNode) -> Void
    
    /// 默认显示的节点数量
    var defaultVisibleCount: Int = 6
    
    @State private var isExpanded: Bool = false
    
    public init(
        group: Level2Group,
        color: Color,
        defaultVisibleCount: Int = 6,
        onNodeTap: @escaping (KnowledgeNode) -> Void
    ) {
        self.group = group
        self.color = color
        self.defaultVisibleCount = defaultVisibleCount
        self.onNodeTap = onNodeTap
    }
    
    /// 是否需要展开功能
    private var needsExpansion: Bool {
        group.nodes.count > defaultVisibleCount
    }
    
    /// 当前显示的节点
    private var visibleNodes: [KnowledgeNode] {
        if isExpanded || !needsExpansion {
            return group.nodes
        } else {
            return Array(group.nodes.prefix(defaultVisibleCount))
        }
    }
    
    /// 隐藏的节点数量
    private var hiddenCount: Int {
        max(0, group.nodes.count - defaultVisibleCount)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            titleView
            
            // 节点列表
            FlowLayoutView(spacing: 8) {
                ForEach(visibleNodes) { node in
                    KnowledgeNodeCard(
                        node: node,
                        color: color,
                        onTap: { onNodeTap(node) }
                    )
                }
            }
            
            // 展开/收起按钮
            if needsExpansion {
                expandButton
            }
        }
    }
    
    /// 标题视图
    private var titleView: some View {
        HStack(spacing: 8) {
            Text(group.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("(\(group.nodeCount))")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
    }
    
    /// 展开/收起按钮
    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded ? "收起" : "展开更多 (\(hiddenCount))")
                    .font(.caption)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "收起列表" : "展开更多\(hiddenCount)个节点")
        .accessibilityHint(isExpanded ? "双击收起节点列表" : "双击展开查看更多节点")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct Level2GroupView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Basic Level2GroupView
                Group {
                    Text("Basic Level2GroupView")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Level2GroupView(
                        group: sampleGroup,
                        color: .blue,
                        onNodeTap: { _ in }
                    )
                }
                
                Divider()
                
                // Compact View
                Group {
                    Text("Compact View (No Title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Level2GroupCompactView(
                        group: sampleGroup,
                        color: .green,
                        onNodeTap: { _ in }
                    )
                }
                
                Divider()
                
                // Expandable View
                Group {
                    Text("Expandable View")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Level2GroupExpandableView(
                        group: largeGroup,
                        color: .orange,
                        defaultVisibleCount: 4,
                        onNodeTap: { _ in }
                    )
                }
                
                Divider()
                
                // Mixed Content Types
                Group {
                    Text("Mixed Content Types")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Level2GroupView(
                        group: mixedGroup,
                        color: .purple,
                        onNodeTap: { _ in }
                    )
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
    
    // Sample Data
    static var sampleGroup: Level2Group {
        Level2Group(
            level2: "professional_skills",
            displayName: "专业技能",
            nodes: [
                KnowledgeNode(nodeType: "achievements.competencies.professional_skills", contentType: .aiTag, name: "Swift"),
                KnowledgeNode(nodeType: "achievements.competencies.professional_skills", contentType: .aiTag, name: "SwiftUI"),
                KnowledgeNode(nodeType: "achievements.competencies.professional_skills", contentType: .aiTag, name: "iOS 开发"),
                KnowledgeNode(nodeType: "achievements.competencies.professional_skills", contentType: .aiTag, name: "产品设计")
            ]
        )
    }
    
    static var largeGroup: Level2Group {
        Level2Group(
            level2: "professional_skills",
            displayName: "专业技能",
            nodes: (1...10).map { i in
                KnowledgeNode(
                    nodeType: "achievements.competencies.professional_skills",
                    contentType: .aiTag,
                    name: "技能 \(i)"
                )
            }
        )
    }
    
    static var mixedGroup: Level2Group {
        Level2Group(
            level2: "identity",
            displayName: "身份认同",
            nodes: [
                KnowledgeNode(nodeType: "self.identity.social_roles", contentType: .aiTag, name: "父亲"),
                KnowledgeNode(nodeType: "self.identity.social_roles", contentType: .aiTag, name: "工程师"),
                KnowledgeNode(
                    nodeType: "self.identity.personal_info",
                    contentType: .subsystem,
                    name: "个人信息",
                    description: "基础信息",
                    attributes: ["blood_type": .string("A"), "zodiac": .string("狮子座")]
                )
            ]
        )
    }
}
#endif
