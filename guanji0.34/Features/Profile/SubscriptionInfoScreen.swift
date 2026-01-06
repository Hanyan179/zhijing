import SwiftUI
import Foundation

public struct SubscriptionInfoScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        List {
            Section(Localization.tr("subscriptionInfo")) {
                HStack {
                    Label(Localization.tr("statusActive"), systemImage: "checkmark.seal.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.green)
                    Spacer()
                    Button(Localization.tr("manageSubscription")) {}
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .tint(Colors.indigo)
                }
            }
            
            Section(Localization.tr("subscriptionNoticeLabel")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.tr("subNotice1Title")).font(.headline)
                    Text(Localization.tr("subNotice1Body")).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.tr("subNotice2Title")).font(.headline)
                    Text(Localization.tr("subNotice2Body")).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.tr("subNotice3Title")).font(.headline)
                    Text(Localization.tr("subNotice3Body")).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("subscriptionInfo"))
        .id(appState.lang.rawValue)
    }
}
