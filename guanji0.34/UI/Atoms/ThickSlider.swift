import SwiftUI

public struct ThickSlider: View {
    @Binding public var value: Double
    public let range: ClosedRange<Double>
    public let step: Double
    public let leftText: String
    public let rightText: String
    public let accent: Color
    public init(value: Binding<Double>, range: ClosedRange<Double> = 0...100, step: Double = 1, leftText: String, rightText: String, accent: Color = Colors.slatePrimary) {
        self._value = value
        self.range = range
        self.step = step
        self.leftText = leftText
        self.rightText = rightText
        self.accent = accent
    }
    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 8
                let pad: CGFloat = 20
                let trackWidth = width - pad * 2
                let frac = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                let knobX = pad + frac * trackWidth
                ZStack(alignment: .leading) {
                    Capsule().fill(Colors.slateLight).frame(height: height).padding(.horizontal, pad)
                    Capsule().fill(accent).frame(width: max(0, knobX - pad), height: height).padding(.leading, pad)
                
                    Circle().fill(Color.white).frame(width: 28, height: 28).shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2).position(x: knobX, y: height/2 + 14)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    let x = min(max(g.location.x - pad, 0), trackWidth)
                    let frac = Double(x / trackWidth)
                    var newVal = range.lowerBound + frac * (range.upperBound - range.lowerBound)
                    if step > 0 { newVal = (newVal / step).rounded() * step }
                    value = min(max(newVal, range.lowerBound), range.upperBound)
                })
            }
            .frame(height: 44)
            HStack {
                Text(leftText).font(.caption)
                Spacer()
                Text(rightText).font(.caption)
            }
        }
    }
}
