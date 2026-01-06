import SwiftUI

// MARK: - ConfidenceBadge
// Task 10.3: 置信度标签组件
// 0.9~1.0: 无标签（正常显示）
// 0.7~0.9: "AI 推测" 蓝色标签
// 0.5~0.7: "待确认" 黄色标签
// < 0.5: "低置信度" 灰色标签

/// Confidence badge component for displaying confidence level
public struct ConfidenceBadge: View {
    
    // MARK: - Confidence Level
    
    public enum Level {
        case high       // 0.9~1.0: 无标签
        case aiGuess    // 0.7~0.9: AI 推测
        case needsConfirm // 0.5~0.7: 待确认
        case low        // < 0.5: 低置信度
        
        init(confidence: Double) {
            switch confidence {
            case 0.9...1.0: self = .high
            case 0.7..<0.9: self = .aiGuess
            case 0.5..<0.7: self = .needsConfirm
            default: self = .low
            }
        }
        
        var label: String? {
            switch self {
            case .high: return nil
            case .aiGuess: return "AI 推测"
            case .needsConfirm: return "待确认"
            case .low: return "低置信度"
            }
        }
        
        var color: Color {
            switch self {
            case .high: return Colors.green
            case .aiGuess: return Colors.blue
            case .needsConfirm: return Colors.amber
            case .low: return Colors.systemGray
            }
        }
        
        var icon: String? {
            switch self {
            case .high: return nil
            case .aiGuess: return "sparkles"
            case .needsConfirm: return "questionmark.circle"
            case .low: return "exclamationmark.triangle"
            }
        }
    }
    
    // MARK: - Properties
    
    let confidence: Double
    let showPercentage: Bool
    let compact: Bool
    
    private var level: Level {
        Level(confidence: confidence)
    }
    
    // MARK: - Initialization
    
    public init(
        confidence: Double,
        showPercentage: Bool = false,
        compact: Bool = false
    ) {
        self.confidence = confidence
        self.showPercentage = showPercentage
        self.compact = compact
    }
    
    // MARK: - Body
    
    public var body: some View {
        // High confidence: no badge shown
        if level == .high {
            if showPercentage {
                percentageOnlyView
            } else {
                EmptyView()
            }
        } else {
            badgeView
        }
    }
    
    // MARK: - Badge View
    
    @ViewBuilder
    private var badgeView: some View {
        if compact {
            compactBadge
        } else {
            fullBadge
        }
    }
    
    private var fullBadge: some View {
        HStack(spacing: 4) {
            if let icon = level.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            
            if let label = level.label {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            if showPercentage {
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
    }
    
    private var compactBadge: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(level.color)
                .frame(width: 6, height: 6)
            
            if showPercentage {
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(level.color)
            }
        }
    }
    
    private var percentageOnlyView: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

// MARK: - ConfidenceBadge Modifiers

extension ConfidenceBadge {
    
    /// Show percentage value
    public func withPercentage() -> ConfidenceBadge {
        ConfidenceBadge(
            confidence: confidence,
            showPercentage: true,
            compact: compact
        )
    }
    
    /// Use compact style
    public func compactStyle() -> ConfidenceBadge {
        ConfidenceBadge(
            confidence: confidence,
            showPercentage: showPercentage,
            compact: true
        )
    }
}

// MARK: - Preview

#Preview("Confidence Levels") {
    VStack(alignment: .leading, spacing: 16) {
        Group {
            HStack {
                Text("0.95 (高置信)")
                Spacer()
                ConfidenceBadge(confidence: 0.95)
            }
            
            HStack {
                Text("0.95 (显示百分比)")
                Spacer()
                ConfidenceBadge(confidence: 0.95, showPercentage: true)
            }
            
            HStack {
                Text("0.85 (AI 推测)")
                Spacer()
                ConfidenceBadge(confidence: 0.85)
            }
            
            HStack {
                Text("0.85 (显示百分比)")
                Spacer()
                ConfidenceBadge(confidence: 0.85, showPercentage: true)
            }
            
            HStack {
                Text("0.65 (待确认)")
                Spacer()
                ConfidenceBadge(confidence: 0.65)
            }
            
            HStack {
                Text("0.65 (显示百分比)")
                Spacer()
                ConfidenceBadge(confidence: 0.65, showPercentage: true)
            }
            
            HStack {
                Text("0.35 (低置信度)")
                Spacer()
                ConfidenceBadge(confidence: 0.35)
            }
            
            HStack {
                Text("0.35 (显示百分比)")
                Spacer()
                ConfidenceBadge(confidence: 0.35, showPercentage: true)
            }
        }
    }
    .padding()
}

#Preview("Compact Style") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("AI 推测 (紧凑)")
            Spacer()
            ConfidenceBadge(confidence: 0.85, compact: true)
        }
        
        HStack {
            Text("待确认 (紧凑+百分比)")
            Spacer()
            ConfidenceBadge(confidence: 0.65, showPercentage: true, compact: true)
        }
        
        HStack {
            Text("低置信度 (紧凑)")
            Spacer()
            ConfidenceBadge(confidence: 0.35, compact: true)
        }
    }
    .padding()
}
