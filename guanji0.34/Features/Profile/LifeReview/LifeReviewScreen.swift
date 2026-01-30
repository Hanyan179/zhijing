import SwiftUI

// MARK: - LifeReviewScreen

/// 人生回顾主页面 - 沉浸式展示所有维度数据
///
/// 设计特点：
/// - 使用 NavigationStack 包装，支持 iOS 16+ 导航
/// - 使用 ScrollViewReader 支持锚点跳转
/// - 使用 LazyVStack 实现懒加载，优化大数据量性能
/// - 组合 UserHeaderSection、DimensionQuickNav、DimensionSectionView
/// - 使用 `.sheet(item:)` 展示节点详情
/// - 支持搜索功能和下拉刷新
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// NavigationStack {
///     LifeReviewScreen()
/// }
/// ```
///
/// - SeeAlso: `LifeReviewViewModel` 数据管理
/// - SeeAlso: `UserHeaderSection` 用户头部信息
/// - SeeAlso: `DimensionQuickNav` 维度快速导航
/// - SeeAlso: `DimensionSectionView` 维度区块视图
/// - SeeAlso: `KnowledgeNodeDetailSheet` 节点详情 Sheet
/// - Requirements: REQ-1, REQ-2, REQ-8.5, REQ-8.8
public struct LifeReviewScreen: View {
    
    // MARK: - State
    
    /// ViewModel
    @StateObject private var viewModel = LifeReviewViewModel()
    
    /// 选中的节点（用于显示详情 Sheet）
    @State private var selectedNode: KnowledgeNode?
    
    /// 要编辑的节点
    @State private var nodeToEdit: KnowledgeNode?
    
    /// 滚动目标（用于锚点跳转）
    @State private var scrollTarget: String?
    
    /// 是否显示导入确认弹窗
    @State private var showImportConfirmation: Bool = false
    
    /// 是否显示清除确认弹窗
    @State private var showClearConfirmation: Bool = false
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("人生回顾")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "搜索知识节点"
                )
                .refreshable {
                    await refreshData()
                }
                .toolbar {
                    toolbarContent
                }
                .sheet(item: $selectedNode) { node in
                    KnowledgeNodeDetailSheet(
                        node: node,
                        viewModel: viewModel,
                        onDismiss: { selectedNode = nil },
                        onEdit: { nodeToEdit = $0 },
                        onChildNodeTap: { childNode in
                            selectedNode = childNode
                        }
                    )
                }
                .sheet(item: $nodeToEdit) { node in
                    KnowledgeNodeEditSheet(
                        originalNode: node,
                        viewModel: viewModel,
                        onSave: { updatedNode in
                            // 更新选中的节点以刷新详情页
                            selectedNode = updatedNode
                            nodeToEdit = nil
                        },
                        onCancel: {
                            nodeToEdit = nil
                        }
                    )
                }
                #if DEBUG
                .alert("导入测试数据", isPresented: $showImportConfirmation) {
                    Button("取消", role: .cancel) { }
                    Button("导入", role: .destructive) {
                        viewModel.importTestData()
                    }
                } message: {
                    Text("这将覆盖现有的用户画像数据。确定要导入测试数据吗？")
                }
                .alert("清除所有数据", isPresented: $showClearConfirmation) {
                    Button("取消", role: .cancel) { }
                    Button("清除", role: .destructive) {
                        viewModel.clearAllNodes()
                    }
                } message: {
                    Text("这将删除所有知识节点数据。此操作不可撤销。")
                }
                #endif
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.isSearching {
            searchResultsView
        } else if viewModel.showEmptyState {
            EmptyStateView(onStartConversation: nil)
        } else {
            scrollableContent
        }
    }
    
    // MARK: - Scrollable Content
    
    private var scrollableContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 24) {
                    // 用户头部信息
                    UserHeaderSection(
                        profile: viewModel.userProfile,
                        totalNodeCount: viewModel.totalNodeCount
                    )
                    .id("header")
                    
                    // 维度快速导航
                    if !viewModel.populatedDimensions.isEmpty {
                        DimensionQuickNav(
                            dimensions: viewModel.populatedDimensions,
                            onSelect: { dimensionId in
                                scrollTarget = dimensionId
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // 各维度内容区块
                    ForEach(viewModel.populatedDimensions) { dimension in
                        DimensionSectionView(
                            dimension: dimension,
                            onNodeTap: { node in
                                selectedNode = node
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(dimension.id)
                        .padding(.horizontal, 16)
                    }
                    
                    // 底部间距
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.top, 8)
            }
            .onChange(of: scrollTarget) { target in
                if let target = target {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    // 重置滚动目标
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        scrollTarget = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        SearchResultsView(
            results: viewModel.searchResults,
            query: viewModel.searchText,
            viewModel: viewModel,
            onNodeTap: { node in
                selectedNode = node
            },
            onClearSearch: {
                viewModel.clearSearch()
            }
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            RobotAvatar(mood: .processing, size: 100)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if DEBUG
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("导入测试数据", systemImage: "square.and.arrow.down") {
                    showImportConfirmation = true
                }
                
                Button("清除所有数据", systemImage: "trash", role: .destructive) {
                    showClearConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("更多操作")
            .accessibilityHint("双击打开操作菜单，包含导入测试数据和清除数据选项")
        }
        #endif
    }
    
    // MARK: - Helper Methods
    
    /// 刷新数据（异步）
    private func refreshData() async {
        // 模拟异步操作
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.refresh()
    }
}

// MARK: - SearchResultsView

/// 搜索结果视图 - 显示搜索结果列表
///
/// 设计特点：
/// - 按维度分组显示搜索结果
/// - 高亮匹配关键词
/// - 支持空结果状态
/// - 支持 VoiceOver 无障碍访问
///
/// - Requirements: REQ-1.4
struct SearchResultsView: View {
    
    // MARK: - Properties
    
    /// 搜索结果
    let results: [KnowledgeNode]
    
    /// 搜索关键词
    let query: String
    
    /// ViewModel 引用
    @ObservedObject var viewModel: LifeReviewViewModel
    
    /// 节点点击回调
    let onNodeTap: (KnowledgeNode) -> Void
    
    /// 清除搜索回调
    let onClearSearch: () -> Void
    
    // MARK: - Computed Properties
    
    /// 按维度分组的搜索结果
    private var groupedResults: [(level1: DimensionHierarchy.Level1, nodes: [KnowledgeNode])] {
        let grouped = viewModel.searchNodesGroupedByDimension(query: query)
        return DimensionHierarchy.coreDimensions.compactMap { level1 in
            guard let nodes = grouped[level1], !nodes.isEmpty else { return nil }
            return (level1: level1, nodes: nodes)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if results.isEmpty {
            SearchEmptyStateView(
                query: query,
                onClearSearch: onClearSearch
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // 搜索结果统计
                    searchHeader
                    
                    // 按维度分组显示
                    ForEach(groupedResults, id: \.level1.rawValue) { group in
                        searchResultGroup(level1: group.level1, nodes: group.nodes)
                    }
                    
                    // 底部间距
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// 搜索结果头部
    private var searchHeader: some View {
        HStack {
            Text("搜索结果")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(results.count) 个结果")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    /// 搜索结果分组
    private func searchResultGroup(level1: DimensionHierarchy.Level1, nodes: [KnowledgeNode]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 维度标题
            HStack(spacing: 8) {
                Image(systemName: DimensionIcons.icon(for: level1))
                    .font(.subheadline)
                    .foregroundStyle(DimensionColors.color(for: level1))
                
                Text(level1.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("(\(nodes.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 节点列表
            ForEach(nodes) { node in
                SearchResultRow(
                    node: node,
                    query: query,
                    viewModel: viewModel,
                    onTap: { onNodeTap(node) }
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - SearchResultRow

/// 搜索结果行 - 单个搜索结果的展示
///
/// 设计特点：
/// - 高亮匹配关键词
/// - 显示节点名称和描述
/// - 显示维度路径
private struct SearchResultRow: View {
    
    let node: KnowledgeNode
    let query: String
    @ObservedObject var viewModel: LifeReviewViewModel
    let onTap: () -> Void
    
    /// 主题色
    private var themeColor: Color {
        if let level1 = node.level1Dimension {
            return DimensionColors.color(for: level1)
        }
        return .blue
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 内容类型图标
                contentTypeIcon
                
                // 节点信息
                VStack(alignment: .leading, spacing: 4) {
                    // 名称（高亮）
                    Text(viewModel.highlightSearchQuery(in: node.name, query: query))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // 描述（高亮）
                    if let description = node.description, !description.isEmpty {
                        Text(viewModel.highlightSearchQuery(in: description, query: query))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    // 维度路径
                    if let path = node.typePath {
                        dimensionPath(path)
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
                    .strokeBorder(themeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(node.name)")
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }
    
    /// 内容类型图标
    private var contentTypeIcon: some View {
        Image(systemName: node.contentType.iconName)
            .font(.caption)
            .foregroundStyle(themeColor)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(themeColor.opacity(0.1))
            )
    }
    
    /// 维度路径
    private func dimensionPath(_ path: NodeTypePath) -> some View {
        HStack(spacing: 4) {
            if let level1 = path.level1Dimension {
                Text(level1.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if let level2 = path.level2 {
                Text("›")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                
                Text(DimensionHierarchy.getLevel2DisplayName(level2))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - NodeContentType Extension

extension NodeContentType {
    /// 内容类型对应的图标名称
    var iconName: String {
        switch self {
        case .aiTag:
            return "tag.fill"
        case .subsystem:
            return "square.grid.2x2.fill"
        case .entityRef:
            return "person.fill"
        case .nestedList:
            return "list.bullet.indent"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LifeReviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        LifeReviewScreen()
            .previewDisplayName("Life Review Screen")
    }
}
#endif
