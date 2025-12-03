import SwiftUI
import Foundation

public struct SubscriptionInfoScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("subscriptionInfo"))
            ListGroup {
                HStack {
                    HStack(spacing: 12) { Image(systemName: "checkmark.seal").foregroundColor(.green); Text(Localization.tr("statusActive")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    Button(action: {}) { Text(Localization.tr("manageSubscription")).font(.system(size: 12, weight: .bold)).foregroundColor(.indigo) }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text(Localization.tr("subNotice1Title")).font(.system(size: 14, weight: .bold)).foregroundColor(Colors.slateText)
                    Text(Localization.tr("subNotice1Body")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text(Localization.tr("subNotice2Title")).font(.system(size: 14, weight: .bold)).foregroundColor(Colors.slateText)
                    Text(Localization.tr("subNotice2Body")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text(Localization.tr("subNotice3Title")).font(.system(size: 14, weight: .bold)).foregroundColor(Colors.slateText)
                    Text(Localization.tr("subNotice3Body")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
            }
        }
        .id(appState.lang.rawValue)
    }
}
