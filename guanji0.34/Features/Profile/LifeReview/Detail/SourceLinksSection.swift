import SwiftUI

// MARK: - SourceLinksSection

/// 溯源链接区块 - 显示知识节点的原始数据来源
///
/// 设计特点：
/// - 显示溯源链接列表
/// - 显示 snippet 文本片段
/// - 支持点击跳转到原始数据
/// - 显示来源类型图标和日期
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// SourceLinksSection(
///     sourceLinks: node.sourceLinks,
///     color: .blue,
///     onLinkTap: { link in
///         // 跳转到原始数据
///     }
/// )
/// ```
///
/// - SeeAlso: `SourceLink` 溯源链接模型
/// - Requirements: REQ-7.3, REQ-2.5
public struct SourceLinksSection: View {
    
    // MARK: - Properties
    
    /// 溯源链接列表
    let sourceLinks: [SourceLink]
    
    /// 主题色
    let color: Color
    
    /// 链接点击回调
    var onLinkTap: ((SourceLink) -> Void)?
    
    /// 最大显示数量（超出时折叠）
    var maxDisplayCount: Int = 5
    
    // MARK: - State
    
    /// 是否展开全部
    @State private var isExpanded: Bool = false
    
    // MARK: - Computed Properties
    
    /// 显示的链接列表
    private var displayedLinks: [SourceLink] {
        if isExpanded || sourceLinks.count <= maxDisplayCount {
            return sourceLinks
        }
        return Array(sourceLinks.prefix(maxDisplayCount))
    }
    
    /// 是否有更多链接
    private var hasMore: Bool {
        sourceLinks.count > maxDisplayCount
    }
    
    /// 剩余链接数量
    private var remainingCount: Int {
        sourceLinks.count - maxDisplayCount
    }
    
    // MARK: - Initialization
    
    /// 创建溯源链接区块
    /// - Parameters:
    ///   - sourceLinks: 溯源链接列表
    ///   - color: 主题色
    ///   - onLinkTap: 链接点击回调
    public init(
        sourceLinks: [SourceLink],
        color: Color = .blue,
        onLinkTap: ((SourceLink) -> Void)? = nil
    ) {
        self.sourceLinks = sourceLinks
        self.color = color
        self.onLinkTap = onLinkTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 区块标题
            sectionHeader
            
            // 链接列表
            if sourceLinks.isEmpty {
                emptyStateView
            } else {
                linksListView
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 区块标题
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "link.circle.fill")
                .foregroundStyle(color)
            
            Text("溯源链接")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(sourceLinks.count) 条")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "link.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("暂无溯源链接")
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
    
    /// 链接列表视图
    private var linksListView: some View {
        VStack(spacing: 12) {
            ForEach(displayedLinks) { link in
                SourceLinkRow(
                    link: link,
                    onTap: {
                        onLinkTap?(link)
                    }
                )
            }
            
            // 展开/收起按钮
            if hasMore {
                expandButton
            }
        }
    }
    
    /// 展开/收起按钮
    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Spacer()
                
                if isExpanded {
                    Label("收起", systemImage: "chevron.up")
                } else {
                    Label("查看更多 (\(remainingCount))", systemImage: "chevron.down")
                }
                
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(color)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "收起链接列表" : "展开查看更多\(remainingCount)条链接")
        .accessibilityHint(isExpanded ? "双击收起溯源链接列表" : "双击展开查看更多溯源链接")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct SourceLinksSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 有链接的情况
                SourceLinksSection(
                    sourceLinks: sampleSourceLinks,
                    color: .blue,
                    onLinkTap: { link in
                        print("Tapped: \(link.id)")
                    }
                )
                
                Divider()
                
                // 空链接的情况
                SourceLinksSection(
                    sourceLinks: [],
                    color: .orange
                )
                
                Divider()
                
                // 单个链接行
                SourceLinkRow(
                    link: sampleSourceLinks[0]
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleSourceLinks: [SourceLink] {
        [
            SourceLink(
                sourceType: "diary",
                sourceId: "diary_001",
                dayId: "2024-12-15",
                snippet: "今天开始学习 Swift 编程，感觉这门语言设计得很优雅，特别是 SwiftUI 的声明式语法让我眼前一亮。",
                relevanceScore: 0.95,
                relatedEntityIds: []
            ),
            SourceLink(
                sourceType: "conversation",
                sourceId: "conv_002",
                dayId: "2024-12-20",
                snippet: "和小明讨论了 iOS 开发的技术栈选择，他推荐我深入学习 Combine 框架。",
                relevanceScore: 0.85,
                relatedEntityIds: ["REL_001"]
            ),
            SourceLink(
                sourceType: "tracker",
                sourceId: "tracker_003",
                dayId: "2024-12-25",
                snippet: "完成了 SwiftUI 基础教程的学习，开始尝试构建第一个 App。",
                relevanceScore: 0.75
            ),
            SourceLink(
                sourceType: "mindState",
                sourceId: "mind_004",
                dayId: "2024-12-28",
                snippet: "对编程学习充满热情，感觉找到了新的方向。",
                relevanceScore: 0.65,
                relatedEntityIds: []
            ),
            SourceLink(
                sourceType: "diary",
                sourceId: "diary_005",
                dayId: "2024-12-30",
                snippet: "成功发布了第一个 iOS App 到 TestFlight，虽然功能简单但很有成就感。",
                relevanceScore: 0.90
            ),
            SourceLink(
                sourceType: "conversation",
                sourceId: "conv_006",
                dayId: "2025-01-02",
                snippet: "收到了用户的第一条反馈，他们觉得 App 的界面设计很清爽。",
                relevanceScore: 0.70,
                relatedEntityIds: ["REL_002", "REL_003"]
            )
        ]
    }
}
#endif
