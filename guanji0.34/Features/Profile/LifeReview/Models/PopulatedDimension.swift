import Foundation
import SwiftUI

// MARK: - PopulatedDimension

/// 有数据的维度 - 用于 UI 展示
/// 只包含有 KnowledgeNode 数据的维度，空维度不会被创建
///
/// 设计目的：
/// - 过滤空维度，只展示有数据的内容
/// - 按 L1/L2 层级组织节点
/// - 提供 UI 展示所需的颜色和图标配置
///
/// - SeeAlso: `Level2Group` 用于 L2 分组
/// - SeeAlso: `DimensionHierarchy.Level1` 用于维度定义
public struct PopulatedDimension: Identifiable {
    
    // MARK: - Properties
    
    /// 唯一标识符（使用 level1.rawValue）
    public let id: String
    
    /// Level 1 维度
    public let level1: DimensionHierarchy.Level1
    
    /// Level 2 分组列表
    public let level2Groups: [Level2Group]
    
    /// 该维度下的节点总数
    public let totalNodeCount: Int
    
    /// 维度主题色
    public let color: Color
    
    /// 维度图标名称（SF Symbol）
    public let icon: String
    
    // MARK: - Initialization
    
    /// 创建有数据的维度
    /// - Parameters:
    ///   - level1: Level 1 维度枚举
    ///   - level2Groups: Level 2 分组列表
    ///   - color: 维度主题色
    ///   - icon: 维度图标名称
    public init(
        level1: DimensionHierarchy.Level1,
        level2Groups: [Level2Group],
        color: Color,
        icon: String
    ) {
        self.id = level1.rawValue
        self.level1 = level1
        self.level2Groups = level2Groups
        self.totalNodeCount = level2Groups.reduce(0) { $0 + $1.nodes.count }
        self.color = color
        self.icon = icon
    }
    
    // MARK: - Computed Properties
    
    /// 维度中文显示名称
    public var displayName: String {
        level1.displayName
    }
    
    /// 维度英文名称
    public var englishName: String {
        level1.englishName
    }
    
    /// 维度描述
    public var dimensionDescription: String {
        level1.dimensionDescription
    }
    
    /// 是否有数据
    public var hasData: Bool {
        totalNodeCount > 0
    }
    
    /// Level 2 分组数量
    public var level2Count: Int {
        level2Groups.count
    }
}

// MARK: - Level2Group

/// L2 分组 - 用于组织同一 Level 2 维度下的节点
///
/// 设计目的：
/// - 按 Level 2 维度对节点进行分组
/// - 提供分组的显示名称
/// - 支持 UI 中的分组展示
public struct Level2Group: Identifiable {
    
    // MARK: - Properties
    
    /// 唯一标识符（使用 level2 标识）
    public let id: String
    
    /// Level 2 维度标识（如 "identity", "physical"）
    public let level2: String
    
    /// Level 2 维度中文显示名称
    public let displayName: String
    
    /// 该分组下的所有节点
    public let nodes: [KnowledgeNode]
    
    // MARK: - Initialization
    
    /// 创建 L2 分组
    /// - Parameters:
    ///   - level2: Level 2 维度标识
    ///   - displayName: 中文显示名称
    ///   - nodes: 该分组下的节点列表
    public init(
        level2: String,
        displayName: String,
        nodes: [KnowledgeNode]
    ) {
        self.id = level2
        self.level2 = level2
        self.displayName = displayName
        self.nodes = nodes
    }
    
    /// 使用自动获取显示名称的便捷初始化
    /// - Parameters:
    ///   - level2: Level 2 维度标识
    ///   - nodes: 该分组下的节点列表
    public init(level2: String, nodes: [KnowledgeNode]) {
        self.id = level2
        self.level2 = level2
        let resolvedDisplayName = DimensionHierarchy.getLevel2DisplayName(level2)
        // 如果 displayName 为空，使用 level2 原始值；如果 level2 也为空，使用默认值
        if resolvedDisplayName.isEmpty {
            self.displayName = level2.isEmpty ? "未分类" : level2
        } else {
            self.displayName = resolvedDisplayName
        }
        self.nodes = nodes
        #if DEBUG
        print("Level2Group init: level2='\(level2)' -> displayName='\(self.displayName)'")
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// 节点数量
    public var nodeCount: Int {
        nodes.count
    }
    
    /// 是否有数据
    public var hasData: Bool {
        !nodes.isEmpty
    }
}

// MARK: - PopulatedDimension Builder

extension PopulatedDimension {
    
    /// 从节点列表构建有数据的维度列表
    /// - Parameters:
    ///   - nodes: 所有知识节点
    ///   - colorProvider: 颜色提供函数
    ///   - iconProvider: 图标提供函数
    /// - Returns: 有数据的维度列表（已过滤空维度）
    public static func buildFromNodes(
        _ nodes: [KnowledgeNode],
        colorProvider: (DimensionHierarchy.Level1) -> Color,
        iconProvider: (DimensionHierarchy.Level1) -> String
    ) -> [PopulatedDimension] {
        
        // 按 Level 1 分组
        var level1Groups: [DimensionHierarchy.Level1: [KnowledgeNode]] = [:]
        
        for node in nodes {
            guard let path = node.typePath,
                  let level1 = path.level1Dimension else {
                continue
            }
            
            if level1Groups[level1] == nil {
                level1Groups[level1] = []
            }
            level1Groups[level1]?.append(node)
        }
        
        // 构建 PopulatedDimension 列表
        var result: [PopulatedDimension] = []
        
        // 按核心维度顺序遍历
        for level1 in DimensionHierarchy.coreDimensions {
            guard let nodesForLevel1 = level1Groups[level1], !nodesForLevel1.isEmpty else {
                continue
            }
            
            // 按 Level 2 分组
            let level2Groups = buildLevel2Groups(
                from: nodesForLevel1,
                level1: level1
            )
            
            // 只有有数据的维度才添加
            if !level2Groups.isEmpty {
                let dimension = PopulatedDimension(
                    level1: level1,
                    level2Groups: level2Groups,
                    color: colorProvider(level1),
                    icon: iconProvider(level1)
                )
                result.append(dimension)
            }
        }
        
        return result
    }
    
    /// 构建 Level 2 分组
    private static func buildLevel2Groups(
        from nodes: [KnowledgeNode],
        level1: DimensionHierarchy.Level1
    ) -> [Level2Group] {
        
        // 按 Level 2 分组
        var level2Map: [String: [KnowledgeNode]] = [:]
        
        for node in nodes {
            guard let path = node.typePath,
                  let level2 = path.level2 else {
                #if DEBUG
                print("buildLevel2Groups: Skipping node '\(node.name)' - no valid level2 in nodeType '\(node.nodeType)'")
                #endif
                continue
            }
            
            #if DEBUG
            print("buildLevel2Groups: Node '\(node.name)' -> level2='\(level2)' (nodeType: '\(node.nodeType)')")
            #endif
            
            if level2Map[level2] == nil {
                level2Map[level2] = []
            }
            level2Map[level2]?.append(node)
        }
        
        #if DEBUG
        print("buildLevel2Groups: level2Map keys = \(level2Map.keys.sorted())")
        #endif
        
        // 按预定义顺序构建分组
        var result: [Level2Group] = []
        let orderedLevel2s = DimensionHierarchy.getLevel2Dimensions(for: level1)
        
        for level2 in orderedLevel2s {
            if let nodesForLevel2 = level2Map[level2], !nodesForLevel2.isEmpty {
                let group = Level2Group(level2: level2, nodes: nodesForLevel2)
                result.append(group)
            }
        }
        
        // 添加不在预定义列表中的 Level 2（AI 动态创建的）
        for (level2, nodesForLevel2) in level2Map {
            if !orderedLevel2s.contains(level2) && !nodesForLevel2.isEmpty {
                #if DEBUG
                print("buildLevel2Groups: Adding non-predefined level2='\(level2)' with \(nodesForLevel2.count) nodes")
                #endif
                let group = Level2Group(level2: level2, nodes: nodesForLevel2)
                result.append(group)
            }
        }
        
        return result
    }
}

// MARK: - Equatable & Hashable

extension PopulatedDimension: Equatable {
    public static func == (lhs: PopulatedDimension, rhs: PopulatedDimension) -> Bool {
        lhs.id == rhs.id
    }
}

extension PopulatedDimension: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Level2Group: Equatable {
    public static func == (lhs: Level2Group, rhs: Level2Group) -> Bool {
        lhs.id == rhs.id
    }
}

extension Level2Group: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
