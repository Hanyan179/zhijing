import SwiftUI

public struct ResonanceHub: View {
    @State private var expanded: Bool = false
    public let entries: [JournalEntry]
    public let todayDate: String
    @EnvironmentObject private var appState: AppState
    public init(entries: [JournalEntry], todayDate: String) { self.entries = entries; self.todayDate = todayDate }
    public var body: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { expanded.toggle() } }) {
                HStack {
                    Text(Localization.tr("resonanceStream")).font(.system(size: 15, weight: .semibold)).foregroundColor(.indigo)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundColor(.indigo)
                }
                .padding(12)
                .background(Color.indigo.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if expanded {
                VStack(spacing: 6) {
                    HStack {
                        Text("\(entries.count)" + Localization.tr("memoriesPast")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                        Spacer()
                        Text(Localization.tr("tapToJump")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                    }
                    VStack(spacing: 12) {
                        ForEach(entries) { e in
                            Button(action: { if let meta = MockDataService.getEntryMeta(id: e.id) { appState.selectedDate = meta.date; appState.focusEntryId = e.id } }) {
                                JournalRow(entry: e, questionEntries: MockDataService.questions, currentDateLabel: todayDate, todayDate: todayDate, isHighlighted: true, lang: appState.lang)
                            }
                        }
                    }
                }
                .padding(12)
                .modifier(Materials.card())
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
    }
}
