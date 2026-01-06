import SwiftUI

// MARK: - DimensionHeader

/// 维度标题组件 - 显示 L1 维度的图标、名称和节点数量
///
/// 设计特点：
/// - 使用维度主题色
/// - 显示 SF Symbol 图标
/// - 显示节点数量统计
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// DimensionHeader(
///     level1: .achievements,
///     nodeCount: 15,
///     color: DimensionColors.color(for: .achievements),
///     icon: DimensionIcons.icon(for: .achievements)
/// )
/// ```
///
/// - SeeAlso: `DimensionColors` 维度颜色配置
/// - SeeAlso: `DimensionIcons` 维度图标配置
/// - Requirements: REQ-4.1, REQ-8.1
public struct DimensionHeader: View {
    
    // MARK: - Properties
    
    /// Level 1 维度
    let level1: DimensionHierarchy.Level1
    
    /// 该维度下的节点数量
    let nodeCount: Int
    
    /// 维度主题色（可选，默认从 DimensionColors 获取）
    let color: Color?
    
    /// 维度图标（可选，默认从 DimensionIcons 获取）
    let icon: String?
    
    // MARK: - Computed Properties
    
    /// 实际使用的颜色
    private var themeColor: Color {
        color ?? DimensionColors.color(for: level1)
    }
    
    /// 实际使用的图标
    private var themeIcon: String {
        icon ?? DimensionIcons.icon(for: level1)
    }
    
    // MARK: - Initialization
    
    /// 创建维度标题
    /// - Parameters:
    ///   - level1: Level 1 维度
    ///   - nodeCount: 节点数量
    ///   - color: 主题色（可选）
    ///   - icon: 图标名称（可选）
    public init(
        level1: DimensionHierarchy.Level1,
        nodeCount: Int,
        color: Color? = nil,
        icon: String? = nil
    ) {
        self.level1 = level1
        self.nodeCount = nodeCount
        self.color = color
        self.icon = icon
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 12) {
            // 图标
            iconView
            
            // 标题和描述
            titleSection
            
            Spacer()
            
            // 节点数量
            nodeCountBadge
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(backgroundView)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }
    
    // MARK: - Subviews
    
    /// 图标视图
    private var iconView: some View {
        Image(systemName: themeIcon)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(themeColor)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(themeColor.opacity(0.15))
            )
    }
    
    /// 标题区域
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 中文名称
            Text(level1.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // 英文名称和描述
            Text(level1.englishName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 节点数量徽章
    private var nodeCountBadge: some View {
        Text("\(nodeCount)")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(themeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(themeColor.opacity(0.1))
            )
    }
    
    /// 背景视图
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 无障碍标签文本
    private var accessibilityLabelText: String {
        "\(level1.displayName)维度，共\(nodeCount)个知识节点"
    }
}

// MARK: - Convenience Initializer

extension DimensionHeader {
    
    /// 从 PopulatedDimension 创建
    /// - Parameter dimension: 有数据的维度
    public init(dimension: PopulatedDimension) {
        self.level1 = dimension.level1
        self.nodeCount = dimension.totalNodeCount
        self.color = dimension.color
        self.icon = dimension.icon
    }
}

// MARK: - Preview

#if DEBUG
struct DimensionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 各维度示例
            ForEach(DimensionHierarchy.coreDimensions, id: \.rawValue) { level1 in
                DimensionHeader(
                    level1: level1,
                    nodeCount: Int.random(in: 5...30)
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
        .previewDisplayName("All Dimensions")
    }
}
#endif
