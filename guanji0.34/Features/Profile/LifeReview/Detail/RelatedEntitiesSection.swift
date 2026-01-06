import SwiftUI

// MARK: - RelatedEntitiesSection

/// 关联人物区块 - 显示与知识节点相关的人物列表
///
/// 设计特点：
/// - 显示关联人物头像和名称
/// - 支持点击查看人物详情
/// - 使用水平滚动布局
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// RelatedEntitiesSection(
///     entityIds: node.relatedEntityIds,
///     color: .blue,
///     onEntityTap: { entityId in
///         // 跳转到人物详情
///     }
/// )
/// ```
///
/// - SeeAlso: `NarrativeRelationship` 关系模型
/// - Requirements: REQ-7.4
public struct RelatedEntitiesSection: View {
    
    // MARK: - Properties
    
    /// 关联实体 ID 列表
    let entityIds: [String]
    
    /// 主题色
    let color: Color
    
    /// 实体点击回调
    var onEntityTap: ((String) -> Void)?
    
    /// 实体名称提供者（用于显示名称，如果没有则显示 ID）
    var entityNameProvider: ((String) -> String)?
    
    // MARK: - Initialization
    
    /// 创建关联人物区块
    /// - Parameters:
    ///   - entityIds: 关联实体 ID 列表
    ///   - color: 主题色
    ///   - onEntityTap: 实体点击回调
    ///   - entityNameProvider: 实体名称提供者
    public init(
        entityIds: [String],
        color: Color = .pink,
        onEntityTap: ((String) -> Void)? = nil,
        entityNameProvider: ((String) -> String)? = nil
    ) {
        self.entityIds = entityIds
        self.color = color
        self.onEntityTap = onEntityTap
        self.entityNameProvider = entityNameProvider
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 区块标题
            sectionHeader
            
            // 人物列表
            if entityIds.isEmpty {
                emptyStateView
            } else {
                entitiesListView
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 区块标题
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundStyle(color)
            
            Text("关联人物")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(entityIds.count) 人")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("暂无关联人物")
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
    
    /// 人物列表视图
    private var entitiesListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(entityIds, id: \.self) { entityId in
                    EntityCard(
                        entityId: entityId,
                        name: entityNameProvider?(entityId),
                        color: color,
                        onTap: {
                            onEntityTap?(entityId)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - EntityCard

/// 实体卡片组件
private struct EntityCard: View {
    
    // MARK: - Properties
    
    /// 实体 ID
    let entityId: String
    
    /// 显示名称
    let name: String?
    
    /// 主题色
    let color: Color
    
    /// 点击回调
    var onTap: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// 显示名称（如果没有提供则从 ID 提取）
    private var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        // 尝试从 ID 提取名称（格式可能是 REL_xxx_name）
        let components = entityId.split(separator: "_")
        if components.count >= 2 {
            return String(components.last ?? Substring(entityId))
        }
        return entityId
    }
    
    /// 头像首字母
    private var avatarInitial: String {
        String(displayName.prefix(1))
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel("关联人物：\(displayName)")
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Content
    
    private var content: some View {
        VStack(spacing: 8) {
            // 头像
            avatarView
            
            // 名称
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: 70)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// 头像视图
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.6), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(avatarInitial)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - RelatedEntitiesGrid

/// 关联人物网格视图（替代水平滚动的布局）
///
/// 适用于需要在有限空间内显示所有关联人物的场景
public struct RelatedEntitiesGrid: View {
    
    // MARK: - Properties
    
    let entityIds: [String]
    let color: Color
    var onEntityTap: ((String) -> Void)?
    var entityNameProvider: ((String) -> String)?
    
    /// 每行显示数量
    var columnsCount: Int = 4
    
    // MARK: - Initialization
    
    public init(
        entityIds: [String],
        color: Color = .pink,
        columnsCount: Int = 4,
        onEntityTap: ((String) -> Void)? = nil,
        entityNameProvider: ((String) -> String)? = nil
    ) {
        self.entityIds = entityIds
        self.color = color
        self.columnsCount = columnsCount
        self.onEntityTap = onEntityTap
        self.entityNameProvider = entityNameProvider
    }
    
    // MARK: - Body
    
    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnsCount),
            spacing: 12
        ) {
            ForEach(entityIds, id: \.self) { entityId in
                EntityGridItem(
                    entityId: entityId,
                    name: entityNameProvider?(entityId),
                    color: color,
                    onTap: {
                        onEntityTap?(entityId)
                    }
                )
            }
        }
    }
}

// MARK: - EntityGridItem

/// 实体网格项组件
private struct EntityGridItem: View {
    
    let entityId: String
    let name: String?
    let color: Color
    var onTap: (() -> Void)?
    
    private var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        let components = entityId.split(separator: "_")
        if components.count >= 2 {
            return String(components.last ?? Substring(entityId))
        }
        return entityId
    }
    
    private var avatarInitial: String {
        String(displayName.prefix(1))
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 6) {
                // 头像
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                    
                    Text(avatarInitial)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }
                .frame(width: 40, height: 40)
                
                // 名称
                Text(displayName)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("关联人物：\(displayName)")
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - RelatedEntitiesCompact

/// 关联人物紧凑视图
///
/// 适用于空间有限的场景，只显示头像堆叠
public struct RelatedEntitiesCompact: View {
    
    let entityIds: [String]
    let color: Color
    var maxDisplay: Int = 3
    var onTap: (() -> Void)?
    
    public init(
        entityIds: [String],
        color: Color = .pink,
        maxDisplay: Int = 3,
        onTap: (() -> Void)? = nil
    ) {
        self.entityIds = entityIds
        self.color = color
        self.maxDisplay = maxDisplay
        self.onTap = onTap
    }
    
    private var displayedIds: [String] {
        Array(entityIds.prefix(maxDisplay))
    }
    
    private var remainingCount: Int {
        max(0, entityIds.count - maxDisplay)
    }
    
    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: -8) {
                ForEach(Array(displayedIds.enumerated()), id: \.element) { index, entityId in
                    avatarCircle(for: entityId)
                        .zIndex(Double(maxDisplay - index))
                }
                
                if remainingCount > 0 {
                    moreIndicator
                        .zIndex(0)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entityIds.count) 个关联人物")
        .accessibilityHint("双击查看全部关联人物")
        .accessibilityAddTraits(.isButton)
    }
    
    private func avatarCircle(for entityId: String) -> some View {
        let initial = String(entityId.split(separator: "_").last?.prefix(1) ?? "?")
        
        return ZStack {
            Circle()
                .fill(color)
            
            Text(initial)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(width: 28, height: 28)
        .overlay(
            Circle()
                .strokeBorder(.white, lineWidth: 2)
        )
    }
    
    private var moreIndicator: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
            
            Text("+\(remainingCount)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(width: 28, height: 28)
        .overlay(
            Circle()
                .strokeBorder(.white, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct RelatedEntitiesSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 有关联人物
                RelatedEntitiesSection(
                    entityIds: sampleEntityIds,
                    color: .pink,
                    onEntityTap: { id in
                        print("Tapped: \(id)")
                    },
                    entityNameProvider: { id in
                        sampleEntityNames[id] ?? id
                    }
                )
                
                Divider()
                
                // 空状态
                RelatedEntitiesSection(
                    entityIds: [],
                    color: .blue
                )
                
                Divider()
                
                // 网格布局
                VStack(alignment: .leading, spacing: 12) {
                    Text("网格布局")
                        .font(.headline)
                    
                    RelatedEntitiesGrid(
                        entityIds: sampleEntityIds,
                        color: .purple,
                        entityNameProvider: { id in
                            sampleEntityNames[id] ?? id
                        }
                    )
                }
                
                Divider()
                
                // 紧凑布局
                VStack(alignment: .leading, spacing: 12) {
                    Text("紧凑布局")
                        .font(.headline)
                    
                    HStack {
                        RelatedEntitiesCompact(
                            entityIds: sampleEntityIds,
                            color: .orange
                        )
                        
                        Spacer()
                        
                        Text("点击查看全部")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleEntityIds: [String] {
        ["REL_001_张三", "REL_002_李四", "REL_003_王五", "REL_004_赵六", "REL_005_钱七"]
    }
    
    static var sampleEntityNames: [String: String] {
        [
            "REL_001_张三": "张三",
            "REL_002_李四": "李四",
            "REL_003_王五": "王五",
            "REL_004_赵六": "赵六",
            "REL_005_钱七": "钱七"
        ]
    }
}
#endif
