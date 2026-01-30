import SwiftUI

// MARK: - ConfidenceIndicator

/// 置信度指示器组件 - 使用颜色和图标直观展示置信度
///
/// 设计特点：
/// - 根据置信度显示不同颜色（绿/蓝/橙/红）
/// - 显示对应的 SF Symbol 图标
/// - 支持紧凑和完整两种显示模式
/// - 支持 VoiceOver 无障碍访问
///
/// 置信度等级：
/// - 0.9 ~ 1.0: 高置信度（绿色，checkmark）
/// - 0.7 ~ 0.9: AI推测（蓝色，questionmark）
/// - 0.5 ~ 0.7: 待确认（橙色，exclamationmark）
/// - < 0.5: 低置信度（红色，xmark）
///
/// 使用示例：
/// ```swift
/// // 紧凑模式（仅图标）
/// ConfidenceIndicator(confidence: 0.75)
///
/// // 完整模式（图标 + 标签）
/// ConfidenceIndicator(confidence: 0.75, style: .full)
/// ```
///
/// - SeeAlso: `ConfidenceColors` 置信度颜色配置
/// - Requirements: REQ-4.3
public struct ConfidenceIndicator: View {
    
    // MARK: - Display Style
    
    /// 显示样式
    public enum DisplayStyle {
        /// 紧凑模式 - 仅显示图标
        case compact
        /// 完整模式 - 显示图标和标签
        case full
        /// 进度条模式 - 显示进度条
        case progress
    }
    
    // MARK: - Properties
    
    /// 置信度值 (0.0 ~ 1.0)
    let confidence: Double
    
    /// 显示样式
    let style: DisplayStyle
    
    /// 图标大小
    let iconSize: Font
    
    // MARK: - Computed Properties
    
    /// 置信度颜色
    private var color: Color {
        ConfidenceColors.color(for: confidence)
    }
    
    /// 置信度图标
    private var icon: String {
        ConfidenceColors.icon(for: confidence)
    }
    
    /// 置信度标签
    private var label: String {
        ConfidenceColors.label(for: confidence)
    }
    
    /// 置信度百分比文本
    private var percentageText: String {
        "\(Int(confidence * 100))%"
    }
    
    // MARK: - Initialization
    
    /// 创建置信度指示器
    /// - Parameters:
    ///   - confidence: 置信度值 (0.0 ~ 1.0)
    ///   - style: 显示样式，默认 .compact
    ///   - iconSize: 图标大小，默认 .caption
    public init(
        confidence: Double,
        style: DisplayStyle = .compact,
        iconSize: Font = .caption
    ) {
        self.confidence = min(max(confidence, 0), 1) // 限制在 0-1 范围
        self.style = style
        self.iconSize = iconSize
    }
    
    // MARK: - Body
    
    public var body: some View {
        switch style {
        case .compact:
            compactView
        case .full:
            fullView
        case .progress:
            progressView
        }
    }
    
    // MARK: - Subviews
    
    /// 紧凑视图 - 仅图标
    private var compactView: some View {
        Image(systemName: icon)
            .font(iconSize)
            .foregroundStyle(color)
            .accessibilityLabel(accessibilityLabelText)
    }
    
    /// 完整视图 - 图标 + 标签
    private var fullView: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(iconSize)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }
    
    /// 进度条视图
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(percentageText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * confidence)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(percentageText)
    }
    
    /// 无障碍标签文本
    private var accessibilityLabelText: String {
        "\(label)，置信度\(percentageText)"
    }
}

// MARK: - ConfidenceRing (Circular Style)

/// 置信度圆环 - 圆形进度指示器
///
/// 适用于需要圆形显示的场景
public struct ConfidenceRing: View {
    
    let confidence: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    public init(
        confidence: Double,
        size: CGFloat = 40,
        lineWidth: CGFloat = 4
    ) {
        self.confidence = min(max(confidence, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
    }
    
    private var color: Color {
        ConfidenceColors.color(for: confidence)
    }
    
    public var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: confidence)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // 百分比文本
            Text("\(Int(confidence * 100))")
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("置信度\(Int(confidence * 100))%")
    }
}

// MARK: - Preview

#if DEBUG
struct ConfidenceIndicator_Previews: PreviewProvider {
    static let confidenceLevels: [Double] = [1.0, 0.85, 0.65, 0.4]
    
    static var previews: some View {
        VStack(spacing: 24) {
            // Compact Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Compact Style")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(confidenceLevels, id: \.self) { confidence in
                        ConfidenceIndicator(confidence: confidence, style: .compact)
                    }
                }
            }
            
            Divider()
            
            // Full Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Style")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(confidenceLevels, id: \.self) { confidence in
                        ConfidenceIndicator(confidence: confidence, style: .full)
                    }
                }
            }
            
            Divider()
            
            // Progress Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress Style")
                    .font(.headline)
                
                ForEach(confidenceLevels, id: \.self) { confidence in
                    ConfidenceIndicator(confidence: confidence, style: .progress)
                        .frame(width: 200)
                }
            }
            
            Divider()
            
            // Ring Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Ring Style")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(confidenceLevels, id: \.self) { confidence in
                        ConfidenceRing(confidence: confidence)
                    }
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
