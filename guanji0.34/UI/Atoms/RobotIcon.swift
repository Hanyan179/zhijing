import SwiftUI

// MARK: - Robot Icon
/// 简化版静态机器人图标 - 用于按钮、菜单等小尺寸场景
/// 只保留核心形状（头部轮廓 + 眼睛），无动画，性能优化
///
/// 参数:
/// - size: 图标尺寸（默认 24）
/// - eyeStyle: 眼睛样式（默认 .round）
/// - theme: 主题（默认跟随系统）
public struct RobotIcon: View {
    let size: CGFloat
    let eyeStyle: EyeStyle
    let theme: IconTheme
    
    private var s: CGFloat { size / 24 }
    
    public enum EyeStyle {
        case round      // 圆形眼（愉快）
        case happy      // 咪咪眼（幸福）
        case star       // 星星眼（兴奋）
        case check      // 勾选眼（完成）
    }
    
    public enum IconTheme {
        case light
        case dark
        case auto
        
        fileprivate func colors(for colorScheme: ColorScheme) -> IconColors {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .auto: return colorScheme == .dark ? .dark : .light
            }
        }
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: IconColors {
        theme.colors(for: colorScheme)
    }
    
    public init(
        size: CGFloat = 24,
        eyeStyle: EyeStyle = .round,
        theme: IconTheme = .auto
    ) {
        self.size = size
        self.eyeStyle = eyeStyle
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            // 主体轮廓
            RobotBodyShape(s: s)
                .fill(colors.bodyGradient)
            
            // 玻璃层
            RobotBodyShape(s: s)
                .fill(colors.glassGradient)
            
            // 屏幕
            RoundedRectangle(cornerRadius: 3 * s)
                .fill(colors.screenColor)
                .frame(width: 14 * s, height: 9 * s)
                .offset(y: -0.5 * s)
            
            // 眼睛
            eyes
                .offset(y: -0.5 * s)
            
            // 高光
            Capsule()
                .fill(LinearGradient(
                    colors: [colors.highlightColor, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 10 * s, height: 2 * s)
                .offset(y: -8 * s)
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Eyes
    
    @ViewBuilder
    private var eyes: some View {
        switch eyeStyle {
        case .round:
            HStack(spacing: 4 * s) {
                Circle()
                    .fill(colors.eyeColor)
                    .frame(width: 3.5 * s, height: 3.5 * s)
                Circle()
                    .fill(colors.eyeColor)
                    .frame(width: 3.5 * s, height: 3.5 * s)
            }
            
        case .happy:
            HStack(spacing: 4 * s) {
                HappyEye(s: s, color: colors.eyeColor)
                HappyEye(s: s, color: colors.eyeColor)
            }
            
        case .star:
            HStack(spacing: 4 * s) {
                StarEye(s: s, color: colors.eyeColor)
                StarEye(s: s, color: colors.eyeColor)
            }
            
        case .check:
            Image(systemName: "checkmark")
                .font(.system(size: 6 * s, weight: .bold))
                .foregroundColor(colors.checkColor)
        }
    }
}

// MARK: - Body Shape

private struct RobotBodyShape: Shape {
    let s: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        
        // 简化的机器人头部形状
        let w: CGFloat = 10 * s
        let h: CGFloat = 10 * s
        let r: CGFloat = 3 * s
        
        p.move(to: CGPoint(x: cx - w, y: cy - h + r))
        p.addQuadCurve(
            to: CGPoint(x: cx - w + r, y: cy - h),
            control: CGPoint(x: cx - w, y: cy - h)
        )
        p.addLine(to: CGPoint(x: cx + w - r, y: cy - h))
        p.addQuadCurve(
            to: CGPoint(x: cx + w, y: cy - h + r),
            control: CGPoint(x: cx + w, y: cy - h)
        )
        p.addLine(to: CGPoint(x: cx + w + 1.5 * s, y: cy + h - r))
        p.addQuadCurve(
            to: CGPoint(x: cx + w - r + 1.5 * s, y: cy + h + 2 * s),
            control: CGPoint(x: cx + w + 2 * s, y: cy + h + 2 * s)
        )
        p.addLine(to: CGPoint(x: cx - w + r - 1.5 * s, y: cy + h + 2 * s))
        p.addQuadCurve(
            to: CGPoint(x: cx - w - 1.5 * s, y: cy + h - r),
            control: CGPoint(x: cx - w - 2 * s, y: cy + h + 2 * s)
        )
        p.closeSubpath()
        
        return p
    }
}

// MARK: - Eye Shapes

private struct HappyEye: View {
    let s: CGFloat
    let color: Color
    
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 2 * s))
            p.addQuadCurve(
                to: CGPoint(x: 4 * s, y: 2 * s),
                control: CGPoint(x: 2 * s, y: 0)
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
        .frame(width: 4 * s, height: 3 * s)
    }
}

private struct StarEye: View {
    let s: CGFloat
    let color: Color
    
    var body: some View {
        StarShape()
            .fill(color)
            .frame(width: 4 * s, height: 4 * s)
    }
}

private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        
        var path = Path()
        
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Colors

private struct IconColors {
    let bodyGradient: LinearGradient
    let glassGradient: LinearGradient
    let screenColor: Color
    let eyeColor: Color
    let checkColor: Color
    let highlightColor: Color
    
    static let light = IconColors(
        bodyGradient: LinearGradient(
            colors: [Color(hex: "#f8f9fc"), Color(hex: "#e8eaf0")],
            startPoint: .top,
            endPoint: .bottom
        ),
        glassGradient: LinearGradient(
            colors: [Color.white.opacity(0.9), Color(hex: "#e0e4ec").opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        screenColor: Color(hex: "#d8dae0"),
        eyeColor: Color(hex: "#0066CC"),
        checkColor: Color(hex: "#34C759"),
        highlightColor: Color.white.opacity(0.95)
    )
    
    static let dark = IconColors(
        bodyGradient: LinearGradient(
            colors: [Color(hex: "#252830"), Color(hex: "#151820")],
            startPoint: .top,
            endPoint: .bottom
        ),
        glassGradient: LinearGradient(
            colors: [Color.white.opacity(0.2), Color(hex: "#607080").opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        screenColor: Color(hex: "#0c0e14"),
        eyeColor: Color(hex: "#4A9EFF"),
        checkColor: Color(hex: "#34C759"),
        highlightColor: Color.white.opacity(0.3)
    )
}

// MARK: - Color Hex Extension

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: h).scanHexInt64(&i)
        let a, r, g, b: UInt64
        switch h.count {
        case 3: (a, r, g, b) = (255, (i >> 8) * 17, (i >> 4 & 0xF) * 17, (i & 0xF) * 17)
        case 6: (a, r, g, b) = (255, i >> 16, i >> 8 & 0xFF, i & 0xFF)
        case 8: (a, r, g, b) = (i >> 24, i >> 16 & 0xFF, i >> 8 & 0xFF, i & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Robot Icons") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForEach([RobotIcon.EyeStyle.round, .happy, .star, .check], id: \.self) { style in
                VStack {
                    RobotIcon(size: 32, eyeStyle: style, theme: .light)
                    Text(String(describing: style))
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color.white)
        
        HStack(spacing: 20) {
            ForEach([RobotIcon.EyeStyle.round, .happy, .star, .check], id: \.self) { style in
                VStack {
                    RobotIcon(size: 32, eyeStyle: style, theme: .dark)
                    Text(String(describing: style))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.black)
        
        // Size variations
        HStack(spacing: 16) {
            RobotIcon(size: 16)
            RobotIcon(size: 24)
            RobotIcon(size: 32)
            RobotIcon(size: 48)
        }
    }
    .padding()
}
#endif
