import SwiftUI

// MARK: - UserHeaderSection

/// 用户头部信息组件 - 显示用户头像和基本信息
///
/// 设计特点：
/// - 显示用户头像（占位或实际图片）
/// - 显示用户名称和基本信息
/// - 显示节点总数统计
/// - 使用温暖、个人化的视觉风格
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// UserHeaderSection(
///     profile: userProfile,
///     totalNodeCount: 42
/// )
/// ```
///
/// - SeeAlso: `NarrativeUserProfile` 用户画像模型
/// - Requirements: REQ-2.4
public struct UserHeaderSection: View {
    
    // MARK: - Properties
    
    /// 用户画像数据
    let profile: NarrativeUserProfile?
    
    /// 节点总数（可选，如果不提供则从 profile 计算）
    var totalNodeCount: Int?
    
    /// 是否显示统计信息
    var showStatistics: Bool = true
    
    /// 头像大小
    var avatarSize: CGFloat = 80
    
    // MARK: - Computed Properties
    
    /// 用户显示名称
    private var displayName: String {
        if let name = profile?.staticCore.nickname, !name.isEmpty {
            return name
        }
        return "我的人生"
    }
    
    /// 用户职业
    private var occupation: String? {
        profile?.staticCore.occupation
    }
    
    /// 用户所在城市
    private var city: String? {
        profile?.staticCore.currentCity
    }
    
    /// 实际节点总数
    private var nodeCount: Int {
        totalNodeCount ?? profile?.knowledgeNodes.count ?? 0
    }
    
    /// 副标题文本
    private var subtitleText: String? {
        var parts: [String] = []
        if let occ = occupation {
            parts.append(occ)
        }
        if let c = city {
            parts.append(c)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
    
    // MARK: - Initialization
    
    /// 创建用户头部信息组件
    /// - Parameters:
    ///   - profile: 用户画像数据
    ///   - totalNodeCount: 节点总数（可选）
    public init(
        profile: NarrativeUserProfile?,
        totalNodeCount: Int? = nil
    ) {
        self.profile = profile
        self.totalNodeCount = totalNodeCount
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 16) {
            // 头像和基本信息
            HStack(spacing: 16) {
                avatarView
                
                VStack(alignment: .leading, spacing: 4) {
                    // 名称
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    // 副标题
                    if let subtitle = subtitleText {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 统计信息
                    if showStatistics {
                        statisticsView
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(backgroundView)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }
    
    // MARK: - Subviews
    
    /// 头像视图
    private var avatarView: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.6),
                    Color.purple.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 头像图标
            Image(systemName: "person.fill")
                .font(.system(size: avatarSize * 0.4))
                .foregroundStyle(.white)
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    /// 统计信息视图
    private var statisticsView: some View {
        HStack(spacing: 12) {
            // 节点总数
            StatisticBadge(
                icon: "brain.head.profile",
                value: "\(nodeCount)",
                label: "知识节点"
            )
            
            // 维度数量（如果有数据）
            if let profile = profile {
                let dimensionCount = countPopulatedDimensions(profile)
                if dimensionCount > 0 {
                    StatisticBadge(
                        icon: "square.grid.2x2",
                        value: "\(dimensionCount)",
                        label: "维度"
                    )
                }
            }
        }
        .padding(.top, 4)
    }
    
    /// 背景视图
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    /// 无障碍标签文本
    private var accessibilityLabelText: String {
        var label = displayName
        if let subtitle = subtitleText {
            label += "，\(subtitle)"
        }
        label += "，共\(nodeCount)个知识节点"
        return label
    }
    
    // MARK: - Helper Methods
    
    /// 计算有数据的维度数量
    private func countPopulatedDimensions(_ profile: NarrativeUserProfile) -> Int {
        var level1Set = Set<String>()
        for node in profile.knowledgeNodes {
            if let path = node.typePath, let level1 = path.level1Dimension {
                level1Set.insert(level1.rawValue)
            }
        }
        return level1Set.count
    }
}

// MARK: - UserHeaderSection Modifiers

extension UserHeaderSection {
    
    /// 设置是否显示统计信息
    /// - Parameter show: 是否显示
    /// - Returns: 修改后的视图
    public func showStatistics(_ show: Bool) -> UserHeaderSection {
        var view = self
        view.showStatistics = show
        return view
    }
    
    /// 设置头像大小
    /// - Parameter size: 头像尺寸
    /// - Returns: 修改后的视图
    public func avatarSize(_ size: CGFloat) -> UserHeaderSection {
        var view = self
        view.avatarSize = size
        return view
    }
}

// MARK: - StatisticBadge

/// 统计徽章组件 - 显示单个统计项
private struct StatisticBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - UserHeaderCompactSection

/// 用户头部紧凑视图 - 更小的头像和简化的信息
///
/// 适用于空间有限的场景
public struct UserHeaderCompactSection: View {
    
    let profile: NarrativeUserProfile?
    let totalNodeCount: Int?
    
    public init(
        profile: NarrativeUserProfile?,
        totalNodeCount: Int? = nil
    ) {
        self.profile = profile
        self.totalNodeCount = totalNodeCount
    }
    
    public var body: some View {
        UserHeaderSection(
            profile: profile,
            totalNodeCount: totalNodeCount
        )
        .avatarSize(56)
        .showStatistics(false)
    }
}

// MARK: - Preview

#if DEBUG
struct UserHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Full Header
            Group {
                Text("Full Header")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                UserHeaderSection(
                    profile: sampleProfile,
                    totalNodeCount: 42
                )
            }
            
            Divider()
            
            // Compact Header
            Group {
                Text("Compact Header")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                UserHeaderCompactSection(
                    profile: sampleProfile,
                    totalNodeCount: 42
                )
            }
            
            Divider()
            
            // Empty Profile
            Group {
                Text("Empty Profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                UserHeaderSection(
                    profile: nil,
                    totalNodeCount: 0
                )
            }
            
            Divider()
            
            // Profile without statistics
            Group {
                Text("Without Statistics")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                UserHeaderSection(
                    profile: sampleProfile,
                    totalNodeCount: 42
                )
                .showStatistics(false)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
        .previewDisplayName("UserHeaderSection Variants")
    }
    
    // Sample Data
    static var sampleProfile: NarrativeUserProfile {
        var profile = NarrativeUserProfile()
        profile.staticCore.nickname = "张三"
        profile.staticCore.occupation = "软件工程师"
        profile.staticCore.currentCity = "北京"
        profile.knowledgeNodes = (1...42).map { i in
            KnowledgeNode(
                nodeType: "achievements.competencies.professional_skills",
                contentType: .aiTag,
                name: "技能 \(i)"
            )
        }
        return profile
    }
}
#endif
