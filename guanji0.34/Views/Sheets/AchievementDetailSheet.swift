import SwiftUI

public struct AchievementDetailSheet: View {
    public let item: UserAchievement
    public init(item: UserAchievement) { self.item = item }
    @EnvironmentObject private var appState: AppState
    public var body: some View {
        VStack(spacing: 12) {
            Text(item.aiGeneratedTitle?.zh ?? item.aiGeneratedTitle?.en ?? "").font(.title3).bold()
            if let desc = item.aiPoeticDescription?.zh ?? item.aiPoeticDescription?.en { Text(desc).font(.subheadline).foregroundColor(Colors.systemGray) }
            HStack(spacing: 8) {
                Text(NSLocalizedString("current", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Text(String(format: "%.0f", item.progressValue)).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Text(NSLocalizedString("target", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Text(String(format: "%.0f", item.targetValue)).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
            Divider()
            HStack { Text(NSLocalizedString("evidenceChain", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray); Spacer() }
            if item.relatedEntryIDs.isEmpty {
                Text(NSLocalizedString("noTraces", comment: "")).font(.footnote).foregroundColor(Colors.systemGray)
            } else {
                ForEach(item.relatedEntryIDs, id: \.self) { id in
                    let meta = MockDataService.getEntryMeta(id: id)
                    Button(action: { if let m = meta { appState.selectedDate = m.date; appState.focusEntryId = id } }) {
                        HStack {
                            Text(meta?.title ?? id).font(.footnote)
                            Spacer()
                            if let m = meta { Text(m.date).font(Typography.fontEngraved).foregroundColor(Colors.systemGray) }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            Spacer()
        }
        .padding(16)
    }
}
