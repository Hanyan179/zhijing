import SwiftUI

public struct InsightSheet: View {
    @StateObject private var vm = InsightViewModel()
    public init() {}
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Picker("", selection: Binding(get: { "All" }, set: { _ in })) {
                    Text(NSLocalizedString("week", comment: "")).tag("Week")
                    Text(NSLocalizedString("month", comment: "")).tag("Month")
                    Text(NSLocalizedString("year", comment: "")).tag("Year")
                    Text(NSLocalizedString("all", comment: "")).tag("All")
                }
                .pickerStyle(.segmented)
            }
            OverviewCard(streak: vm.streak, totalDays: vm.totalDays, totalEntries: vm.totalEntries)
            StateAnalysisCard(vm: vm)
            HeatmapGrid(hourCounts: vm.hourCounts)
            RankingListView(vm: vm)
            KeywordsCloudView(words: vm.topCategories)
            HStack { Spacer(); Text(NSLocalizedString("insightEngine", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray) }
        }
        .padding(16)
    }
}

#Preview { InsightSheet() }
