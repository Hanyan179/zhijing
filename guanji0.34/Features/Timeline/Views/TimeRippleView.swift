import SwiftUI

public struct TimeRippleView: View {
    public let repliedCount: Int
    public let totalCount: Int
    public let action: () -> Void
    
    public init(repliedCount: Int, totalCount: Int, action: @escaping () -> Void) {
        self.repliedCount = repliedCount
        self.totalCount = totalCount
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Left Line
                Rectangle()
                    .fill(Colors.indigo.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 8) {
                    Image(systemName: "drop.circle.fill") // Ripple icon
                        .font(.system(size: 16))
                        .foregroundColor(Colors.indigo)
                    
                    Text(Localization.tr("timeRipple").uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2) // Letter spacing
                        .foregroundColor(Colors.indigo)
                        .fixedSize()
                    
                    Text("\(repliedCount)/\(totalCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Colors.indigo)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Colors.indigo.opacity(0.1))
                        .clipShape(Capsule())
                        .fixedSize()
                }
                .padding(.horizontal, 8)
                
                // Right Line
                Rectangle()
                    .fill(Colors.indigo.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.01)) // Hit area
        }
        .buttonStyle(.plain)
    }
}
