import SwiftUI

// MARK: - NodeSourceSection

/// 节点来源信息区块 - 重构版
///
/// 设计特点：
/// - 显示关联原始次数（基于 sourceLinks 数量）
/// - 显示来源类型分布（按数据表类型分组统计）
/// - 显示时间信息（创建时间、更新时间）
/// - 支持 VoiceOver 无障碍访问
///
/// 重构变更（L4 Source Info Redesign）：
/// - 移除：置信度进度条 UI
/// - 移除：验证状态显示
/// - 移除：确认时间显示
/// - 新增：关联原始次数
/// - 重构：来源类型改为数据表分布
///
/// 使用示例：
/// ```swift
/// NodeSourceSection(node: node, color: .blue)
/// ```
///
/// - SeeAlso: `NodeTracking` 节点追踪信息
/// - SeeAlso: `DataSourceTypeIcons` 数据表来源类型图标
/// - Requirements: REQ-1.1, REQ-1.2, REQ-2.1, REQ-3.1
public struct NodeSourceSection: View {
    
    // MARK: - Properties
    
    /// 知识节点
    let node: KnowledgeNode
    
    /// 主题色
    let color: Color
    
    // MARK: - Computed Properties
    
    /// 关联原始次数
    private var mentionCount: Int {
        node.mentionCount
    }
    
    /// 来源类型分布
    private var sourceTypeDistribution: [String: Int] {
        node.sourceTypeDistribution
    }
    
    /// 是否有来源数据
    private var hasSourceData: Bool {
        node.hasSourceData
    }
    
    // MARK: - Initialization
    
    /// 创建节点来源信息区块
    /// - Parameters:
    ///   - node: 知识节点
    ///   - color: 主题色
    public init(node: KnowledgeNode, color: Color) {
        self.node = node
        self.color = color
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 区块标题
            sectionHeader
            
            // 关联原始次数
            mentionCountView
            
            // 来源类型分布
            sourceTypeView
            
            // 时间信息
            timelineView
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 区块标题
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(color)
            
            Text("来源信息")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    /// 关联原始次数视图
    private var mentionCountView: some View {
        HStack {
            Image(systemName: "link")
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("关联原始次数")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if hasSourceData {
                    Text("关联 \(mentionCount) 条原始数据")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("暂无来源数据")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 数量徽章
            if hasSourceData {
                Text("\(mentionCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasSourceData ? "关联 \(mentionCount) 条原始数据" : "暂无来源数据")
    }

    
    /// 来源类型分布视图
    private var sourceTypeView: some View {
        Group {
            if hasSourceData {
                if sourceTypeDistribution.count == 1,
                   let (sourceType, count) = sourceTypeDistribution.first {
                    // 单条来源时显示单行格式
                    singleSourceTypeRow(sourceType: sourceType, count: count)
                } else {
                    // 多条来源时显示分组格式
                    multipleSourceTypeView
                }
            } else {
                // 无来源数据时不显示此区块
                EmptyView()
            }
        }
    }
    
    /// 单条来源类型行
    private func singleSourceTypeRow(sourceType: String, count: Int) -> some View {
        HStack {
            Image(systemName: DataSourceTypeIcons.icon(for: sourceType))
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text("来源：\(DataSourceTypeIcons.displayName(for: sourceType)) \(count) 条")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("来源：\(DataSourceTypeIcons.displayName(for: sourceType)) \(count) 条")
    }
    
    /// 多条来源类型视图
    private var multipleSourceTypeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text("来源分布")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 分组列表
            ForEach(sortedSourceTypes, id: \.key) { sourceType, count in
                sourceTypeRow(sourceType: sourceType, count: count)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    /// 排序后的来源类型列表
    private var sortedSourceTypes: [(key: String, value: Int)] {
        sourceTypeDistribution.sorted { $0.value > $1.value }
    }
    
    /// 来源类型行
    private func sourceTypeRow(sourceType: String, count: Int) -> some View {
        HStack {
            Image(systemName: DataSourceTypeIcons.icon(for: sourceType))
                .font(.body)
                .foregroundStyle(sourceTypeColor(for: sourceType))
                .frame(width: 24)
            
            Text(DataSourceTypeIcons.displayName(for: sourceType))
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count) 条")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(DataSourceTypeIcons.displayName(for: sourceType)) \(count) 条")
    }
    
    /// 来源类型颜色
    private func sourceTypeColor(for sourceType: String) -> Color {
        switch sourceType {
        case "diary":
            return .blue
        case "conversation":
            return .purple
        case "tracker":
            return .green
        case "mindState":
            return .pink
        default:
            return .gray
        }
    }
    
    /// 时间信息视图
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 创建时间
            timelineRow(
                icon: "plus.circle.fill",
                label: "创建时间",
                date: node.createdAt
            )
            
            // 更新时间
            timelineRow(
                icon: "arrow.clockwise.circle.fill",
                label: "更新时间",
                date: node.updatedAt
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    /// 时间行视图
    private func timelineRow(
        icon: String,
        label: String,
        date: Date,
        color: Color = .secondary
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(formatDate(date))
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(formatDate(date))")
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct NodeSourceSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 有多条来源的节点
                NodeSourceSection(
                    node: sampleNodeWithMultipleSources,
                    color: .blue
                )
                
                Divider()
                
                // 只有一条来源的节点
                NodeSourceSection(
                    node: sampleNodeWithSingleSource,
                    color: .orange
                )
                
                Divider()
                
                // 没有来源的节点
                NodeSourceSection(
                    node: sampleNodeWithNoSource,
                    color: .purple
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleNodeWithMultipleSources: KnowledgeNode {
        KnowledgeNode(
            nodeType: "spirit.ideology.values",
            contentType: .aiTag,
            name: "家庭优先",
            sourceLinks: [
                SourceLink(sourceType: "diary", sourceId: "d1", dayId: "2024-12-15"),
                SourceLink(sourceType: "diary", sourceId: "d2", dayId: "2024-12-20"),
                SourceLink(sourceType: "diary", sourceId: "d3", dayId: "2024-12-25"),
                SourceLink(sourceType: "conversation", sourceId: "c1", dayId: "2024-12-18"),
                SourceLink(sourceType: "conversation", sourceId: "c2", dayId: "2024-12-22"),
                SourceLink(sourceType: "tracker", sourceId: "t1", dayId: "2024-12-30")
            ],
            tracking: NodeTracking(
                source: NodeSource(type: .aiExtracted, confidence: 0.85),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 30),
                    lastUpdated: Date().addingTimeInterval(-86400 * 7)
                ),
                verification: NodeVerification(confirmedByUser: false, needsReview: false)
            )
        )
    }
    
    static var sampleNodeWithSingleSource: KnowledgeNode {
        KnowledgeNode(
            nodeType: "achievements.competencies.professional_skills",
            contentType: .aiTag,
            name: "Swift 编程",
            sourceLinks: [
                SourceLink(sourceType: "diary", sourceId: "d1", dayId: "2024-12-15")
            ],
            tracking: NodeTracking(
                source: NodeSource(type: .aiExtracted, confidence: 0.85),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 14),
                    lastUpdated: Date().addingTimeInterval(-86400 * 2)
                ),
                verification: NodeVerification(confirmedByUser: false, needsReview: false)
            )
        )
    }
    
    static var sampleNodeWithNoSource: KnowledgeNode {
        KnowledgeNode(
            nodeType: "self.personality.self_assessment",
            contentType: .aiTag,
            name: "完美主义",
            sourceLinks: [],
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                timeline: NodeTimeline(
                    firstDiscovered: Date().addingTimeInterval(-86400 * 3),
                    lastUpdated: Date()
                ),
                verification: NodeVerification(confirmedByUser: true, needsReview: false)
            )
        )
    }
}
#endif
