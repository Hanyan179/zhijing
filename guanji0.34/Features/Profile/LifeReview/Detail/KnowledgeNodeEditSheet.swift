import SwiftUI

// MARK: - KnowledgeNodeEditSheet

/// 知识节点编辑 Sheet - 编辑节点的基本信息
///
/// 支持编辑：
/// - 节点名称
/// - 节点描述
/// - 标签
///
/// - Requirements: REQ-7.4
public struct KnowledgeNodeEditSheet: View {
    
    // MARK: - Properties
    
    /// 原始节点
    let originalNode: KnowledgeNode
    
    /// ViewModel 引用
    @ObservedObject var viewModel: LifeReviewViewModel
    
    /// 保存回调
    var onSave: ((KnowledgeNode) -> Void)?
    
    /// 取消回调
    var onCancel: (() -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var tagsText: String = ""
    @State private var showDiscardAlert: Bool = false
    
    // MARK: - Computed Properties
    
    /// 主题色
    private var themeColor: Color {
        if let level1 = originalNode.level1Dimension {
            return DimensionColors.color(for: level1)
        }
        return .blue
    }
    
    /// 是否有修改
    private var hasChanges: Bool {
        name != originalNode.name ||
        description != (originalNode.description ?? "") ||
        tagsText != originalNode.tags.joined(separator: ", ")
    }
    
    /// 是否可以保存
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("名称", text: $name)
                    
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // 标签
                Section {
                    TextField("标签（用逗号分隔）", text: $tagsText)
                } header: {
                    Text("标签")
                } footer: {
                    Text("多个标签请用逗号分隔，如：技术, iOS, Swift")
                }
                
                // 节点信息（只读）
                Section("节点信息") {
                    LabeledContent("类型", value: originalNode.contentType.displayName)
                    LabeledContent("维度", value: originalNode.typePath?.fullDisplayPath ?? originalNode.nodeType)
                    LabeledContent("来源关联", value: "\(originalNode.mentionCount) 次")
                }
            }
            .navigationTitle("编辑节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismissSheet()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("放弃修改？", isPresented: $showDiscardAlert) {
                Button("继续编辑", role: .cancel) { }
                Button("放弃", role: .destructive) {
                    dismissSheet()
                }
            } message: {
                Text("您有未保存的修改，确定要放弃吗？")
            }
        }
        .onAppear {
            loadNodeData()
        }
        .interactiveDismissDisabled(hasChanges)
    }
    
    // MARK: - Methods
    
    /// 加载节点数据到编辑状态
    private func loadNodeData() {
        name = originalNode.name
        description = originalNode.description ?? ""
        tagsText = originalNode.tags.joined(separator: ", ")
    }
    
    /// 保存修改
    private func saveChanges() {
        var updatedNode = originalNode
        updatedNode.name = name.trimmingCharacters(in: .whitespaces)
        updatedNode.description = description.isEmpty ? nil : description
        updatedNode.tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 更新到 ViewModel
        viewModel.updateNode(updatedNode)
        
        // 回调
        onSave?(updatedNode)
        
        dismiss()
    }
    
    /// 关闭 Sheet
    private func dismissSheet() {
        onCancel?()
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct KnowledgeNodeEditSheet_Previews: PreviewProvider {
    static var previews: some View {
        KnowledgeNodeEditSheet(
            originalNode: KnowledgeNode(
                nodeType: "self.personality.self_assessment",
                contentType: .aiTag,
                name: "内向",
                description: "喜欢独处，社交后需要时间恢复精力",
                tags: ["性格", "MBTI"],
                tracking: NodeTracking(source: NodeSource(type: .aiExtracted, confidence: 0.85))
            ),
            viewModel: LifeReviewViewModel()
        )
    }
}
#endif
