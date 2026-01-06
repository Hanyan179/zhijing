import SwiftUI

// MARK: - FlowLayout

/// 流式布局组件 - 自适应换行布局
///
/// 设计特点：
/// - 子视图自动换行，适应容器宽度
/// - 支持自定义水平和垂直间距
/// - 支持对齐方式配置
/// - 使用 SwiftUI 原生布局 API
///
/// 使用示例：
/// ```swift
/// FlowLayout(spacing: 8) {
///     ForEach(tags, id: \.self) { tag in
///         TagView(tag: tag)
///     }
/// }
/// ```
///
/// - Requirements: REQ-4.5, REQ-8.1
public struct FlowLayout: Layout {
    
    // MARK: - Properties
    
    /// 水平间距
    var horizontalSpacing: CGFloat
    
    /// 垂直间距
    var verticalSpacing: CGFloat
    
    /// 对齐方式
    var alignment: HorizontalAlignment
    
    // MARK: - Initialization
    
    /// 创建流式布局
    /// - Parameters:
    ///   - horizontalSpacing: 水平间距，默认 8
    ///   - verticalSpacing: 垂直间距，默认 8
    ///   - alignment: 对齐方式，默认 .leading
    public init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
    }
    
    /// 便捷初始化 - 统一间距
    /// - Parameters:
    ///   - spacing: 统一的水平和垂直间距
    ///   - alignment: 对齐方式，默认 .leading
    public init(
        spacing: CGFloat,
        alignment: HorizontalAlignment = .leading
    ) {
        self.horizontalSpacing = spacing
        self.verticalSpacing = spacing
        self.alignment = alignment
    }
    
    // MARK: - Layout Protocol
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = arrangeSubviews(
            proposal: proposal,
            subviews: subviews
        )
        return result.size
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = arrangeSubviews(
            proposal: proposal,
            subviews: subviews
        )
        
        for (index, position) in result.positions.enumerated() {
            let adjustedX: CGFloat
            
            switch alignment {
            case .leading:
                adjustedX = bounds.minX + position.x
            case .center:
                let rowWidth = result.rowWidths[result.rowIndices[index]]
                let offset = (bounds.width - rowWidth) / 2
                adjustedX = bounds.minX + position.x + offset
            case .trailing:
                let rowWidth = result.rowWidths[result.rowIndices[index]]
                let offset = bounds.width - rowWidth
                adjustedX = bounds.minX + position.x + offset
            default:
                adjustedX = bounds.minX + position.x
            }
            
            subviews[index].place(
                at: CGPoint(x: adjustedX, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 计算子视图排列
    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        
        var positions: [CGPoint] = []
        var rowWidths: [CGFloat] = []
        var rowIndices: [Int] = []
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowIndex = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // 检查是否需要换行
            if currentX + size.width > maxWidth && currentX > 0 {
                // 保存当前行宽度
                rowWidths.append(currentRowWidth - horizontalSpacing)
                
                // 换行
                currentX = 0
                currentY += currentRowHeight + verticalSpacing
                currentRowHeight = 0
                currentRowWidth = 0
                currentRowIndex += 1
            }
            
            // 记录位置
            positions.append(CGPoint(x: currentX, y: currentY))
            rowIndices.append(currentRowIndex)
            
            // 更新当前位置
            currentX += size.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, size.height)
            currentRowWidth = currentX
        }
        
        // 保存最后一行宽度
        if currentRowWidth > 0 {
            rowWidths.append(currentRowWidth - horizontalSpacing)
        }
        
        // 计算总尺寸
        let totalHeight = currentY + currentRowHeight
        let totalWidth = rowWidths.max() ?? 0
        
        return ArrangementResult(
            positions: positions,
            rowWidths: rowWidths,
            rowIndices: rowIndices,
            size: CGSize(width: totalWidth, height: totalHeight)
        )
    }
    
    /// 排列结果
    private struct ArrangementResult {
        let positions: [CGPoint]
        let rowWidths: [CGFloat]
        let rowIndices: [Int]
        let size: CGSize
    }
}

// MARK: - FlowLayoutView (ViewBuilder Wrapper)

/// FlowLayout 的 ViewBuilder 包装器
///
/// 提供更便捷的使用方式：
/// ```swift
/// FlowLayoutView(spacing: 8) {
///     ForEach(items) { item in
///         ItemView(item: item)
///     }
/// }
/// ```
public struct FlowLayoutView<Content: View>: View {
    
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content
    
    public init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
        self.content = content()
    }
    
    public init(
        spacing: CGFloat,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalSpacing = spacing
        self.verticalSpacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    public var body: some View {
        FlowLayout(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            alignment: alignment
        ) {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FlowLayout_Previews: PreviewProvider {
    static let sampleTags = [
        "Swift", "iOS", "SwiftUI", "Combine", "UIKit",
        "Core Data", "CloudKit", "ARKit", "Metal",
        "Machine Learning", "Vision", "Natural Language"
    ]
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FlowLayout Demo")
                .font(.headline)
            
            FlowLayoutView(spacing: 8) {
                ForEach(sampleTags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Divider()
            
            Text("Center Aligned")
                .font(.headline)
            
            FlowLayoutView(spacing: 8, alignment: .center) {
                ForEach(sampleTags.prefix(6), id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
