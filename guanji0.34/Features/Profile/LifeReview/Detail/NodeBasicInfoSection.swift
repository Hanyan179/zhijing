import SwiftUI

// MARK: - NodeBasicInfoSection

/// 节点基本信息区块 - 显示节点名称、描述、标签和维度路径
///
/// 设计特点：
/// - 清晰展示节点核心信息
/// - 显示维度路径（L1 > L2 > L3）
/// - 标签使用流式布局
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// NodeBasicInfoSection(node: node, color: .blue)
/// ```
///
/// - SeeAlso: `KnowledgeNode` 知识节点模型
/// - SeeAlso: `NodeTypePath` 维度路径解析
/// - Requirements: REQ-7.1
public struct NodeBasicInfoSection: View {
    
    // MARK: - Properties
    
    /// 知识节点
    let node: KnowledgeNode
    
    /// 主题色
    let color: Color
    
    // MARK: - Computed Properties
    
    /// 维度路径
    private var dimensionPath: String {
        node.typePath?.fullDisplayPath ?? node.nodeType
    }
    
    /// 内容类型显示名称
    private var contentTypeLabel: String {
        node.contentType.displayName
    }
    
    // MARK: - Initialization
    
    /// 创建节点基本信息区块
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
            // 维度路径
            dimensionPathView
            
            // 节点名称
            nameView
            
            // 描述
            if let description = node.description, !description.isEmpty {
                descriptionView(description)
            }
            
            // 标签
            if !node.tags.isEmpty {
                tagsView
            }
            
            // 内容类型
            contentTypeView
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 维度路径视图
    private var dimensionPathView: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.caption)
                .foregroundStyle(color)
            
            Text(dimensionPath)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("维度路径：\(dimensionPath)")
    }
    
    /// 节点名称视图
    private var nameView: some View {
        HStack(alignment: .top, spacing: 8) {
            // 内容类型图标
            Image(systemName: ContentTypeIcons.icon(for: node.contentType))
                .font(.title2)
                .foregroundStyle(color)
            
            Text(node.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("名称：\(node.name)")
    }
    
    /// 描述视图
    private func descriptionView(_ description: String) -> some View {
        Text(description)
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("描述：\(description)")
    }
    
    /// 标签视图
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            FlowLayoutView(spacing: 8) {
                ForEach(node.tags, id: \.self) { tag in
                    NodeTagChip(text: tag, color: color)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("标签：\(node.tags.joined(separator: "、"))")
    }
    
    /// 内容类型视图
    private var contentTypeView: some View {
        HStack(spacing: 6) {
            Text("类型")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(contentTypeLabel)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.1))
                )
        }
        .accessibilityLabel("内容类型：\(contentTypeLabel)")
    }
}

// MARK: - NodeTagChip

/// 节点标签芯片组件（本地使用，避免与其他 TagChip 冲突）
private struct NodeTagChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#if DEBUG
struct NodeBasicInfoSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 完整信息节点
                NodeBasicInfoSection(
                    node: sampleFullNode,
                    color: .blue
                )
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Divider()
                
                // 简单节点（无描述和标签）
                NodeBasicInfoSection(
                    node: sampleSimpleNode,
                    color: .orange
                )
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleFullNode: KnowledgeNode {
        KnowledgeNode(
            nodeType: "achievements.competencies.professional_skills",
            contentType: .aiTag,
            name: "Swift 编程",
            description: "iOS 开发主力语言，熟练掌握 SwiftUI、Combine 等现代框架，有多年实战经验。",
            tags: ["编程", "iOS", "移动开发", "技术"],
            tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.85))
        )
    }
    
    static var sampleSimpleNode: KnowledgeNode {
        KnowledgeNode(
            nodeType: "spirit.ideology.values",
            contentType: .aiTag,
            name: "家庭优先",
            tracking: NodeTracking(source: NodeSource(type: .userInput, confidence: 1.0))
        )
    }
}
#endif
