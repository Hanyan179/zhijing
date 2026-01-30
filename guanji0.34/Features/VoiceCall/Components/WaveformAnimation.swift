import SwiftUI

/// 波形动画组件
/// 用于语音通话界面显示监听状态
/// 支持基于实际音量的响应式动画
/// Requirements: 5.2
public struct WaveformAnimation: View {
    /// 音频电平 (0.0-1.0)，nil 时使用默认动画
    var audioLevel: Float?
    
    /// 波形条数量
    private let barCount = 5
    /// 波形条宽度
    private let barWidth: CGFloat = 4
    /// 波形条间距
    private let barSpacing: CGFloat = 6
    
    public init(audioLevel: Float? = nil) {
        self.audioLevel = audioLevel
    }
    
    public var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    audioLevel: audioLevel,
                    barIndex: index
                )
                .frame(width: barWidth)
            }
        }
    }
}

/// 单个波形条
/// 支持音量响应和默认动画两种模式
struct WaveformBar: View {
    let audioLevel: Float?
    let barIndex: Int
    
    @State private var animatedHeight: CGFloat = 20
    @State private var isAnimating = false
    
    /// 最小高度
    private let minHeight: CGFloat = 20
    /// 最大高度
    private let maxHeight: CGFloat = 60
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Colors.indigo)
            .frame(height: currentHeight)
            .animation(.easeOut(duration: 0.1), value: currentHeight)
            .onAppear {
                if audioLevel == nil {
                    startDefaultAnimation()
                }
            }
            .onChange(of: audioLevel) { newValue in
                if newValue == nil && !isAnimating {
                    startDefaultAnimation()
                }
            }
    }
    
    /// 当前高度：基于音量或默认动画
    private var currentHeight: CGFloat {
        if let level = audioLevel {
            // 基于音量计算高度，每个条有轻微偏移增加视觉效果
            let offset = Float(barIndex) * 0.1
            let adjustedLevel = min(1.0, level + offset * level)
            return minHeight + CGFloat(adjustedLevel) * (maxHeight - minHeight)
        } else {
            return animatedHeight
        }
    }
    
    /// 启动默认动画（无音量数据时）
    private func startDefaultAnimation() {
        isAnimating = true
        let delay = Double(barIndex) * 0.1
        
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay)
        ) {
            animatedHeight = CGFloat.random(in: 30...maxHeight)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WaveformAnimation_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // 默认动画模式
            VStack {
                Text("默认动画").font(.caption)
                WaveformAnimation()
                    .frame(width: 100, height: 60)
            }
            .padding()
            .background(Colors.slateLight)
            
            // 低音量
            VStack {
                Text("低音量 (0.2)").font(.caption)
                WaveformAnimation(audioLevel: 0.2)
                    .frame(width: 100, height: 60)
            }
            .padding()
            .background(Colors.slateLight)
            
            // 高音量
            VStack {
                Text("高音量 (0.8)").font(.caption)
                WaveformAnimation(audioLevel: 0.8)
                    .frame(width: 100, height: 60)
            }
            .padding()
            .background(Colors.slateLight)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
