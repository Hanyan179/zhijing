import SwiftUI

public struct SceneBlock: View {
    public let scene: SceneGroup
    public let questionEntries: [QuestionEntry]
    public let currentDateLabel: String
    public let todayDate: String
    public let focusEntryId: String?
    @EnvironmentObject private var appState: AppState
    public var onLongPress: ((JournalEntry) -> Void)? = nil
    public init(scene: SceneGroup, questionEntries: [QuestionEntry] = [], currentDateLabel: String, todayDate: String, focusEntryId: String? = nil, onLongPress: ((JournalEntry) -> Void)? = nil) { self.scene = scene; self.questionEntries = questionEntries; self.currentDateLabel = currentDateLabel; self.todayDate = todayDate; self.focusEntryId = focusEntryId; self.onLongPress = onLongPress }
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocationBadge(location: scene.location)
            ForEach(scene.entries) { e in
                JournalRow(entry: e, questionEntries: questionEntries, currentDateLabel: currentDateLabel, todayDate: todayDate, isHighlighted: (e.id == focusEntryId), lang: appState.lang)
                    .id(e.id)
                    .onLongPressGesture { onLongPress?(e) }
            }
        }
        .padding(.vertical, 12)
    }
}
