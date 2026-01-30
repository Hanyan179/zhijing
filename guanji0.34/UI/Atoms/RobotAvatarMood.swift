import SwiftUI

// MARK: - Robot Avatar Mood
/// 心情版机器人头像 - 根据心情天气和身体能量动态变化
/// 对应 React 版本的 RobotAvatarMood.tsx
///
/// 参数:
/// - mindValence: 心情天气 (0-100)，控制眼睛样式
/// - bodyEnergy: 身体能量 (0-100)，控制动画幅度和发光强度
/// - theme: 主题 (purple/dark/light)
/// - modelTier: AI 模式下的模型档位（可选），控制卫星球颜色
/// - thinkingMode: AI 模式下是否开启思考模式（可选），显示头顶灯泡
public struct RobotAvatarMood: View {
    let mindValence: Int      // 0-100
    let bodyEnergy: Int       // 0-100
    let theme: RobotMoodTheme
    let size: CGFloat
    
    // AI 模式可选参数
    let modelTier: ModelTier?
    let thinkingMode: Bool
    
    @State private var isBlinking = false
    @State private var floatY: CGFloat = 0
    @State private var floatRot: Double = 0
    @State private var satY: CGFloat = 0
    @State private var pulse: Double = 1.0
    @State private var starRotation: Double = 0
    @State private var thinkingPulse: Double = 1.0
    
    private var s: CGFloat { size / 400 }
    
    // 能量归一化 (0-1)
    private var energyNormalized: CGFloat { CGFloat(bodyEnergy) / 100.0 }
    
    // 动画参数根据能量变化
    private var floatAmplitude: CGFloat { 5 + energyNormalized * 20 }  // 5-25
    private var floatDuration: Double { 8 - Double(energyNormalized) * 4 }  // 8s-4s
    private var glowIntensity: CGFloat { 0.3 + energyNormalized * 0.7 }  // 0.3-1.0
    private var planetScale: CGFloat { 0.7 + energyNormalized * 0.5 }  // 0.7-1.2
    
    // 心情等级 (0-6)
    private var moodLevel: Int { min(6, Int(Double(mindValence) / 14.3)) }
    // 等级内微调值 (0-1)
    private var moodMicro: CGFloat { CGFloat(mindValence % 14) / 14.0 }
    
    // 眨眼间隔根据能量变化
    private var blinkInterval: Double { 6.0 - Double(energyNormalized) * 3.0 }  // 6s-3s
    
    private var colors: RobotMoodColors { theme.colors }
    
    // AI 模式卫星球颜色
    private var satelliteColors: (primary: Color, secondary: Color, ring: Color) {
        guard let tier = modelTier else {
            return (colors.planet[0], colors.planet[1], colors.planetRing)
        }
        switch tier {
        case .fast:
            // 绿色 - 快速
            return (Color(hex: "#4ADE80"), Color(hex: "#22C55E"), Color(hex: "#86EFAC"))
        case .balanced:
            // 蓝色 - 均衡
            return (Color(hex: "#60A5FA"), Color(hex: "#3B82F6"), Color(hex: "#93C5FD"))
        case .powerful:
            // 金色 - 强力
            return (Color(hex: "#FCD34D"), Color(hex: "#F59E0B"), Color(hex: "#FDE68A"))
        }
    }
    
    public init(
        mindValence: Int = 50,
        bodyEnergy: Int = 50,
        theme: RobotMoodTheme = .dark,
        size: CGFloat = 200,
        modelTier: ModelTier? = nil,
        thinkingMode: Bool = false
    ) {
        self.mindValence = max(0, min(100, mindValence))
        self.bodyEnergy = max(0, min(100, bodyEnergy))
        self.theme = theme
        self.size = size
        self.modelTier = modelTier
        self.thinkingMode = thinkingMode
    }
    
    public var body: some View {
        ZStack {
            // 地面阴影
            groundShadow
            
            // 星球（AI 模式下颜色变化）
            satellites
            
            // 能量圆环
            energyRings
            
            // 主体
            mainBody
            
            // 思考灯（AI 模式下显示）
            if thinkingMode {
                thinkingBulb
            }
        }
        .frame(width: size, height: size)
        .offset(y: floatY)
        .rotationEffect(.degrees(floatRot))
        .onAppear { startAnimations() }
        .onChange(of: mindValence) { _ in restartBlinkTimer() }
        .onChange(of: bodyEnergy) { _ in restartBlinkTimer() }
    }
    
    // MARK: - Ground Shadow
    private var groundShadow: some View {
        Ellipse()
            .fill(Color.black.opacity(0.2 + Double(energyNormalized) * 0.2))
            .frame(width: 120 * s, height: 20 * s)
            .blur(radius: 8 * s)
            .offset(y: 180 * s)
    }
    
    // MARK: - Satellites
    private var satellites: some View {
        let dist: CGFloat = 140 * s
        return ZStack {
            satellite(rot: -20)
                .offset(x: -dist, y: satY)
                .scaleEffect(planetScale)
            satellite(rot: 20)
                .offset(x: dist, y: -satY)
                .scaleEffect(planetScale)
        }
    }
    
    private func satellite(rot: Double) -> some View {
        let r: CGFloat = 16 * s
        let satColors = satelliteColors
        return ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [satColors.primary.opacity(glowIntensity), satColors.secondary.opacity(glowIntensity)],
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 0, endRadius: r
                ))
                .frame(width: r * 2, height: r * 2)
            
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.4), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: r * 2, height: r * 2)
            
            Ellipse()
                .stroke(LinearGradient(
                    colors: [satColors.ring.opacity(0), satColors.ring.opacity(0.8 * glowIntensity), satColors.ring.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                ), lineWidth: 2 * s * glowIntensity)
                .frame(width: r * 3, height: r * 0.7)
                .rotationEffect(.degrees(rot))
            
            // AI 模式下添加发光效果
            if modelTier != nil {
                Circle()
                    .fill(satColors.primary.opacity(0.3))
                    .frame(width: r * 2.5, height: r * 2.5)
                    .blur(radius: 4 * s)
            }
        }
    }
    
    // MARK: - Thinking Bulb
    private var thinkingBulb: some View {
        let bulbSize: CGFloat = 14 * s
        // 使用与卫星球相同的颜色风格
        let bulbColor = satelliteColors.primary
        let bulbSecondary = satelliteColors.secondary
        
        return ZStack {
            // 发光光晕 - 更柔和
            Circle()
                .fill(bulbColor.opacity(0.25 * thinkingPulse))
                .frame(width: bulbSize * 3, height: bulbSize * 3)
                .blur(radius: 6 * s)
            
            // 灯泡主体 - 玻璃质感
            Circle()
                .fill(RadialGradient(
                    colors: [bulbColor.opacity(0.9), bulbSecondary.opacity(0.7)],
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 0,
                    endRadius: bulbSize
                ))
                .frame(width: bulbSize * 2, height: bulbSize * 2)
            
            // 高光
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.5), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: bulbSize * 2, height: bulbSize * 2)
            
            // 小光环
            Circle()
                .stroke(bulbColor.opacity(0.4 * glowIntensity), lineWidth: 1.5 * s)
                .frame(width: bulbSize * 2.8, height: bulbSize * 2.8)
        }
        .offset(y: -125 * s) // 头顶位置
        .scaleEffect(0.9 + 0.1 * thinkingPulse)
    }
    
    // MARK: - Energy Rings
    private var energyRings: some View {
        ZStack {
            // 第一环 - 能量 > 15
            if bodyEnergy > 15 {
                Circle()
                    .stroke(colors.rings[0].opacity(colors.ringsOpacity[0]), lineWidth: (theme == .dark ? 2.5 : 2) * s)
                    .frame(width: 290 * s, height: 290 * s)
                    .offset(y: 10 * s)
            }
            
            // 第二环 - 能量 > 45
            if bodyEnergy > 45 {
                Circle()
                    .stroke(colors.rings[1].opacity(colors.ringsOpacity[1]), lineWidth: (theme == .dark ? 2 : 1.5) * s)
                    .frame(width: 330 * s, height: 330 * s)
                    .offset(y: 10 * s)
            }
            
            // 第三环 - 能量 > 75，带发光
            if bodyEnergy > 75 {
                Circle()
                    .stroke(colors.rings[2].opacity(colors.ringsOpacity[2] * pulse), lineWidth: (theme == .dark ? 1.5 : 1) * s)
                    .frame(width: 370 * s, height: 370 * s)
                    .blur(radius: 2 * s)
                    .offset(y: 10 * s)
            }
        }
    }

    
    // MARK: - Main Body
    private var mainBody: some View {
        ZStack {
            // 1. 内核
            BodyPath(s: s, outer: false)
                .fill(RadialGradient(
                    colors: colors.bodyCore,
                    center: .center, startRadius: 0, endRadius: 150 * s
                ))
            
            // 2. 屏幕
            screen
            
            // 3. 眼睛
            eyes.offset(y: -5 * s)
            
            // 4. 玻璃外壳
            glass
            
            // 5. 折射线
            RefractPath(s: s)
                .stroke(Color.white.opacity(0.06 * glowIntensity), lineWidth: 1.5 * s)
            
            // 6. 高光
            highlights
            
            // 7. 底部光晕
            rimGlow
        }
    }
    
    // MARK: - Screen
    private var screen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24 * s)
                .fill(colors.screenBg)
                .frame(width: 170 * s, height: 110 * s)
            
            RoundedRectangle(cornerRadius: 24 * s)
                .stroke(colors.stroke.opacity(0.5), lineWidth: theme == .light ? 1.5 : 1)
                .frame(width: 170 * s, height: 110 * s)
            
            // Light 主题内阴影
            if theme == .light {
                RoundedRectangle(cornerRadius: 22 * s)
                    .stroke(Color(hex: "#c0c0c8").opacity(0.4), lineWidth: 3 * s)
                    .blur(radius: 2 * s)
                    .frame(width: 164 * s, height: 104 * s)
            }
        }
        .offset(y: -5 * s)
    }
    
    // MARK: - Glass
    private var glass: some View {
        let stops = zip(colors.glassShell, colors.glassOpacity).enumerated().map { i, pair in
            Gradient.Stop(
                color: pair.0.opacity(pair.1 * glowIntensity),
                location: CGFloat(i) / CGFloat(max(1, colors.glassShell.count - 1))
            )
        }
        
        return ZStack {
            BodyPath(s: s, outer: true)
                .fill(LinearGradient(stops: stops, startPoint: .topLeading, endPoint: .bottomTrailing))
            
            BodyPath(s: s, outer: true)
                .stroke(
                    theme == .light ? Color(hex: "#c8c8d0").opacity(0.6) : Color.white.opacity(0.2 * glowIntensity),
                    lineWidth: theme == .light ? 1.5 : 1
                )
        }
    }
    
    // MARK: - Highlights
    private var highlights: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(
                    colors: [colors.highlight.opacity(colors.highlightOpacity * glowIntensity), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 120 * s, height: 40 * s)
                .blur(radius: 2 * s)
                .offset(y: -82 * s)
            
            // Light 主题额外高光
            if theme == .light {
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 120 * s, height: 3 * s)
                    .offset(y: -95 * s)
            }
        }
    }
    
    // MARK: - Rim Glow
    private var rimGlow: some View {
        ZStack {
            Capsule()
                .fill(colors.rimLight.opacity(0.3 + glowIntensity * 0.5))
                .frame(width: 160 * s, height: (2 + glowIntensity * 3) * s)
                .blur(radius: 8 * s)
            
            if bodyEnergy >= 20 {
                Capsule()
                    .fill(colors.rimLight.opacity(0.15 * glowIntensity))
                    .frame(width: 200 * s, height: 10 * s)
                    .blur(radius: 16 * s)
            }
        }
        .offset(y: 110 * s)
    }
    
    // MARK: - Eyes (7 种样式)
    @ViewBuilder
    private var eyes: some View {
        let transitionOpacity = getTransitionOpacity()
        
        switch moodLevel {
        case 0: xEyes(opacity: transitionOpacity)           // 暴风雨 - X眼（崩溃）
        case 1: sadEyes(opacity: transitionOpacity)         // 下雨 - 下垂眼
        case 2: tiredEyes(opacity: transitionOpacity)       // 毛毛雨 - 半闭眼（疲惫）
        case 3: normalEyes(opacity: transitionOpacity)      // 多云 - 方形眼（平静）
        case 4: roundEyes(opacity: transitionOpacity)       // 多云转晴 - 圆形眼
        case 5: starEyes(opacity: transitionOpacity)        // 晴朗 - 星星眼
        default: happyEyes(opacity: transitionOpacity)      // 大晴天 - 咪咪眼
        }
    }
    
    private func getTransitionOpacity() -> Double {
        if moodMicro < 0.15 { return 0.7 + Double(moodMicro) * 2 }
        if moodMicro > 0.85 { return 0.7 + Double(1 - moodMicro) * 2 }
        return 1.0
    }
    
    // Level 0: X眼（崩溃）
    private func xEyes(opacity: Double) -> some View {
        let eyeOpacity = isBlinking ? 0.3 : (0.5 + Double(moodMicro) * 0.3) * opacity
        let strokeWidth = (8 - moodMicro * 2) * s
        
        return HStack(spacing: 40 * s) {
            xEyeShape(strokeWidth: strokeWidth, opacity: eyeOpacity)
            xEyeShape(strokeWidth: strokeWidth, opacity: eyeOpacity)
        }
    }
    
    private func xEyeShape(strokeWidth: CGFloat, opacity: Double) -> some View {
        let eyeSize: CGFloat = 36 * s
        
        return ZStack {
            // X 形状 - 使用 GeometryReader 确保居中
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let halfSize = min(size.width, size.height) / 2 * 0.7
                
                var path1 = Path()
                path1.move(to: CGPoint(x: center.x - halfSize, y: center.y - halfSize))
                path1.addLine(to: CGPoint(x: center.x + halfSize, y: center.y + halfSize))
                
                var path2 = Path()
                path2.move(to: CGPoint(x: center.x + halfSize, y: center.y - halfSize))
                path2.addLine(to: CGPoint(x: center.x - halfSize, y: center.y + halfSize))
                
                context.stroke(path1, with: .color(colors.eyeSadColor), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                context.stroke(path2, with: .color(colors.eyeSadColor), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            }
            .frame(width: eyeSize, height: eyeSize)
        }
        .opacity(opacity)
        .modifier(EyeGlow(color: colors.eyeSadColor, s: s, intensity: glowIntensity))
    }
    
    // Level 1: 下垂眼（悲伤）
    private func sadEyes(opacity: Double) -> some View {
        let eyeOpacity = (0.6 + Double(moodMicro) * 0.2) * opacity
        let strokeWidth = (9 - moodMicro * 2) * s
        let droop = moodMicro * 8 * s
        
        return HStack(spacing: 40 * s) {
            sadEye(droop: droop, strokeWidth: strokeWidth, opacity: eyeOpacity)
            sadEye(droop: droop, strokeWidth: strokeWidth, opacity: eyeOpacity)
        }
    }
    
    private func sadEye(droop: CGFloat, strokeWidth: CGFloat, opacity: Double) -> some View {
        Group {
            if isBlinking {
                Capsule()
                    .fill(colors.eyeSadColor)
                    .frame(width: 45 * s, height: 4 * s)
            } else {
                SadEyePath(droop: droop, s: s)
                    .stroke(colors.eyeSadColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .frame(width: 45 * s, height: 35 * s)
            }
        }
        .opacity(opacity)
        .modifier(EyeGlow(color: colors.eyeSadColor, s: s, intensity: glowIntensity))
    }
    
    // Level 2: 半闭眼（疲惫）
    private func tiredEyes(opacity: Double) -> some View {
        let eyeOpacity = (0.75 + Double(moodMicro) * 0.15) * opacity
        let height = isBlinking ? 4 * s : (18 + moodMicro * 15) * s
        
        return HStack(spacing: 40 * s) {
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(colors.eyeSadColor)
                .frame(width: 45 * s, height: height)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeSadColor, s: s, intensity: glowIntensity))
            
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(colors.eyeSadColor)
                .frame(width: 45 * s, height: height)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeSadColor, s: s, intensity: glowIntensity))
        }
        .animation(.easeInOut(duration: 0.2), value: isBlinking)
    }
    
    // Level 3: 方形眼（平静）
    private func normalEyes(opacity: Double) -> some View {
        let eyeOpacity = (0.85 + Double(moodMicro) * 0.1) * opacity
        let height = isBlinking ? 4 * s : (46 + moodMicro * 8) * s
        let cornerRadius = (14 + moodMicro * 8) * s
        
        return HStack(spacing: 40 * s) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(colors.eyeColor)
                .frame(width: 45 * s, height: height)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(colors.eyeColor)
                .frame(width: 45 * s, height: height)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
        }
        .animation(.easeInOut(duration: 0.2), value: isBlinking)
    }
    
    // Level 4: 圆形眼（愉快）
    private func roundEyes(opacity: Double) -> some View {
        let eyeOpacity = (0.95 + Double(moodMicro) * 0.05) * opacity
        let radius = isBlinking ? 2 * s : (22 + moodMicro * 6) * s
        
        return HStack(spacing: 40 * s) {
            Circle()
                .fill(colors.eyeColor)
                .frame(width: radius * 2, height: radius * 2)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
            
            Circle()
                .fill(colors.eyeColor)
                .frame(width: radius * 2, height: radius * 2)
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
        }
        .animation(.easeInOut(duration: 0.2), value: isBlinking)
    }

    
    // Level 5: 星星眼（兴奋）
    private func starEyes(opacity: Double) -> some View {
        let eyeOpacity = isBlinking ? 0.3 : opacity
        let starSize = (44 + moodMicro * 6) * s
        
        return HStack(spacing: 40 * s) {
            StarShape()
                .fill(colors.eyeColor)
                .frame(width: starSize, height: starSize)
                .rotationEffect(.degrees(starRotation))
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
            
            StarShape()
                .fill(colors.eyeColor)
                .frame(width: starSize, height: starSize)
                .rotationEffect(.degrees(-starRotation))
                .opacity(eyeOpacity)
                .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
        }
    }
    
    // Level 6: 咪咪眼（幸福）
    private func happyEyes(opacity: Double) -> some View {
        let strokeWidth = (7 + moodMicro * 2) * s
        let curve = moodMicro * 5 * s
        
        return HStack(spacing: 40 * s) {
            Group {
                if isBlinking {
                    Capsule()
                        .fill(colors.eyeColor)
                        .frame(width: 45 * s, height: 4 * s)
                } else {
                    HappyEyePath(curve: curve, s: s)
                        .stroke(colors.eyeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                        .frame(width: 45 * s, height: 25 * s)
                }
            }
            .opacity(opacity)
            .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
            
            Group {
                if isBlinking {
                    Capsule()
                        .fill(colors.eyeColor)
                        .frame(width: 45 * s, height: 4 * s)
                } else {
                    HappyEyePath(curve: curve, s: s)
                        .stroke(colors.eyeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                        .frame(width: 45 * s, height: 25 * s)
                }
            }
            .opacity(opacity)
            .modifier(EyeGlow(color: colors.eyeColor, s: s, intensity: glowIntensity))
        }
        .animation(.easeInOut(duration: 0.1), value: isBlinking)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // 浮动动画
        withAnimation(.easeInOut(duration: floatDuration).repeatForever(autoreverses: true)) {
            floatY = -floatAmplitude * s
        }
        withAnimation(.easeInOut(duration: floatDuration * 2).repeatForever(autoreverses: true)) {
            floatRot = 1
        }
        
        // 星球浮动
        withAnimation(.easeInOut(duration: floatDuration * 0.8).repeatForever(autoreverses: true).delay(0.3)) {
            satY = 3 * s
        }
        
        // 脉冲动画
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulse = 1.5
        }
        
        // 星星眼旋转
        withAnimation(.easeInOut(duration: 2.5 - Double(moodMicro) * 0.8).repeatForever(autoreverses: true)) {
            starRotation = 8 + Double(moodMicro) * 5
        }
        
        // 思考灯脉冲动画
        if thinkingMode {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                thinkingPulse = 1.15
            }
        }
        
        // 眨眼定时器
        startBlinkTimer()
    }
    
    private func startBlinkTimer() {
        Timer.scheduledTimer(withTimeInterval: max(2.0, blinkInterval), repeats: true) { timer in
            isBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isBlinking = false
            }
        }
    }
    
    private func restartBlinkTimer() {
        // 重新计算眨眼间隔
    }
}

// MARK: - Theme
public enum RobotMoodTheme: String, CaseIterable {
    case purple
    case dark
    case light
    
    var colors: RobotMoodColors {
        switch self {
        case .purple: return .purple
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Colors
struct RobotMoodColors {
    let bodyCore: [Color]
    let screenBg: Color
    let glassShell: [Color]
    let glassOpacity: [Double]
    let eyeColor: Color
    let eyeSadColor: Color
    let planet: [Color]
    let planetRing: Color
    let rings: [Color]
    let ringsOpacity: [Double]
    let rimLight: Color
    let stroke: Color
    let highlight: Color
    let highlightOpacity: Double
    
    static let purple = RobotMoodColors(
        bodyCore: [Color(hex: "#2E1065"), Color(hex: "#020617")],
        screenBg: Color(hex: "#0f0518"),
        glassShell: [.white, Color(hex: "#E0F2FE"), Color(hex: "#A78BFA"), Color(hex: "#4C1D95")],
        glassOpacity: [0.4, 0.1, 0.05, 0.3],
        eyeColor: Color(hex: "#22D3EE"),
        eyeSadColor: Color(hex: "#22D3EE"),        // 统一蓝色
        planet: [Color(hex: "#E9D5FF"), Color(hex: "#6B21A8")],
        planetRing: Color(hex: "#E9D5FF"),
        rings: [Color(hex: "#A855F7"), Color(hex: "#C084FC"), Color(hex: "#E879F9")],
        ringsOpacity: [0.4, 0.3, 0.5],
        rimLight: Color(hex: "#A855F7"),
        stroke: Color(hex: "#4c1d95"),
        highlight: .white,
        highlightOpacity: 0.5
    )
    
    static let dark = RobotMoodColors(
        bodyCore: [Color(hex: "#151822"), Color(hex: "#0a0c10")],
        screenBg: Color(hex: "#0c0e14"),
        glassShell: [Color(hex: "#e8ecf0"), Color(hex: "#a0aab8"), Color(hex: "#607080"), Color(hex: "#354050")],
        glassOpacity: [0.3, 0.2, 0.15, 0.2],
        eyeColor: Color(hex: "#4A9EFF"),
        eyeSadColor: Color(hex: "#4A9EFF"),
        planet: [Color(hex: "#8898a8"), Color(hex: "#8898a8")],
        planetRing: Color(hex: "#6080a0"),
        rings: [Color(hex: "#3a4a5a"), Color(hex: "#4a5a6a"), Color(hex: "#5a6a7a")],
        ringsOpacity: [1, 0.85, 0.9],
        rimLight: Color(hex: "#4A9EFF"),
        stroke: Color(hex: "#2a3545"),
        highlight: .white,
        highlightOpacity: 0.4
    )
    
    static let light = RobotMoodColors(
        bodyCore: [Color(hex: "#f8f9fc"), Color(hex: "#eef0f5")],
        screenBg: Color(hex: "#e8eaf0"),
        glassShell: [.white, Color(hex: "#f0f2f8"), Color(hex: "#e0e4ec"), Color(hex: "#d0d4e0")],
        glassOpacity: [0.95, 0.85, 0.7, 0.8],
        eyeColor: Color(hex: "#0066CC"),
        eyeSadColor: Color(hex: "#0066CC"),        // 统一蓝色
        planet: [Color(hex: "#e8eaf0"), Color(hex: "#c8ccd8")],
        planetRing: Color(hex: "#a0a8b8"),
        rings: [Color(hex: "#c0c8d8"), Color(hex: "#a8b0c0"), Color(hex: "#9098a8")],
        ringsOpacity: [0.9, 0.8, 0.85],
        rimLight: Color(hex: "#0066CC"),
        stroke: Color(hex: "#b8c0d0"),
        highlight: .white,
        highlightOpacity: 0.98
    )
}

// MARK: - Eye Glow Modifier
private struct EyeGlow: ViewModifier {
    let color: Color
    let s: CGFloat
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8 * intensity), radius: 3 * s)
            .shadow(color: color.opacity(0.5 * intensity), radius: 6 * s)
            .shadow(color: color.opacity(0.3 * intensity), radius: 12 * s)
    }
}

// MARK: - Body Path (复用)
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

// MARK: - Sad Eye Path
private struct SadEyePath: Shape {
    let droop: CGFloat
    let s: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + droop)
        )
        return p
    }
}

// MARK: - Happy Eye Path
private struct HappyEyePath: Shape {
    let curve: CGFloat
    let s: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY - curve))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.maxY - curve),
            control: CGPoint(x: rect.midX, y: rect.minY - curve)
        )
        return p
    }
}

// MARK: - Star Shape
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
#Preview("Mood Levels") {
    ScrollView {
        VStack(spacing: 30) {
            ForEach([0, 14, 28, 42, 56, 70, 85, 100], id: \.self) { mood in
                VStack {
                    RobotAvatarMood(mindValence: mood, bodyEnergy: 50, theme: .dark, size: 120)
                    Text("心情: \(mood)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}

#Preview("Energy Levels") {
    HStack(spacing: 20) {
        ForEach([10, 50, 90], id: \.self) { energy in
            VStack {
                RobotAvatarMood(mindValence: 70, bodyEnergy: energy, theme: .dark, size: 150)
                Text("能量: \(energy)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    .padding()
    .background(Color.black)
}

#Preview("Themes") {
    HStack(spacing: 20) {
        ForEach(RobotMoodTheme.allCases, id: \.self) { theme in
            VStack {
                RobotAvatarMood(mindValence: 70, bodyEnergy: 60, theme: theme, size: 150)
                Text(theme.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    .padding()
    .background(Color(hex: "#1a1a2e"))
}
