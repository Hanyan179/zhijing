import SwiftUI

// MARK: - DimensionQuickNav

/// 维度快速导航组件 - 显示维度概览卡片网格
///
/// 设计特点：
/// - 使用 2x3 网格布局展示维度卡片
/// - 只显示有数据的维度
/// - 支持点击进入维度详情（锚点跳转）
/// - 显示每个维度的节点数量
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// DimensionQuickNav(
///     dimensions: populatedDimensions,
///     onSelect: { dimensionId in
///         scrollTarget = dimensionId
///     }
/// )
/// ```
///
/// - SeeAlso: `PopulatedDimension` 有数据的维度模型
/// - Requirements: REQ-1.4, REQ-3
public struct DimensionQuickNav: View {
    
    // MARK: - Properties
    
    /// 有数据的维度列表
    let dimensions: [PopulatedDimension]
    
    /// 维度选择回调（返回维度 ID 用于锚点跳转）
    let onSelect: (String) -> Void
    
    /// 网格列数
    var columns: Int = 2
    
    /// 卡片间距
    var spacing: CGFloat = 12
    
    /// 是否显示标题
    var showTitle: Bool = true
    
    // MARK: - Computed Properties
    
    /// 网格列配置
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    // MARK: - Initialization
    
    /// 创建维度快速导航组件
    /// - Parameters:
    ///   - dimensions: 有数据的维度列表
    ///   - onSelect: 维度选择回调
    public init(
        dimensions: [PopulatedDimension],
        onSelect: @escaping (String) -> Void
    ) {
        self.dimensions = dimensions
        self.onSelect = onSelect
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            if showTitle && !dimensions.isEmpty {
                titleView
            }
            
            // 维度卡片网格
            if dimensions.isEmpty {
                emptyView
            } else {
                gridView
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 标题视图
    private var titleView: some View {
        HStack {
            Text("维度概览")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(dimensions.count) 个维度")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 网格视图
    private var gridView: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(dimensions) { dimension in
                DimensionQuickNavCard(
                    dimension: dimension,
                    onTap: { onSelect(dimension.id) }
                )
            }
        }
    }
    
    /// 空状态视图
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.title)
                .foregroundStyle(.tertiary)
            
            Text("暂无维度数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - DimensionQuickNav Modifiers

extension DimensionQuickNav {
    
    /// 设置网格列数
    /// - Parameter count: 列数
    /// - Returns: 修改后的视图
    public func columns(_ count: Int) -> DimensionQuickNav {
        var view = self
        view.columns = count
        return view
    }
    
    /// 设置卡片间距
    /// - Parameter spacing: 间距值
    /// - Returns: 修改后的视图
    public func spacing(_ spacing: CGFloat) -> DimensionQuickNav {
        var view = self
        view.spacing = spacing
        return view
    }
    
    /// 设置是否显示标题
    /// - Parameter show: 是否显示
    /// - Returns: 修改后的视图
    public func showTitle(_ show: Bool) -> DimensionQuickNav {
        var view = self
        view.showTitle = show
        return view
    }
}

// MARK: - DimensionQuickNavCard

/// 维度快速导航卡片 - 单个维度的概览卡片
private struct DimensionQuickNavCard: View {
    
    let dimension: PopulatedDimension
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 图标和节点数量
                HStack {
                    // 图标
                    Image(systemName: dimension.icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(dimension.color)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(dimension.color.opacity(0.15))
                        )
                    
                    Spacer()
                    
                    // 节点数量
                    Text("\(dimension.totalNodeCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(dimension.color)
                }
                
                // 维度名称
                Text(dimension.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // L2 维度数量
                Text("\(dimension.level2Count) 个子维度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dimension.displayName)，\(dimension.totalNodeCount)个节点，\(dimension.level2Count)个子维度")
        .accessibilityHint("双击跳转到该维度")
        .accessibilityAddTraits(.isButton)
    }
    
    /// 卡片背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(dimension.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - DimensionQuickNavHorizontal

/// 维度快速导航水平滚动视图 - 水平滚动的维度卡片
///
/// 适用于需要水平滚动展示的场景
public struct DimensionQuickNavHorizontal: View {
    
    let dimensions: [PopulatedDimension]
    let onSelect: (String) -> Void
    
    /// 卡片宽度
    var cardWidth: CGFloat = 140
    
    /// 卡片间距
    var spacing: CGFloat = 12
    
    public init(
        dimensions: [PopulatedDimension],
        onSelect: @escaping (String) -> Void
    ) {
        self.dimensions = dimensions
        self.onSelect = onSelect
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(dimensions) { dimension in
                    DimensionQuickNavHorizontalCard(
                        dimension: dimension,
                        width: cardWidth,
                        onTap: { onSelect(dimension.id) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - DimensionQuickNavHorizontalCard

/// 水平滚动卡片
private struct DimensionQuickNavHorizontalCard: View {
    
    let dimension: PopulatedDimension
    let width: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 图标
                Image(systemName: dimension.icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(dimension.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(dimension.color.opacity(0.15))
                    )
                
                // 维度名称
                Text(dimension.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 节点数量
                HStack(spacing: 4) {
                    Text("\(dimension.totalNodeCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(dimension.color)
                    
                    Text("节点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: width, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(dimension.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dimension.displayName)，\(dimension.totalNodeCount)个节点")
        .accessibilityHint("双击跳转到该维度")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct DimensionQuickNav_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Standard Grid (2 columns)
                Group {
                    Text("Standard Grid (2 columns)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionQuickNav(
                        dimensions: sampleDimensions,
                        onSelect: { id in
                            print("Selected: \(id)")
                        }
                    )
                }
                
                Divider()
                
                // 3 Columns Grid
                Group {
                    Text("3 Columns Grid")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionQuickNav(
                        dimensions: sampleDimensions,
                        onSelect: { _ in }
                    )
                    .columns(3)
                }
                
                Divider()
                
                // Without Title
                Group {
                    Text("Without Title")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionQuickNav(
                        dimensions: sampleDimensions,
                        onSelect: { _ in }
                    )
                    .showTitle(false)
                }
                
                Divider()
                
                // Horizontal Scroll
                Group {
                    Text("Horizontal Scroll")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    DimensionQuickNavHorizontal(
                        dimensions: sampleDimensions,
                        onSelect: { _ in }
                    )
                }
                
                Divider()
                
                // Empty State
                Group {
                    Text("Empty State")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    DimensionQuickNav(
                        dimensions: [],
                        onSelect: { _ in }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
        .previewDisplayName("DimensionQuickNav Variants")
    }
    
    // Sample Data
    static var sampleDimensions: [PopulatedDimension] {
        DimensionHierarchy.coreDimensions.enumerated().map { index, level1 in
            PopulatedDimension(
                level1: level1,
                level2Groups: [
                    Level2Group(
                        level2: "sample",
                        displayName: "示例分组",
                        nodes: (1...(5 + index * 3)).map { i in
                            KnowledgeNode(
                                nodeType: "\(level1.rawValue).sample.item",
                                contentType: .aiTag,
                                name: "节点 \(i)"
                            )
                        }
                    )
                ],
                color: DimensionColors.color(for: level1),
                icon: DimensionIcons.icon(for: level1)
            )
        }
    }
}
#endif
