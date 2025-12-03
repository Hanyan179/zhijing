import SwiftUI

public struct GallerySheet: View {
    @StateObject private var vm = GalleryViewModel()
    @State private var selected: UserAchievement?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("memoryMuseum", comment: "")).font(Typography.fontSerif).foregroundColor(Colors.text)
            TextField(NSLocalizedString("searchCollection", comment: ""), text: $vm.query)
                .textFieldStyle(.roundedBorder)
            if vm.filtered.isEmpty {
                Text(NSLocalizedString("noArtifacts", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.filtered) { item in
                            Button(action: { selected = item }) {
                                AchievementCard(achievement: item)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Colors.background)
        .sheet(item: $selected, content: { ach in
            AchievementDetailSheet(item: ach)
        })
    }
}

#Preview {
    GallerySheet()
}
