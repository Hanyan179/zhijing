import SwiftUI

public struct ResonanceHub: View {
    @State private var expanded: Bool = false
    public let stats: [ResonanceDateStat]
    public init(stats: [ResonanceDateStat]) { self.stats = stats }
    @EnvironmentObject private var appState: AppState
    private var totalMemories: Int { stats.reduce(0) { $0 + $1.originalCount } }
    private func relativeLabel(_ s: ResonanceDateStat) -> String {
        switch s.yearsAgo {
        case 1: return Localization.tr("oneYearAgo")
        case 2: return Localization.tr("twoYearsAgo")
        default: return "\(s.yearsAgo)" + Localization.tr("yearsAgoSuffix")
        }
    }
    public var body: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { expanded.toggle() } }) {
                HStack {
                    Text("\(totalMemories)" + Localization.tr("memoriesPast")).font(Typography.body).foregroundColor(Colors.slateText)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundColor(Colors.slate500)
                }
                .padding(12)
                .background(Colors.slateLight.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if expanded {
                VStack(spacing: 10) {
                    VStack(spacing: 14) {
                        ForEach(stats) { s in
                            Button(action: { appState.selectedDate = s.date }) {
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(spacing: 4) {
                                        Circle().fill(Colors.indigo).frame(width: 8, height: 8)
                                        Rectangle().fill(Colors.slateLight).frame(width: 2, height: 28)
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(relativeLabel(s)).font(Typography.body).foregroundColor(Colors.slateText)
                                        if let t = s.title, !t.isEmpty { Text(t).font(Typography.body).foregroundColor(Colors.slateText) }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
    }
}
