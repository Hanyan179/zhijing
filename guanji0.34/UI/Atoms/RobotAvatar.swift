import SwiftUI

// MARK: - Robot Mood States
public enum RobotMood: String, CaseIterable {
    case idle = "IDLE"
    case processing = "PROCESSING"
    case happy = "HAPPY"
    case sleep = "SLEEP"
}

// MARK: - Robot Avatar Configuration
/// 机器人头像的完整配置参数
/// 所有视觉元素都可以动态调整
public struct RobotAvatarConfig {
    
    // MARK: - 主体颜色
    public var coreStartColor: Color
    public var coreEndColor: Color
    public var screenBgColor: Color
    public var strokeColor: Color
    
    // MARK: - 玻璃外壳
    public var glassColors: [Color]
    public var glassOpacities: [Double]
    
    // MARK: - 眼睛
    public var eyeColor: Color
    public var eyeWidth: CGFloat      // 相对于 size 的比例 (0-1)
    public var eyeHeight: CGFloat     // 相对于 size 的比例 (0-1)
    public var eyeSpacing: CGFloat    // 两眼间距比例
    public var eyeCornerRadius: CGFloat // 眼睛圆角比例
    
    // MARK: - 光效
    public var glowColor: Color
    public var glowIntensity: CGFloat // 0-1
    public var rimGlowEnabled: Bool
    
    // MARK: - 星球/卫星
    public var planetColor: Color
    public var planetRingColor: Color
    public var planetSize: CGFloat    // 相对于 size 的比例 (0-1)
    public var planetDistance: CGFloat // 距离中心的比例
    public var planetsVisible: Bool
    
    // MARK: - 动画参数
    public var floatAmplitude: CGFloat  // 浮动幅度
    public var floatDuration: Double    // 浮动周期（秒）
    public var blinkInterval: Double    // 眨眼间隔（秒）
    public var pulseIntensity: CGFloat  // 脉冲强度 (1.0 = 无脉冲)
    
    // MARK: - 阴影
    public var shadowOpacity: Double
    public var shadowBlur: CGFloat
    
    // MARK: - 默认配置（深色主题）
    public static let `default` = RobotAvatarConfig(
        // 主体：深邃蓝黑
        coreStartColor: Color(hex: "#151822"),
        coreEndColor: Color(hex: "#0a0c10"),
        screenBgColor: Color(hex: "#0c0e14"),
        strokeColor: Color(hex: "#2a3545"),
        // 玻璃：冷银色
        glassColors: [
            Color(hex: "#d8dce0"),
            Color(hex: "#909aa8"),
            Color(hex: "#506070"),
            Color(hex: "#304050")
        ],
        glassOpacities: [0.25, 0.18, 0.12, 0.15],
        // 眼睛：蓝色
        eyeColor: Color(hex: "#4A9EFF"),
        eyeWidth: 0.105,      // 42/400
        eyeHeight: 0.12,      // 48/400
        eyeSpacing: 0.095,    // 38/400
        eyeCornerRadius: 0.3,
        // 光效
        glowColor: Color(hex: "#4A9EFF"),
        glowIntensity: 1.0,
        rimGlowEnabled: true,
        // 星球
        planetColor: Color(hex: "#7888a0"),
        planetRingColor: Color(hex: "#5070a0"),
        planetSize: 0.07,     // 28/400
        planetDistance: 0.3375, // 135/400
        planetsVisible: true,
        // 动画
        floatAmplitude: 10,
        floatDuration: 3.0,
        blinkInterval: 4.0,
        pulseIntensity: 1.2,
        // 阴影
        shadowOpacity: 0.35,
        shadowBlur: 12
    )
    
    public init(
        coreStartColor: Color,
        coreEndColor: Color,
        screenBgColor: Color,
        strokeColor: Color,
        glassColors: [Color],
        glassOpacities: [Double],
        eyeColor: Color,
        eyeWidth: CGFloat,
        eyeHeight: CGFloat,
        eyeSpacing: CGFloat,
        eyeCornerRadius: CGFloat,
        glowColor: Color,
        glowIntensity: CGFloat,
        rimGlowEnabled: Bool,
        planetColor: Color,
        planetRingColor: Color,
        planetSize: CGFloat,
        planetDistance: CGFloat,
        planetsVisible: Bool,
        floatAmplitude: CGFloat,
        floatDuration: Double,
        blinkInterval: Double,
        pulseIntensity: CGFloat,
        shadowOpacity: Double,
        shadowBlur: CGFloat
    ) {
        self.coreStartColor = coreStartColor
        self.coreEndColor = coreEndColor
        self.screenBgColor = screenBgColor
        self.strokeColor = strokeColor
        self.glassColors = glassColors
        self.glassOpacities = glassOpacities
        self.eyeColor = eyeColor
        self.eyeWidth = eyeWidth
        self.eyeHeight = eyeHeight
        self.eyeSpacing = eyeSpacing
        self.eyeCornerRadius = eyeCornerRadius
        self.glowColor = glowColor
        self.glowIntensity = glowIntensity
        self.rimGlowEnabled = rimGlowEnabled
        self.planetColor = planetColor
        self.planetRingColor = planetRingColor
        self.planetSize = planetSize
        self.planetDistance = planetDistance
        self.planetsVisible = planetsVisible
        self.floatAmplitude = floatAmplitude
        self.floatDuration = floatDuration
        self.blinkInterval = blinkInterval
        self.pulseIntensity = pulseIntensity
        self.shadowOpacity = shadowOpacity
        self.shadowBlur = shadowBlur
    }
}

// MARK: - Robot Avatar
public struct RobotAvatar: View {
    let mood: RobotMood
    let size: CGFloat
    let config: RobotAvatarConfig
    
    @State private var isBlinking = false
    @State private var floatY: CGFloat = 0
    @State private var floatRot: Double = 0
    @State private var satY: CGFloat = 0
    @State private var procH: [CGFloat] = [20, 20, 20, 20]
    @State private var zzzY: CGFloat = 0
    @State private var zzzOp: Double = 0
    @State private var pulse: Double = 1.0
    
    private var s: CGFloat { size / 400 }
    
    public init(mood: RobotMood = .idle, size: CGFloat = 200, config: RobotAvatarConfig = .default) {
        self.mood = mood
        self.size = size
        self.config = config
    }
    
    public var body: some View {
        ZStack {
            // 环境光晕
            ambientGlow
            
            // 地面阴影
            groundShadow
            
            // 星球
            if config.planetsVisible {
                satellites
            }
            
            // 主体
            mainBody
        }
        .frame(width: size, height: size)
        .offset(y: floatY)
        .rotationEffect(.degrees(floatRot))
        .onAppear { startAnim() }
        .onChange(of: mood) { _ in startAnim() }
    }
    
    // MARK: - Ambient Glow
    private var ambientGlow: some View {
        ZStack {
            Ellipse()
                .fill(config.glowColor.opacity(0.08 * pulse * config.glowIntensity))
                .frame(width: 280 * s, height: 200 * s)
                .blur(radius: 40 * s)
            
            Ellipse()
                .fill(config.glowColor.opacity(0.04 * pulse * config.glowIntensity))
                .frame(width: 350 * s, height: 250 * s)
                .blur(radius: 60 * s)
        }
        .offset(y: 20 * s)
    }
    
    // MARK: - Ground Shadow
    private var groundShadow: some View {
        Ellipse()
            .fill(Color.black.opacity(config.shadowOpacity))
            .frame(width: 100 * s, height: 16 * s)
            .blur(radius: config.shadowBlur * s)
            .offset(y: 175 * s)
    }
    
    // MARK: - Satellites
    private var satellites: some View {
        let dist = config.planetDistance * size
        return ZStack {
            satellite(rot: -20).offset(x: -dist, y: satY)
            satellite(rot: 20).offset(x: dist, y: -satY)
        }
    }
    
    private func satellite(rot: Double) -> some View {
        let r = config.planetSize * size
        return ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [config.planetColor.opacity(0.9), config.planetColor.opacity(0.5)],
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 0, endRadius: r
                ))
                .frame(width: r * 2, height: r * 2)
            
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: r * 2, height: r * 2)
            
            Ellipse()
                .stroke(LinearGradient(
                    colors: [config.planetRingColor.opacity(0), config.planetRingColor.opacity(0.5), config.planetRingColor.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                ), lineWidth: 2 * s)
                .frame(width: r * 3, height: r * 0.7)
                .rotationEffect(.degrees(rot))
        }
    }

    // MARK: - Main Body
    private var mainBody: some View {
        ZStack {
            // 1. 内核
            BodyPath(s: s, outer: false)
                .fill(RadialGradient(
                    colors: [config.coreStartColor, config.coreEndColor],
                    center: .center, startRadius: 0, endRadius: 150 * s
                ))
            
            // 2. 内阴影
            BodyPath(s: s, outer: false)
                .stroke(Color.black.opacity(0.5), lineWidth: 6 * s)
                .blur(radius: 4 * s)
                .clipShape(BodyPath(s: s, outer: false))
            
            // 3. 屏幕
            screen
            
            // 4. 眼睛
            eyes.offset(y: -5 * s)
            
            // 5. 玻璃外壳
            glass
            
            // 6. 折射线
            RefractPath(s: s)
                .stroke(Color.white.opacity(0.06), lineWidth: 1.5 * s)
            
            // 7. 高光
            highlights
            
            // 8. 底部光晕
            if config.rimGlowEnabled {
                rimGlow
            }
        }
    }
    
    // MARK: - Screen
    private var screen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22 * s)
                .fill(config.screenBgColor)
                .frame(width: 165 * s, height: 105 * s)
            
            RoundedRectangle(cornerRadius: 22 * s)
                .stroke(config.strokeColor.opacity(0.4), lineWidth: 1)
                .frame(width: 165 * s, height: 105 * s)
        }
        .offset(y: -5 * s)
    }
    
    // MARK: - Glass
    private var glass: some View {
        let stops = zip(config.glassColors, config.glassOpacities).enumerated().map { i, pair in
            Gradient.Stop(color: pair.0.opacity(pair.1), location: CGFloat(i) / CGFloat(max(1, config.glassColors.count - 1)))
        }
        
        return ZStack {
            BodyPath(s: s, outer: true)
                .fill(LinearGradient(stops: stops, startPoint: .topLeading, endPoint: .bottomTrailing))
            
            BodyPath(s: s, outer: true)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
        }
    }
    
    // MARK: - Highlights
    private var highlights: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.35), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 120 * s, height: 40 * s)
                .blur(radius: 2 * s)
                .offset(y: -82 * s)
            
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 60 * s, height: 6 * s)
                .blur(radius: 1.5 * s)
                .offset(x: -25 * s, y: -68 * s)
                .rotationEffect(.degrees(-12))
        }
    }
    
    // MARK: - Rim Glow
    private var rimGlow: some View {
        ZStack {
            Capsule()
                .fill(config.glowColor.opacity(0.35 * pulse * config.glowIntensity))
                .frame(width: 140 * s, height: 4 * s)
                .blur(radius: 8 * s)
            
            Capsule()
                .fill(config.glowColor.opacity(0.15 * pulse * config.glowIntensity))
                .frame(width: 180 * s, height: 10 * s)
                .blur(radius: 16 * s)
        }
        .offset(y: 108 * s)
    }
    
    // MARK: - Eyes
    @ViewBuilder
    private var eyes: some View {
        switch mood {
        case .idle: idleEyes
        case .happy: happyEyes
        case .sleep: sleepEyes
        case .processing: procEyes
        }
    }
    
    private var idleEyes: some View {
        let w = config.eyeWidth * size
        let h = isBlinking ? 4 * s : config.eyeHeight * size
        let spacing = config.eyeSpacing * size
        let y: CGFloat = isBlinking ? config.eyeHeight * size / 2 : 0
        
        return HStack(spacing: spacing) {
            eye(w: w, h: h).offset(y: y)
            eye(w: w, h: h).offset(y: y)
        }
        .animation(.easeInOut(duration: 0.1), value: isBlinking)
    }
    
    private var happyEyes: some View {
        let w = config.eyeWidth * size
        let spacing = config.eyeSpacing * size
        
        return HStack(spacing: spacing) {
            happyEye(blink: isBlinking, width: w)
            happyEye(blink: isBlinking, width: w)
        }
    }
    
    private var sleepEyes: some View {
        let w = config.eyeWidth * size * 1.15
        let spacing = config.eyeSpacing * size * 0.75
        
        return ZStack {
            HStack(spacing: spacing) {
                eye(w: w, h: 4 * s)
                eye(w: w, h: 4 * s)
            }
            Text("Z")
                .font(.system(size: 16 * s, weight: .bold, design: .rounded))
                .foregroundColor(config.eyeColor)
                .modifier(Glow(c: config.eyeColor, s: s, intensity: config.glowIntensity))
                .offset(x: 60 * s, y: -32 * s + zzzY)
                .opacity(zzzOp)
        }
    }
    
    private var procEyes: some View {
        HStack(spacing: 18 * s) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6 * s)
                    .fill(config.eyeColor)
                    .frame(width: 14 * s, height: procH[i])
                    .modifier(Glow(c: config.eyeColor, s: s, intensity: config.glowIntensity))
            }
        }
    }
    
    private func eye(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: min(w, h) * config.eyeCornerRadius)
            .fill(config.eyeColor)
            .frame(width: w, height: h)
            .modifier(Glow(c: config.eyeColor, s: s, intensity: config.glowIntensity))
    }
    
    private func happyEye(blink: Bool, width: CGFloat) -> some View {
        Group {
            if blink {
                Capsule()
                    .fill(config.eyeColor)
                    .frame(width: width, height: 4 * s)
                    .modifier(Glow(c: config.eyeColor, s: s, intensity: config.glowIntensity))
            } else {
                ArcShape()
                    .stroke(config.eyeColor, style: StrokeStyle(lineWidth: 7 * s, lineCap: .round))
                    .frame(width: width, height: width * 0.52)
                    .modifier(Glow(c: config.eyeColor, s: s, intensity: config.glowIntensity))
            }
        }
        .animation(.easeInOut(duration: 0.1), value: blink)
    }
    
    // MARK: - Animations
    private func startAnim() {
        let amt: CGFloat = mood == .sleep ? config.floatAmplitude * 0.5 : config.floatAmplitude
        
        withAnimation(.easeInOut(duration: config.floatDuration).repeatForever(autoreverses: true)) {
            floatY = -amt * s
        }
        withAnimation(.easeInOut(duration: config.floatDuration * 2).repeatForever(autoreverses: true)) {
            floatRot = 0.8
        }
        withAnimation(.easeInOut(duration: config.floatDuration * 0.83).repeatForever(autoreverses: true).delay(0.3)) {
            satY = 4 * s
        }
        withAnimation(.easeInOut(duration: config.floatDuration * 0.83).repeatForever(autoreverses: true)) {
            pulse = config.pulseIntensity
        }
        
        if mood == .idle || mood == .happy {
            Timer.scheduledTimer(withTimeInterval: config.blinkInterval, repeats: true) { t in
                guard mood == .idle || mood == .happy else { t.invalidate(); return }
                isBlinking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isBlinking = false }
            }
        }
        
        if mood == .processing {
            for i in 0..<4 {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.12)) {
                    procH[i] = 45 * s
                }
            }
        }
        
        if mood == .sleep {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) { zzzY = -12 * s }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { zzzOp = 1 }
        }
    }
}

// MARK: - Glow Modifier
private struct Glow: ViewModifier {
    let c: Color
    let s: CGFloat
    let intensity: CGFloat
    
    init(c: Color, s: CGFloat, intensity: CGFloat = 1.0) {
        self.c = c
        self.s = s
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: c.opacity(0.85 * intensity), radius: 3 * s)
            .shadow(color: c.opacity(0.5 * intensity), radius: 6 * s)
            .shadow(color: c.opacity(0.25 * intensity), radius: 12 * s)
    }
}

// MARK: - Body Path
private struct BodyPath: Shape {
    let s: CGFloat
    let outer: Bool
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let o: CGFloat = outer ? 5 : 0
        
        let p1 = CGPoint(x: cx - (100 + o) * s, y: cy - 70 * s)
        let c1 = CGPoint(x: cx - (100 + o) * s, y: cy - (100 + o) * s)
        let p2 = CGPoint(x: cx, y: cy - (100 + o) * s)
        let c2 = CGPoint(x: cx + (100 + o) * s, y: cy - (100 + o) * s)
        let p3 = CGPoint(x: cx + (100 + o) * s, y: cy - 70 * s)
        let p4 = CGPoint(x: cx + (120 + o) * s, y: cy + 50 * s)
        let c3 = CGPoint(x: cx + (130 + o) * s, y: cy + (120 + o) * s)
        let p5 = CGPoint(x: cx, y: cy + (120 + o) * s)
        let c4 = CGPoint(x: cx - (130 + o) * s, y: cy + (120 + o) * s)
        let p6 = CGPoint(x: cx - (120 + o) * s, y: cy + 50 * s)
        
        p.move(to: p1)
        p.addQuadCurve(to: p2, control: c1)
        p.addQuadCurve(to: p3, control: c2)
        p.addLine(to: p4)
        p.addQuadCurve(to: p5, control: c3)
        p.addQuadCurve(to: p6, control: c4)
        p.closeSubpath()
        return p
    }
}

// MARK: - Refract Path
private struct RefractPath: Shape {
    let s: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        
        p.move(to: CGPoint(x: cx - 82 * s, y: cy - 58 * s))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy - 78 * s), control: CGPoint(x: cx - 82 * s, y: cy - 78 * s))
        p.addQuadCurve(to: CGPoint(x: cx + 82 * s, y: cy - 58 * s), control: CGPoint(x: cx + 82 * s, y: cy - 78 * s))
        p.addLine(to: CGPoint(x: cx + 92 * s, y: cy + 38 * s))
        p.addQuadCurve(to: CGPoint(x: cx, y: cy + 88 * s), control: CGPoint(x: cx + 98 * s, y: cy + 88 * s))
        p.addQuadCurve(to: CGPoint(x: cx - 92 * s, y: cy + 38 * s), control: CGPoint(x: cx - 98 * s, y: cy + 88 * s))
        p.closeSubpath()
        return p
    }
}

// MARK: - Arc Shape
private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height), control: CGPoint(x: rect.midX, y: 0))
        return p
    }
}

// MARK: - Color Hex
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
#Preview("Default Config") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            HStack(spacing: 30) {
                VStack { RobotAvatar(mood: .idle, size: 150); Text("Idle").foregroundColor(.gray).font(.caption) }
                VStack { RobotAvatar(mood: .happy, size: 150); Text("Happy").foregroundColor(.gray).font(.caption) }
            }
            HStack(spacing: 30) {
                VStack { RobotAvatar(mood: .sleep, size: 150); Text("Sleep").foregroundColor(.gray).font(.caption) }
                VStack { RobotAvatar(mood: .processing, size: 150); Text("Processing").foregroundColor(.gray).font(.caption) }
            }
        }
    }
}

#Preview("Custom Config - Big Eyes") {
    var config = RobotAvatarConfig.default
    config.eyeWidth = 0.15
    config.eyeHeight = 0.18
    config.eyeColor = Color(hex: "#00FF88")
    config.glowColor = Color(hex: "#00FF88")
    
    return ZStack {
        Color.black.ignoresSafeArea()
        RobotAvatar(mood: .idle, size: 200, config: config)
    }
}

#Preview("Custom Config - No Planets") {
    var config = RobotAvatarConfig.default
    config.planetsVisible = false
    config.rimGlowEnabled = false
    config.glowIntensity = 0.5
    
    return ZStack {
        Color.black.ignoresSafeArea()
        RobotAvatar(mood: .idle, size: 200, config: config)
    }
}
