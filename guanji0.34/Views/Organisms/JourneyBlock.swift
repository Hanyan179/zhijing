import SwiftUI

public struct JourneyBlockView: View {
    public let journey: JourneyBlock
    public let questionEntries: [QuestionEntry]
    public let currentDateLabel: String
    public let todayDate: String
    public let focusEntryId: String?
    @EnvironmentObject private var appState: AppState
    public var onLongPress: ((JournalEntry) -> Void)? = nil
    public init(journey: JourneyBlock, questionEntries: [QuestionEntry] = [], currentDateLabel: String, todayDate: String, focusEntryId: String? = nil, onLongPress: ((JournalEntry) -> Void)? = nil) { self.journey = journey; self.questionEntries = questionEntries; self.currentDateLabel = currentDateLabel; self.todayDate = todayDate; self.focusEntryId = focusEntryId; self.onLongPress = onLongPress }
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                LocationBadge(location: journey.origin)
                Image(systemName: Icons.transportIconName(journey.mode)).foregroundColor(Colors.systemGray)
                LocationBadge(location: journey.destination)
                Spacer()
                Text(journey.duration).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
            ForEach(journey.entries) { e in
                JournalRow(entry: e, questionEntries: questionEntries, currentDateLabel: currentDateLabel, todayDate: todayDate, isHighlighted: (e.id == focusEntryId), lang: appState.lang)
                    .id(e.id)
                    .onLongPressGesture { onLongPress?(e) }
            }
        }
        .padding(.vertical, 12)
    }
}
