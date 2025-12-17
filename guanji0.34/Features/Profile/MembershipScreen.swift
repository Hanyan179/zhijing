import SwiftUI
import Foundation

public struct MembershipScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        List {
            Section(Localization.tr("membership")) {
                HStack {
                    Label(Localization.tr("currentPlan"), systemImage: "person.crop.circle.badge.checkmark")
                    Spacer()
                    Text(vm.userPlan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button(action: {}) {
                    HStack {
                        Label(Localization.tr("upgradePlan"), systemImage: "arrow.up.circle.fill")
                            .foregroundStyle(.indigo)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("membership"))
        .id(appState.lang.rawValue)
    }
}
