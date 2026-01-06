import SwiftUI

// MARK: - EmptyStateView

/// 空状态视图 - 显示引导用户添加数据的提示
///
/// 设计特点：
/// - 温暖、友好的视觉风格
/// - 清晰的引导文案
/// - 包含"开始对话"按钮
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// EmptyStateView(
///     onStartConversation: {
///         // 跳转到 AI 对话页面
///     }
/// )
/// ```
///
/// - Requirements: REQ-3.4
public struct EmptyStateView: View {
    
    // MARK: - Properties
    
    /// 开始对话回调
    let onStartConversation: (() -> Void)?
    
    /// 自定义标题
    var title: String = "开始记录你的人生故事"
    
    /// 自定义描述
    var subtitle: String = "通过与 AI 对话，让我们一起发现和记录你的技能、价值观、经历和梦想"
    
    /// 按钮文本
    var buttonTitle: String = "开始对话"
    
    /// 是否显示按钮
    var showButton: Bool = true
    
    // MARK: - Initialization
    
    /// 创建空状态视图
    /// - Parameter onStartConversation: 开始对话回调
    public init(onStartConversation: (() -> Void)? = nil) {
        self.onStartConversation = onStartConversation
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 插图
            illustrationView
            
            // 文案
            textContent
            
            // 按钮
            if showButton, let action = onStartConversation {
                actionButton(action: action)
            }
            
            // 提示
            tipsView
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 插图视图
    private var illustrationView: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.1),
                            Color.blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            // 图标
            Image(systemName: "book.pages.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .accessibilityHidden(true)
    }
    
    /// 文案内容
    private var textContent: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .accessibilityElement(children: .combine)
    }
    
    /// 操作按钮
    private func actionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.body)
                
                Text(buttonTitle)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(buttonTitle)
        .accessibilityHint("点击开始与 AI 对话，记录你的人生故事")
    }
    
    /// 提示视图
    private var tipsView: some View {
        VStack(spacing: 16) {
            Text("你可以告诉 AI：")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            HStack(spacing: 12) {
                tipBubble("我的技能")
                tipBubble("我的价值观")
                tipBubble("我的经历")
            }
        }
        .padding(.top, 8)
    }
    
    /// 提示气泡
    private func tipBubble(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
    }
}

// MARK: - EmptyStateView Modifiers

extension EmptyStateView {
    
    /// 设置自定义标题
    public func title(_ title: String) -> EmptyStateView {
        var view = self
        view.title = title
        return view
    }
    
    /// 设置自定义描述
    public func subtitle(_ subtitle: String) -> EmptyStateView {
        var view = self
        view.subtitle = subtitle
        return view
    }
    
    /// 设置按钮文本
    public func buttonTitle(_ title: String) -> EmptyStateView {
        var view = self
        view.buttonTitle = title
        return view
    }
    
    /// 设置是否显示按钮
    public func showButton(_ show: Bool) -> EmptyStateView {
        var view = self
        view.showButton = show
        return view
    }
}

// MARK: - DimensionEmptyStateView

/// 维度空状态视图 - 特定维度没有数据时显示
///
/// 适用于单个维度为空的场景
public struct DimensionEmptyStateView: View {
    
    let level1: DimensionHierarchy.Level1
    let onAddData: (() -> Void)?
    
    public init(
        level1: DimensionHierarchy.Level1,
        onAddData: (() -> Void)? = nil
    ) {
        self.level1 = level1
        self.onAddData = onAddData
    }
    
    private var color: Color {
        DimensionColors.color(for: level1)
    }
    
    private var icon: String {
        DimensionIcons.icon(for: level1)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            // 文案
            VStack(spacing: 4) {
                Text("\(level1.displayName)维度暂无数据")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("通过对话添加你的\(level1.displayName.prefix(2))信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 按钮
            if let action = onAddData {
                Button(action: action) {
                    Text("添加数据")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.1))
                        )
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - SearchEmptyStateView

/// 搜索空状态视图 - 搜索无结果时显示
public struct SearchEmptyStateView: View {
    
    let query: String
    let onClearSearch: (() -> Void)?
    
    public init(
        query: String,
        onClearSearch: (() -> Void)? = nil
    ) {
        self.query = query
        self.onClearSearch = onClearSearch
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // 图标
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            
            // 文案
            VStack(spacing: 4) {
                Text("未找到相关结果")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("没有找到与「\(query)」相关的内容")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 建议
            VStack(alignment: .leading, spacing: 8) {
                Text("建议：")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                VStack(alignment: .leading, spacing: 4) {
                    suggestionRow("检查关键词是否正确")
                    suggestionRow("尝试使用更简短的关键词")
                    suggestionRow("尝试搜索相关的同义词")
                }
            }
            .padding(.top, 8)
            
            // 清除搜索按钮
            if let action = onClearSearch {
                Button(action: action) {
                    Text("清除搜索")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
    }
    
    private func suggestionRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundStyle(.tertiary)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Main Empty State
            EmptyStateView(onStartConversation: {})
                .previewDisplayName("Main Empty State")
            
            // Dimension Empty State
            VStack(spacing: 16) {
                ForEach(DimensionHierarchy.coreDimensions.prefix(3), id: \.rawValue) { level1 in
                    DimensionEmptyStateView(level1: level1, onAddData: {})
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Dimension Empty States")
            
            // Search Empty State
            SearchEmptyStateView(query: "Swift 编程", onClearSearch: {})
                .previewDisplayName("Search Empty State")
        }
    }
}
#endif
