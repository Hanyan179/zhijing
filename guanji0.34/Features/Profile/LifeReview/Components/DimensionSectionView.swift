import SwiftUI

// MARK: - DimensionSectionView

/// 维度区块视图 - 展示单个 L1 维度及其所有 L2/L3 内容
///
/// 设计特点：
/// - 组合 DimensionHeader 和 Level2GroupView
/// - 支持节点点击回调
/// - 使用维度主题色
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// DimensionSectionView(
///     dimension: populatedDimension,
///     onNodeTap: { node in
///         selectedNode = node
///     }
/// )
/// ```
///
/// - SeeAlso: `PopulatedDimension` 有数据的维度模型
/// - SeeAlso: `DimensionHeader` 维度标题组件
/// - SeeAlso: `Level2GroupView` L2 分组视图
/// - Requirements: REQ-1.1, REQ-2.2
public struct DimensionSectionView: View {
    
    // MARK: - Properties
    
    /// 有数据的维度
    let dimension: PopulatedDimension
    
    /// 节点点击回调
    let onNodeTap: (KnowledgeNode) -> Void
    
    /// 是否显示维度标题
    var showHeader: Bool = true
    
    /// L2 分组之间的间距
    var groupSpacing: CGFloat = 20
    
    /// 是否使用可展开的 L2 分组
    var useExpandableGroups: Bool = false
    
    /// 可展开分组默认显示的节点数量
    var expandableDefaultCount: Int = 6
    
    // MARK: - Initialization
    
    /// 创建维度区块视图
    /// - Parameters:
    ///   - dimension: 有数据的维度
    ///   - onNodeTap: 节点点击回调
    public init(
        dimension: PopulatedDimension,
        onNodeTap: @escaping (KnowledgeNode) -> Void
    ) {
        self.dimension = dimension
        self.onNodeTap = onNodeTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // L1 维度标题
            if showHeader {
                DimensionHeader(dimension: dimension)
            }
            
            // L2 分组列表
            VStack(alignment: .leading, spacing: groupSpacing) {
                ForEach(dimension.level2Groups) { group in
                    groupView(for: group)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(dimension.displayName)维度，共\(dimension.totalNodeCount)个知识节点")
    }
    
    // MARK: - Subviews
    
    /// 根据配置返回对应的分组视图
    @ViewBuilder
    private func groupView(for group: Level2Group) -> some View {
        if useExpandableGroups && group.nodeCount > expandableDefaultCount {
            Level2GroupExpandableView(
                group: group,
                color: dimension.color,
                defaultVisibleCount: expandableDefaultCount,
                onNodeTap: onNodeTap
            )
        } else {
            Level2GroupView(
                group: group,
                color: dimension.color,
                onNodeTap: onNodeTap
            )
        }
    }
}

// MARK: - DimensionSectionView Modifiers

extension DimensionSectionView {
    
    /// 设置是否显示维度标题
    /// - Parameter show: 是否显示
    /// - Returns: 修改后的视图
    public func showHeader(_ show: Bool) -> DimensionSectionView {
        var view = self
        view.showHeader = show
        return view
    }
    
    /// 设置 L2 分组之间的间距
    /// - Parameter spacing: 间距值
    /// - Returns: 修改后的视图
    public func groupSpacing(_ spacing: CGFloat) -> DimensionSectionView {
        var view = self
        view.groupSpacing = spacing
        return view
    }
    
    /// 启用可展开的 L2 分组
    /// - Parameters:
    ///   - enabled: 是否启用
    ///   - defaultCount: 默认显示的节点数量
    /// - Returns: 修改后的视图
    public func expandableGroups(_ enabled: Bool, defaultCount: Int = 6) -> DimensionSectionView {
        var view = self
        view.useExpandableGroups = enabled
        view.expandableDefaultCount = defaultCount
        return view
    }
}

// MARK: - DimensionSectionCompactView

/// 维度区块紧凑视图 - 不显示标题，仅显示内容
///
/// 适用于已有外部标题或空间有限的场景
public struct DimensionSectionCompactView: View {
    
    let dimension: PopulatedDimension
    let onNodeTap: (KnowledgeNode) -> Void
    
    public init(
        dimension: PopulatedDimension,
        onNodeTap: @escaping (KnowledgeNode) -> Void
    ) {
        self.dimension = dimension
        self.onNodeTap = onNodeTap
    }
    
    public var body: some View {
        DimensionSectionView(
            dimension: dimension,
            onNodeTap: onNodeTap
        )
        .showHeader(false)
    }
}

// MARK: - Preview

#if DEBUG
struct DimensionSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Standard DimensionSectionView
                Group {
                    Text("Standard DimensionSectionView")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionSectionView(
                        dimension: sampleDimension,
                        onNodeTap: { node in
                            print("Tapped: \(node.name)")
                        }
                    )
                }
                
                Divider()
                
                // Compact View (No Header)
                Group {
                    Text("Compact View (No Header)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionSectionCompactView(
                        dimension: sampleDimension,
                        onNodeTap: { _ in }
                    )
                }
                
                Divider()
                
                // Expandable Groups
                Group {
                    Text("Expandable Groups")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionSectionView(
                        dimension: largeDimension,
                        onNodeTap: { _ in }
                    )
                    .expandableGroups(true, defaultCount: 4)
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("DimensionSectionView Variants")
    }
    
    // Sample Data
    static var sampleDimension: PopulatedDimension {
        PopulatedDimension(
            level1: .achievements,
            level2Groups: [
                Level2Group(
                    level2: "competencies",
                    displayName: "个人能力",
                    nodes: [
                        KnowledgeNode(
                            nodeType: "achievements.competencies.professional_skills",
                            contentType: .aiTag,
                            name: "Swift 编程"
                        ),
                        KnowledgeNode(
                            nodeType: "achievements.competencies.professional_skills",
                            contentType: .aiTag,
                            name: "SwiftUI"
                        ),
                        KnowledgeNode(
                            nodeType: "achievements.competencies.professional_skills",
                            contentType: .aiTag,
                            name: "iOS 开发"
                        )
                    ]
                ),
                Level2Group(
                    level2: "career",
                    displayName: "事业发展",
                    nodes: [
                        KnowledgeNode(
                            nodeType: "achievements.career.work_experience",
                            contentType: .aiTag,
                            name: "高级工程师"
                        ),
                        KnowledgeNode(
                            nodeType: "achievements.career.work_experience",
                            contentType: .aiTag,
                            name: "技术负责人"
                        )
                    ]
                )
            ],
            color: DimensionColors.color(for: .achievements),
            icon: DimensionIcons.icon(for: .achievements)
        )
    }
    
    static var largeDimension: PopulatedDimension {
        PopulatedDimension(
            level1: .experiences,
            level2Groups: [
                Level2Group(
                    level2: "culture_entertainment",
                    displayName: "文化娱乐",
                    nodes: (1...12).map { i in
                        KnowledgeNode(
                            nodeType: "experiences.culture_entertainment.reading",
                            contentType: .aiTag,
                            name: "书籍 \(i)"
                        )
                    }
                )
            ],
            color: DimensionColors.color(for: .experiences),
            icon: DimensionIcons.icon(for: .experiences)
        )
    }
}
#endif
