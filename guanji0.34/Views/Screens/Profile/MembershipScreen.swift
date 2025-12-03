import SwiftUI
import Foundation

public struct MembershipScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("membership"))
            ListGroup {
                HStack {
                    HStack(spacing: 12) { Image(systemName: "person.crop.circle.badge.checkmark").foregroundColor(Color(.systemGray)); Text(Localization.tr("currentPlan")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    Text(vm.userPlan).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                Button(action: {}) {
                    HStack {
                        HStack(spacing: 12) { Image(systemName: "arrow.up.circle.fill").foregroundColor(.indigo); Text(Localization.tr("upgradePlan")).font(.system(size: 14, weight: .bold)).foregroundColor(.indigo) }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .id(appState.lang.rawValue)
    }
}
