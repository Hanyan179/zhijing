import SwiftUI

public struct MorningBriefing: View {
    @State private var expanded: Bool = true
    public let items: [JournalEntry]
    public init(items: [JournalEntry]) { self.items = items }
    public var body: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { expanded.toggle() } }) {
                HStack {
                    Text(NSLocalizedString("inbox", comment: "")).font(.system(size: 15, weight: .semibold)).foregroundColor(Colors.slatePrimary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundColor(Colors.systemGray)
                }
                .padding(12)
                .background(Colors.slateLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if expanded {
                VStack(spacing: 12) {
                    ForEach(items) { e in
                        JournalRow(entry: e, questionEntries: MockDataService.questions, currentDateLabel: ChronologyAnchor.TODAY_DATE, todayDate: ChronologyAnchor.TODAY_DATE, lang: .zh)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }
}
