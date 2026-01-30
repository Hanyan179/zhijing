import SwiftUI
import Combine
import Foundation

// MARK: - Dimension Statistics

/// Statistics for a dimension (Level 1 or Level 2)
public struct DimensionStats: Identifiable {
    public let id: String
    public let dimension: String
    public let displayName: String
    public let nodeCount: Int
    public let lastUpdated: Date?
    
    public init(dimension: String, displayName: String, nodeCount: Int, lastUpdated: Date?) {
        self.id = dimension
        self.dimension = dimension
        self.displayName = displayName
        self.nodeCount = nodeCount
        self.lastUpdated = lastUpdated
    }
}

/// Level 1 dimension card data
public struct Level1DimensionCard: Identifiable {
    public let id: String
    public let level1: DimensionHierarchy.Level1
    public let icon: String
    public let color: Color
    public let stats: DimensionStats
    
    public init(level1: DimensionHierarchy.Level1, icon: String, color: Color, stats: DimensionStats) {
        self.id = level1.rawValue
        self.level1 = level1
        self.icon = icon
        self.color = color
        self.stats = stats
    }
}

// MARK: - ViewModel

@MainActor
public final class DimensionProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var userProfile: NarrativeUserProfile?
    @Published public var level1Cards: [Level1DimensionCard] = []
    @Published public var isLoading: Bool = false
    @Published public var searchText: String = ""
    
    // MARK: - Private Properties
    
    private var allNodes: [KnowledgeNode] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Level 1 Dimension Icons & Colors
    
    private let level1Icons: [DimensionHierarchy.Level1: String] = [
        .self_: "person.fill",
        .material: "dollarsign.circle.fill",
        .achievements: "star.fill",
        .experiences: "airplane",
        .spirit: "brain.head.profile"
    ]
    
    private let level1Colors: [DimensionHierarchy.Level1: Color] = [
        .self_: Colors.indigo,
        .material: Colors.emerald,
        .achievements: Colors.amber,
        .experiences: Colors.sky,
        .spirit: Colors.violet
    ]
    
    // MARK: - Initialization
    
    public init() {
        setupSearchBinding()
    }
    
    // MARK: - Public Methods
    
    /// Load data from NarrativeUserProfile
    public func loadData() {
        isLoading = true
        
        let profile = NarrativeUserProfileRepository.shared.load()
        self.userProfile = profile
        self.allNodes = profile.knowledgeNodes
        
        buildLevel1Cards()
        isLoading = false
    }
    
    /// Get Level 2 dimensions for a Level 1 dimension
    public func getLevel2Stats(for level1: DimensionHierarchy.Level1) -> [DimensionStats] {
        let level2Dimensions = DimensionHierarchy.getLevel2Dimensions(for: level1)
        
        return level2Dimensions.map { level2 in
            let prefix = "\(level1.rawValue).\(level2)"
            let nodes = allNodes.filter { $0.nodeType.hasPrefix(prefix) }
            let lastUpdated = nodes.map { $0.updatedAt }.max()
            let displayName = DimensionHierarchy.getLevel2DisplayName(level2)
            
            return DimensionStats(
                dimension: level2,
                displayName: displayName,
                nodeCount: nodes.count,
                lastUpdated: lastUpdated
            )
        }
    }
    
    /// Get nodes for a specific dimension path
    public func getNodes(level1: DimensionHierarchy.Level1, level2: String? = nil, level3: String? = nil) -> [KnowledgeNode] {
        var prefix = level1.rawValue
        if let l2 = level2 {
            prefix += ".\(l2)"
            if let l3 = level3 {
                prefix += ".\(l3)"
            }
        }
        
        return allNodes.filter { $0.nodeType.hasPrefix(prefix) || $0.nodeType == prefix }
    }
    
    /// Get nodes grouped by content type
    public func getNodesGroupedByContentType(level1: DimensionHierarchy.Level1, level2: String) -> [NodeContentType: [KnowledgeNode]] {
        let nodes = getNodes(level1: level1, level2: level2)
        return Dictionary(grouping: nodes) { $0.contentType }
    }
    
    /// Get child nodes for a parent node (for nested_list type)
    public func getChildNodes(parentId: String) -> [KnowledgeNode] {
        return allNodes.filter { $0.parentNodeId == parentId }
    }
    
    /// Get a single node by ID
    public func getNode(id: String) -> KnowledgeNode? {
        return allNodes.first { $0.id == id }
    }
    
    /// Search nodes by name or description
    public func searchNodes(query: String) -> [KnowledgeNode] {
        guard !query.isEmpty else { return [] }
        let lowercased = query.lowercased()
        return allNodes.filter {
            $0.name.lowercased().contains(lowercased) ||
            ($0.description?.lowercased().contains(lowercased) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    /// Get user basic info from staticCore
    public var userBasicInfo: (name: String?, occupation: String?, city: String?) {
        guard let profile = userProfile else { return (nil, nil, nil) }
        return (
            profile.staticCore.nickname,
            profile.staticCore.occupation,
            profile.staticCore.currentCity
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func buildLevel1Cards() {
        let coreDimensions = DimensionHierarchy.coreDimensions
        
        level1Cards = coreDimensions.map { level1 in
            let nodes = allNodes.filter { $0.matchesLevel1(level1) }
            let lastUpdated = nodes.map { $0.updatedAt }.max()
            
            let stats = DimensionStats(
                dimension: level1.rawValue,
                displayName: level1.displayName,
                nodeCount: nodes.count,
                lastUpdated: lastUpdated
            )
            
            return Level1DimensionCard(
                level1: level1,
                icon: level1Icons[level1] ?? "folder.fill",
                color: level1Colors[level1] ?? Colors.indigo,
                stats: stats
            )
        }
    }
}

// MARK: - Confidence Helpers

extension DimensionProfileViewModel {
    
    /// Get confidence color based on value
    public func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0: return Colors.green
        case 0.6..<0.8: return Colors.emerald
        case 0.4..<0.6: return Colors.amber
        case 0.2..<0.4: return Colors.orange
        default: return Colors.red
        }
    }
    
    /// Get confidence label
    public func confidenceLabel(_ confidence: Double) -> String {
        switch confidence {
        case 0.8...1.0: return "高置信"
        case 0.6..<0.8: return "较高"
        case 0.4..<0.6: return "中等"
        case 0.2..<0.4: return "较低"
        default: return "低置信"
        }
    }
}
