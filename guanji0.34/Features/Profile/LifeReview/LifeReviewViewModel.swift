import SwiftUI
import Combine
import Foundation

// MARK: - LifeReviewViewModel

/// 人生回顾 ViewModel - 管理 LifeReviewScreen 的数据和业务逻辑
///
/// 核心职责：
/// - 从 NarrativeUserProfileRepository 加载用户画像数据
/// - 按 L1/L2 维度分组节点，过滤空维度
/// - 提供搜索功能
/// - 管理测试数据导入
///
/// 设计原则：
/// - 使用 @MainActor 确保 UI 更新在主线程
/// - 使用 @Published 属性驱动 SwiftUI 视图更新
/// - 遵循 MVVM 架构，View/ViewModel/Model 职责分离
///
/// - SeeAlso: `PopulatedDimension` 用于 UI 展示的维度数据
/// - SeeAlso: `NarrativeUserProfileRepository` 数据持久化
@MainActor
public final class LifeReviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 用户画像数据
    @Published public var userProfile: NarrativeUserProfile?
    
    /// 有数据的维度列表（已过滤空维度）
    @Published public var populatedDimensions: [PopulatedDimension] = []
    
    /// 加载状态
    @Published public var isLoading: Bool = false
    
    /// 搜索文本
    @Published public var searchText: String = ""
    
    /// 搜索结果
    @Published public var searchResults: [KnowledgeNode] = []
    
    /// 是否正在搜索
    @Published public var isSearching: Bool = false
    
    /// 错误信息
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// 所有知识节点缓存
    private var allNodes: [KnowledgeNode] = []
    
    /// 节点 ID 到节点的映射（用于快速查找）
    private var nodeMap: [String: KnowledgeNode] = [:]
    
    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// Repository 依赖
    private let repository: NarrativeUserProfileRepository
    
    // MARK: - Computed Properties
    
    /// 节点总数
    public var totalNodeCount: Int {
        allNodes.count
    }
    
    /// 是否有数据
    public var hasData: Bool {
        !allNodes.isEmpty
    }
    
    /// 是否显示空状态
    public var showEmptyState: Bool {
        !isLoading && populatedDimensions.isEmpty
    }
    
    /// 用户基本信息
    public var userBasicInfo: (name: String?, occupation: String?, city: String?) {
        guard let profile = userProfile else { return (nil, nil, nil) }
        return (
            profile.staticCore.nickname,
            profile.staticCore.occupation,
            profile.staticCore.currentCity
        )
    }
    
    // MARK: - Initialization
    
    /// 初始化 ViewModel
    /// - Parameter repository: NarrativeUserProfileRepository 实例，默认使用 shared 单例
    @MainActor
    public init(repository: NarrativeUserProfileRepository? = nil) {
        self.repository = repository ?? NarrativeUserProfileRepository.shared
        setupSearchBinding()
    }
    
    // MARK: - Private Setup
    
    /// 设置搜索文本的防抖绑定
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    /// 执行搜索
    private func performSearch(query: String) {
        if query.isEmpty {
            isSearching = false
            searchResults = []
        } else {
            isSearching = true
            searchResults = searchNodes(query: query)
        }
    }
}


// MARK: - Data Loading

extension LifeReviewViewModel {
    
    /// 加载数据
    /// 从 Repository 加载用户画像，构建有数据的维度列表
    public func loadData() {
        isLoading = true
        errorMessage = nil
        
        // 从 Repository 加载数据
        let profile = repository.load()
        self.userProfile = profile
        self.allNodes = profile.knowledgeNodes
        
        // 构建节点映射
        buildNodeMap()
        
        // 构建有数据的维度列表
        buildPopulatedDimensions()
        
        isLoading = false
    }
    
    /// 刷新数据
    /// 强制从磁盘重新加载数据
    public func refresh() {
        repository.reload()
        loadData()
    }
    
    /// 构建节点 ID 到节点的映射
    private func buildNodeMap() {
        nodeMap = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })
    }
    
    /// 构建有数据的维度列表
    /// 按 L1/L2 分组节点，过滤空维度
    public func buildPopulatedDimensions() {
        #if DEBUG
        print("LifeReviewViewModel: Building populated dimensions from \(allNodes.count) nodes")
        for node in allNodes.prefix(5) {
            print("  - Node: \(node.name), nodeType: \(node.nodeType), typePath: \(String(describing: node.typePath))")
        }
        #endif
        
        populatedDimensions = PopulatedDimension.buildFromNodes(
            allNodes,
            colorProvider: { DimensionColors.color(for: $0) },
            iconProvider: { DimensionIcons.icon(for: $0) }
        )
        
        #if DEBUG
        print("LifeReviewViewModel: Built \(populatedDimensions.count) populated dimensions")
        for dim in populatedDimensions {
            print("  - \(dim.displayName): \(dim.totalNodeCount) nodes, \(dim.level2Groups.count) L2 groups")
            for group in dim.level2Groups {
                print("    - L2: '\(group.level2)' -> displayName: '\(group.displayName)', nodes: \(group.nodeCount)")
            }
        }
        #endif
    }
    
    /// 获取指定 Level 1 维度的节点
    /// - Parameter level1: Level 1 维度
    /// - Returns: 该维度下的所有节点
    public func getNodes(for level1: DimensionHierarchy.Level1) -> [KnowledgeNode] {
        allNodes.filter { $0.matchesLevel1(level1) }
    }
    
    /// 获取指定维度路径的节点
    /// - Parameters:
    ///   - level1: Level 1 维度
    ///   - level2: Level 2 维度标识（可选）
    ///   - level3: Level 3 维度标识（可选）
    /// - Returns: 匹配的节点列表
    public func getNodes(
        level1: DimensionHierarchy.Level1,
        level2: String? = nil,
        level3: String? = nil
    ) -> [KnowledgeNode] {
        var prefix = level1.rawValue
        if let l2 = level2 {
            prefix += ".\(l2)"
            if let l3 = level3 {
                prefix += ".\(l3)"
            }
        }
        
        return allNodes.filter { $0.nodeType.hasPrefix(prefix) || $0.nodeType == prefix }
    }
    
    /// 获取单个节点
    /// - Parameter id: 节点 ID
    /// - Returns: 对应的节点，如果不存在则返回 nil
    public func getNode(id: String) -> KnowledgeNode? {
        nodeMap[id]
    }
    
    /// 获取子节点
    /// - Parameter parentId: 父节点 ID
    /// - Returns: 所有子节点列表
    public func getChildNodes(parentId: String) -> [KnowledgeNode] {
        allNodes.filter { $0.parentNodeId == parentId }
    }
    
    /// 获取节点的完整子节点树（递归）
    /// - Parameter parentId: 父节点 ID
    /// - Returns: 所有后代节点列表（包括子节点的子节点）
    public func getAllDescendantNodes(parentId: String) -> [KnowledgeNode] {
        var result: [KnowledgeNode] = []
        let directChildren = getChildNodes(parentId: parentId)
        
        for child in directChildren {
            result.append(child)
            result.append(contentsOf: getAllDescendantNodes(parentId: child.id))
        }
        
        return result
    }
    
    /// 获取节点按内容类型分组
    /// - Parameters:
    ///   - level1: Level 1 维度
    ///   - level2: Level 2 维度标识
    /// - Returns: 按 NodeContentType 分组的节点字典
    public func getNodesGroupedByContentType(
        level1: DimensionHierarchy.Level1,
        level2: String
    ) -> [NodeContentType: [KnowledgeNode]] {
        let nodes = getNodes(level1: level1, level2: level2)
        return Dictionary(grouping: nodes) { $0.contentType }
    }
    
    /// 获取需要审核的节点
    /// - Returns: 所有 needsReview 为 true 的节点
    public var nodesNeedingReview: [KnowledgeNode] {
        allNodes.filter { $0.needsReview }
    }
    
    /// 获取未确认的 AI 节点
    /// - Returns: 所有来自 AI 且未被用户确认的节点
    public var unconfirmedAINodes: [KnowledgeNode] {
        allNodes.filter { $0.isFromAI && !$0.isConfirmed }
    }
    
    /// 获取最近更新的节点
    /// - Parameter limit: 返回数量限制
    /// - Returns: 按更新时间降序排列的节点列表
    public func getRecentlyUpdatedNodes(limit: Int = 10) -> [KnowledgeNode] {
        Array(allNodes.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }
    
    /// 获取高置信度节点
    /// - Parameter threshold: 置信度阈值，默认 0.8
    /// - Returns: 置信度高于阈值的节点列表
    public func getHighConfidenceNodes(threshold: Double = 0.8) -> [KnowledgeNode] {
        allNodes.filter { $0.currentConfidence >= threshold }
    }
}


// MARK: - Search

extension LifeReviewViewModel {
    
    /// 搜索节点
    /// 支持按 name, description, tags 搜索
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的节点列表
    public func searchNodes(query: String) -> [KnowledgeNode] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        return allNodes.filter { node in
            // 搜索 name
            if node.name.lowercased().contains(lowercasedQuery) {
                return true
            }
            
            // 搜索 description
            if let description = node.description,
               description.lowercased().contains(lowercasedQuery) {
                return true
            }
            
            // 搜索 tags
            if node.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                return true
            }
            
            return false
        }
    }
    
    /// 搜索节点并按维度分组
    /// - Parameter query: 搜索关键词
    /// - Returns: 按 Level 1 维度分组的搜索结果
    public func searchNodesGroupedByDimension(query: String) -> [DimensionHierarchy.Level1: [KnowledgeNode]] {
        let results = searchNodes(query: query)
        
        var grouped: [DimensionHierarchy.Level1: [KnowledgeNode]] = [:]
        
        for node in results {
            if let level1 = node.level1Dimension {
                if grouped[level1] == nil {
                    grouped[level1] = []
                }
                grouped[level1]?.append(node)
            }
        }
        
        return grouped
    }
    
    /// 高亮搜索关键词
    /// - Parameters:
    ///   - text: 原始文本
    ///   - query: 搜索关键词
    /// - Returns: 带高亮标记的 AttributedString
    public func highlightSearchQuery(in text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        guard !query.isEmpty else { return attributedString }
        
        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()
        
        var searchStartIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedQuery, range: searchStartIndex..<lowercasedText.endIndex) {
            // 转换为 AttributedString 的范围
            let startOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound)
            let endOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound)
            
            let attrStart = attributedString.index(attributedString.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributedString.index(attributedString.startIndex, offsetByCharacters: endOffset)
            
            attributedString[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.3)
            attributedString[attrStart..<attrEnd].foregroundColor = .primary
            
            searchStartIndex = range.upperBound
        }
        
        return attributedString
    }
    
    /// 清除搜索
    public func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
}

// MARK: - Test Data Import

extension LifeReviewViewModel {
    
    /// 导入测试数据
    /// 仅在 DEBUG 模式下可用
    /// - Requirements: REQ-5.1, REQ-5.2, REQ-5.3, REQ-5.4, REQ-5.5
    public func importTestData() {
        #if DEBUG
        print("LifeReviewViewModel: Importing test data...")
        
        // 使用 TestDataGenerator 生成测试数据
        let testProfile = TestDataGenerator.generateTestProfile()
        
        print("LifeReviewViewModel: Generated \(testProfile.knowledgeNodes.count) nodes")
        
        // 保存到 Repository
        repository.save(testProfile)
        
        print("LifeReviewViewModel: Test data saved to repository")
        
        // 直接更新本地状态（不依赖 refresh）
        self.userProfile = testProfile
        self.allNodes = testProfile.knowledgeNodes
        
        // 构建节点映射
        buildNodeMap()
        
        // 构建有数据的维度列表
        buildPopulatedDimensions()
        
        print("LifeReviewViewModel: Test data imported successfully. Node count: \(allNodes.count), Dimensions: \(populatedDimensions.count)")
        #endif
    }
    
    /// 清除所有知识节点数据
    /// 仅在 DEBUG 模式下可用
    public func clearAllNodes() {
        #if DEBUG
        guard var profile = userProfile else { return }
        profile.knowledgeNodes = []
        repository.save(profile)
        refresh()
        #endif
    }
}

// MARK: - Node Operations

extension LifeReviewViewModel {
    
    /// 确认节点
    /// - Parameter nodeId: 节点 ID
    public func confirmNode(nodeId: String) {
        guard var profile = userProfile,
              let index = profile.knowledgeNodes.firstIndex(where: { $0.id == nodeId }) else {
            return
        }
        
        profile.knowledgeNodes[index].confirm()
        repository.save(profile)
        
        // 更新本地缓存
        allNodes = profile.knowledgeNodes
        buildNodeMap()
        buildPopulatedDimensions()
    }
    
    /// 删除节点
    /// - Parameter nodeId: 节点 ID
    public func deleteNode(nodeId: String) {
        guard var profile = userProfile else { return }
        
        profile.knowledgeNodes.removeAll { $0.id == nodeId }
        repository.save(profile)
        
        // 更新本地缓存
        allNodes = profile.knowledgeNodes
        buildNodeMap()
        buildPopulatedDimensions()
    }
    
    /// 添加节点
    /// - Parameter node: 要添加的节点
    public func addNode(_ node: KnowledgeNode) {
        guard var profile = userProfile else { return }
        
        profile.knowledgeNodes.append(node)
        repository.save(profile)
        
        // 更新本地缓存
        allNodes = profile.knowledgeNodes
        buildNodeMap()
        buildPopulatedDimensions()
    }
    
    /// 更新节点
    /// - Parameter node: 更新后的节点
    public func updateNode(_ node: KnowledgeNode) {
        guard var profile = userProfile,
              let index = profile.knowledgeNodes.firstIndex(where: { $0.id == node.id }) else {
            return
        }
        
        var updatedNode = node
        updatedNode.updatedAt = Date()
        profile.knowledgeNodes[index] = updatedNode
        repository.save(profile)
        
        // 更新本地缓存
        allNodes = profile.knowledgeNodes
        buildNodeMap()
        buildPopulatedDimensions()
    }
}

// MARK: - Confidence Helpers

extension LifeReviewViewModel {
    
    /// 获取置信度颜色
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: 对应的颜色
    public func confidenceColor(_ confidence: Double) -> Color {
        ConfidenceColors.color(for: confidence)
    }
    
    /// 获取置信度标签
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: 显示文本
    public func confidenceLabel(_ confidence: Double) -> String {
        ConfidenceColors.label(for: confidence)
    }
    
    /// 获取置信度图标
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: SF Symbol 名称
    public func confidenceIcon(_ confidence: Double) -> String {
        ConfidenceColors.icon(for: confidence)
    }
}

// MARK: - Statistics

extension LifeReviewViewModel {
    
    /// 获取维度统计信息
    /// - Returns: 各维度的节点数量统计
    public func getDimensionStatistics() -> [(level1: DimensionHierarchy.Level1, count: Int)] {
        DimensionHierarchy.coreDimensions.map { level1 in
            let count = allNodes.filter { $0.matchesLevel1(level1) }.count
            return (level1: level1, count: count)
        }
    }
    
    /// 获取内容类型统计信息
    /// - Returns: 各内容类型的节点数量统计
    public func getContentTypeStatistics() -> [(contentType: NodeContentType, count: Int)] {
        NodeContentType.allCases.map { contentType in
            let count = allNodes.filter { $0.contentType == contentType }.count
            return (contentType: contentType, count: count)
        }
    }
    
    /// 获取来源类型统计信息
    /// - Returns: 各来源类型的节点数量统计
    public func getSourceTypeStatistics() -> [(sourceType: SourceType, count: Int)] {
        let sourceTypes: [SourceType] = [.userInput, .aiExtracted, .aiInferred]
        return sourceTypes.map { sourceType in
            let count = allNodes.filter { $0.tracking.source.type == sourceType }.count
            return (sourceType: sourceType, count: count)
        }
    }
}
