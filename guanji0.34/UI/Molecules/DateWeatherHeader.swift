import SwiftUI

public struct DateWeatherHeader: View {
    public let dateText: String
    public let onOpenMindState: (() -> Void)?
    public let showBackToToday: Bool
    public let onBackToToday: (() -> Void)?
    public init(dateText: String, onOpenMindState: (() -> Void)? = nil, showBackToToday: Bool = false, onBackToToday: (() -> Void)? = nil) {
        self.dateText = dateText
        self.onOpenMindState = onOpenMindState
        self.showBackToToday = showBackToToday
        self.onBackToToday = onBackToToday
    }
    public var body: some View {
        HStack(spacing: 6) {
            Text(dateText).font(Typography.header).foregroundColor(Colors.slateText)
            Image(systemName: "cloud.drizzle").foregroundColor(Colors.systemGray)
            Spacer()
            if showBackToToday {
                Button(action: { onBackToToday?() }) {
                    Text(Localization.tr("backToToday")).font(Typography.caption).foregroundColor(Colors.slate500)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Colors.slateLight.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // .padding(.horizontal, 16) // Removed as per request to fix alignment/spacing
        .padding(.vertical, 10)
    
        .contentShape(Rectangle())
        .onTapGesture { onOpenMindState?() }
        .gesture(DragGesture(minimumDistance: 20).onEnded { _ in onOpenMindState?() })
    }
}
