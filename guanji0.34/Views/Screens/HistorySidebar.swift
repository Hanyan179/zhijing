import SwiftUI

public struct HistorySidebar: View {
    @StateObject private var vm = HistoryViewModel()
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        VStack(spacing: 8) {
            TextField(NSLocalizedString("searchMemory", comment: ""), text: $vm.searchText).textFieldStyle(.roundedBorder).padding(.horizontal, 12)
            List(vm.previewDates.filter { vm.searchText.isEmpty ? true : $0.contains(vm.searchText) }, id: \.self) { d in
                Button(action: { appState.selectedDate = d }) { HStack { Text(d); Spacer(); Text(NSLocalizedString("backToToday", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray) } }
            }
        }
        .navigationTitle(NSLocalizedString("historyTitle", comment: ""))
    }
}
