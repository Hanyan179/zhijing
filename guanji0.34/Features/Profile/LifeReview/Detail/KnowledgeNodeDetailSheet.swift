import SwiftUI

// MARK: - KnowledgeNodeDetailSheet

/// 知识节点详情 Sheet - 以 Sheet 形式展示节点完整信息
///
/// 设计特点：
/// - 组合所有详情 Section（基本信息、来源、溯源链接、关联人物、子节点）
/// - 使用 `.presentationDetents([.medium, .large])` 支持多种高度
/// - 提供编辑、删除操作按钮
/// - 点击编辑按钮直接弹出编辑 Sheet（sheet over sheet）
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// .sheet(item: $selectedNode) { node in
///     KnowledgeNodeDetailSheet(
///         node: node,
///         viewModel: viewModel,
///         onDismiss: { selectedNode = nil }
///     )
/// }
/// ```
///
/// - SeeAlso: `NodeBasicInfoSection` 基本信息区块
/// - SeeAlso: `NodeSourceSection` 来源信息区块
/// - SeeAlso: `SourceLinksSection` 溯源链接区块
/// - SeeAlso: `RelatedEntitiesSection` 关联人物区块
/// - SeeAlso: `ChildNodesSection` 子节点区块
/// - SeeAlso: `KnowledgeNodeEditSheet` 编辑 Sheet
/// - Requirements: REQ-7, REQ-1.2, REQ-4.1, REQ-4.2
public struct KnowledgeNodeDetailSheet: View {
    
    // MARK: - Properties
    
    /// 知识节点
    let node: KnowledgeNode
    
    /// ViewModel 引用
    @ObservedObject var viewModel: LifeReviewViewModel
    
    /// 关闭回调
    var onDismiss: (() -> Void)?
    
    /// 编辑回调
    var onEdit: ((KnowledgeNode) -> Void)?
    
    /// 溯源链接点击回调
    var onSourceLinkTap: ((SourceLink) -> Void)?
    
    /// 关联人物点击回调
    var onEntityTap: ((String) -> Void)?
    
    /// 子节点点击回调
    var onChildNodeTap: ((KnowledgeNode) -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    /// 是否显示删除确认弹窗
    @State private var showDeleteConfirmation: Bool = false
    
    /// 是否显示编辑 Sheet
    @State private var showEditSheet: Bool = false
    
    // MARK: - Computed Properties
    
    /// 主题色（根据维度）
    private var themeColor: Color {
        if let level1 = node.level1Dimension {
            return DimensionColors.color(for: level1)
        }
        return .blue
    }
    
    /// 是否有子节点
    private var hasChildNodes: Bool {
        if let childIds = node.childNodeIds, !childIds.isEmpty {
            return true
        }
        return false
    }
    
    // MARK: - Initialization
    
    /// 创建知识节点详情 Sheet
    /// - Parameters:
    ///   - node: 知识节点
    ///   - viewModel: LifeReviewViewModel 实例
    ///   - onDismiss: 关闭回调
    ///   - onEdit: 编辑回调
    ///   - onSourceLinkTap: 溯源链接点击回调
    ///   - onEntityTap: 关联人物点击回调
    ///   - onChildNodeTap: 子节点点击回调
    public init(
        node: KnowledgeNode,
        viewModel: LifeReviewViewModel,
        onDismiss: (() -> Void)? = nil,
        onEdit: ((KnowledgeNode) -> Void)? = nil,
        onSourceLinkTap: ((SourceLink) -> Void)? = nil,
        onEntityTap: ((String) -> Void)? = nil,
        onChildNodeTap: ((KnowledgeNode) -> Void)? = nil
    ) {
        self.node = node
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.onEdit = onEdit
        self.onSourceLinkTap = onSourceLinkTap
        self.onEntityTap = onEntityTap
        self.onChildNodeTap = onChildNodeTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 基本信息
                    NodeBasicInfoSection(node: node, color: themeColor)
                    
                    // 属性详情（subsystem 类型节点）
                    if !node.attributes.isEmpty {
                        Divider()
                        NodeAttributesSection(
                            attributes: node.attributes,
                            color: themeColor
                        )
                    }
                    
                    Divider()
                    
                    // 来源信息
                    NodeSourceSection(node: node, color: themeColor)
                    
                    // 溯源链接
                    if !node.sourceLinks.isEmpty {
                        Divider()
                        SourceLinksSection(
                            sourceLinks: node.sourceLinks,
                            color: themeColor,
                            onLinkTap: onSourceLinkTap
                        )
                    }
                    
                    // 关联人物
                    if !node.relatedEntityIds.isEmpty {
                        Divider()
                        RelatedEntitiesSection(
                            entityIds: node.relatedEntityIds,
                            color: themeColor,
                            onEntityTap: onEntityTap
                        )
                    }
                    
                    // 子节点
                    if hasChildNodes {
                        Divider()
                        ChildNodesSection(
                            childIds: node.childNodeIds ?? [],
                            color: themeColor,
                            nodeProvider: { viewModel.getNode(id: $0) },
                            onNodeTap: onChildNodeTap
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 关闭按钮
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismissSheet()
                    }
                }
                
                // 操作菜单
                ToolbarItem(placement: .primaryAction) {
                    actionMenu
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("删除节点", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteNode()
            }
        } message: {
            Text("确定要删除「\(node.name)」吗？此操作无法撤销。")
        }
        // 编辑 Sheet（在详情 Sheet 上方弹出）
        .sheet(isPresented: $showEditSheet) {
            KnowledgeNodeEditSheet(
                originalNode: node,
                viewModel: viewModel,
                onSave: { _ in
                    // ViewModel 会自动更新，详情页会自动刷新
                },
                onCancel: nil
            )
        }
    }
    
    // MARK: - Subviews
    
    /// 操作菜单
    private var actionMenu: some View {
        Menu {
            // 编辑按钮 - 直接显示编辑 Sheet
            Button {
                showEditSheet = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            
            Divider()
            
            // 删除按钮
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
        .accessibilityLabel("更多操作")
        .accessibilityHint("双击打开操作菜单，包含编辑和删除选项")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Actions
    
    /// 关闭 Sheet
    private func dismissSheet() {
        onDismiss?()
        dismiss()
    }
    
    /// 删除节点
    private func deleteNode() {
        viewModel.deleteNode(nodeId: node.id)
        dismissSheet()
    }
}


// MARK: - KnowledgeNodeDetailSheet Convenience Initializer

extension KnowledgeNodeDetailSheet {
    
    /// 简化初始化器 - 只需要节点和 ViewModel
    /// - Parameters:
    ///   - node: 知识节点
    ///   - viewModel: LifeReviewViewModel 实例
    public init(node: KnowledgeNode, viewModel: LifeReviewViewModel) {
        self.init(
            node: node,
            viewModel: viewModel,
            onDismiss: nil,
            onEdit: nil,
            onSourceLinkTap: nil,
            onEntityTap: nil,
            onChildNodeTap: nil
        )
    }
}

// MARK: - KnowledgeNode Identifiable Conformance

extension KnowledgeNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: KnowledgeNode, rhs: KnowledgeNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#if DEBUG
struct KnowledgeNodeDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 完整节点（有所有信息）
            KnowledgeNodeDetailSheet(
                node: sampleFullNode,
                viewModel: LifeReviewViewModel()
            )
            .previewDisplayName("完整节点")
            
            // AI 提取节点（需要确认）
            KnowledgeNodeDetailSheet(
                node: sampleAINode,
                viewModel: LifeReviewViewModel()
            )
            .previewDisplayName("AI 提取节点")
            
            // 简单节点
            KnowledgeNodeDetailSheet(
                node: sampleSimpleNode,
                viewModel: LifeReviewViewModel()
            )
            .previewDisplayName("简单节点")
            
            // 嵌套列表节点
            KnowledgeNodeDetailSheet(
                node: sampleNestedNode,
                viewModel: LifeReviewViewModel()
            )
            .previewDisplayName("嵌套列表节点")
        }
    }
    
    // MARK: - Sample Data
    
    static var sampleFullNode: KnowledgeNode {
        KnowledgeNode(
            id: "node_001",
            nodeType: "achievements.competencies.professional_skills",
            contentType: .aiTag,
            name: "Swift 编程",
            description: "iOS 开发主力语言，熟练掌握 SwiftUI、Combine 等现代框架，有多年实战经验。",
            tags: ["编程", "iOS", "移动开发", "技术"],
            sourceLinks: [
                SourceLink(
                    sourceType: "diary",
                    sourceId: "diary_001",
                    dayId: "2024-12-15",
                    snippet: "今天开始学习 Swift 编程，感觉这门语言设计得很优雅。",
                    relevanceScore: 0.95
                ),
                SourceLink(
                    sourceType: "conversation",
                    sourceId: "conv_002",
                    dayId: "2024-12-20",
                    snippet: "和小明讨论了 iOS 开发的技术栈选择。",
                    relevanceScore: 0.85,
                    relatedEntityIds: ["REL_001"]
                )
            ],
            relatedEntityIds: ["REL_001_张三", "REL_002_李四"],
            tracking: NodeTracking(
                source: NodeSource(type: .aiExtracted, confidence: 0.85),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 30),
                    lastUpdated: Date().addingTimeInterval(-86400 * 2)
                ),
                verification: NodeVerification(confirmedByUser: false, needsReview: false)
            )
        )
    }
    
    static var sampleAINode: KnowledgeNode {
        KnowledgeNode(
            id: "node_002",
            nodeType: "self.personality.self_assessment",
            contentType: .aiTag,
            name: "完美主义",
            description: "追求细节和高标准，有时会因此感到压力。",
            tracking: NodeTracking(
                source: NodeSource(type: .aiInferred, confidence: 0.55),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 3),
                    lastUpdated: Date()
                ),
                verification: NodeVerification(confirmedByUser: false, needsReview: true)
            )
        )
    }
    
    static var sampleSimpleNode: KnowledgeNode {
        KnowledgeNode(
            id: "node_003",
            nodeType: "spirit.ideology.values",
            contentType: .aiTag,
            name: "家庭优先",
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 60),
                    lastUpdated: Date().addingTimeInterval(-86400 * 30),
                    lastConfirmed: Date().addingTimeInterval(-86400 * 30)
                ),
                verification: NodeVerification(confirmedByUser: true, needsReview: false)
            )
        )
    }
    
    static var sampleNestedNode: KnowledgeNode {
        KnowledgeNode(
            id: "node_004",
            nodeType: "experiences.culture_entertainment.reading",
            contentType: .nestedList,
            name: "阅读书单",
            description: "我喜欢阅读的书籍列表",
            childNodeIds: ["child_001", "child_002", "child_003"],
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                verification: NodeVerification(confirmedByUser: true)
            )
        )
    }
    
    static var sampleChildNodes: [KnowledgeNode] {
        [
            KnowledgeNode(
                id: "child_001",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《三体》",
                description: "刘慈欣的科幻巨作",
                parentNodeId: "node_004",
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.9))
            ),
            KnowledgeNode(
                id: "child_002",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《人类简史》",
                description: "尤瓦尔·赫拉利的历史著作",
                parentNodeId: "node_004",
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.85))
            ),
            KnowledgeNode(
                id: "child_003",
                nodeType: "experiences.culture_entertainment.reading",
                contentType: .aiTag,
                name: "《原则》",
                description: "瑞·达利欧的人生和工作原则",
                parentNodeId: "node_004",
                tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
            )
        ]
    }
}
#endif
