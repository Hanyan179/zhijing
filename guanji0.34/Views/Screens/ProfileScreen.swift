import SwiftUI
import Foundation

public struct ProfileScreen: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showGallery = false
    @State private var showInsight = false
    @State private var showLangPicker = false
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if vm.view == .main {
                    GroupLabel(label: Localization.tr("osModules"))
                    ListGroup {
                        ListRow(iconName: "lock", label: Localization.tr("privacy"), onClick: { vm.view = .privacy })
                        ListRow(iconName: "bell", label: Localization.tr("notifications"), onClick: { vm.view = .notifications })
                        ListRow(iconName: "map", label: Localization.tr("locations"), onClick: { vm.view = .locationList })
                        ListRow(iconName: "wrench", label: Localization.tr("dataMaintenance"), onClick: { vm.view = .dataMaintenance })
                    }
                    GroupLabel(label: Localization.tr("lifeInsight"))
                    ListGroup {
                        ListRow(iconName: "chart.pie.fill", label: Localization.tr("insightPlan"), value: vm.userPlan, onClick: { vm.view = .membership })
                        ListRow(iconName: "photo.on.rectangle", label: Localization.tr("gallery"), onClick: { showGallery = true })
                        ListRow(iconName: "square.grid.2x2", label: Localization.tr("componentLibrary"), onClick: { vm.view = .componentGallery })
                    }
                    GroupLabel(label: Localization.tr("system"))
                    ListGroup {
                        ListRow(iconName: "globe", label: Localization.tr("language"), value: Localization.displayName(appState.lang), onClick: { showLangPicker = true })
                        ListRow(iconName: "icloud", label: Localization.tr("dataSync"), value: "On", onClick: { })
                        ListRow(iconName: "info.circle", label: Localization.tr("about"), onClick: { vm.view = .about })
                        ListRow(iconName: "doc.text", label: Localization.tr("subscriptionInfo"), onClick: { vm.view = .subscriptionInfo })
                    }
                    Spacer()
                } else {
                    ProfileDetailContainer(vm: vm)
                }
            }
            .navigationTitle(Localization.tr("profileTitle"))
            .padding(.top, 8)
        }
        .sheet(isPresented: $showGallery) { GallerySheet() }
        .sheet(isPresented: $showInsight) { InsightSheet() }
        .sheet(isPresented: $showLangPicker) { LanguagePickerSheet(selected: $appState.lang) }
    }
}

struct ProfileDetailContainer: View {
    @ObservedObject var vm: ProfileViewModel
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { vm.view = .main }) { Image(systemName: "chevron.left").foregroundColor(Colors.systemGray).font(.system(size: 14, weight: .bold)) }
                Spacer()
            }
            .padding(.horizontal, 16)

            switch vm.view {
            case .privacy: PrivacyScreen(vm: vm)
            case .notifications: NotificationsScreen(vm: vm)
            case .membership: MembershipScreen(vm: vm)
            case .about: AboutScreen()
            case .subscriptionInfo: SubscriptionInfoScreen(vm: vm)
            case .dataMaintenance: DataMaintenanceScreen()
            case .locationList: LocationListScreen(vm: vm)
            case .locationDetail: LocationDetailScreen(vm: vm)
            case .componentGallery: ComponentGalleryScreen()
            default: EmptyView()
            }
            Spacer()
        }
    }
}
struct LanguagePickerSheet: View {
    @Binding var selected: Lang
    var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("language"))
            List {
                ForEach(Localization.supported, id: \.self) { l in
                    Button(action: { selected = l; Localization.set(l) }) {
                        HStack { Text(Localization.displayName(l)); if l == selected { Spacer(); Image(systemName: "checkmark").foregroundColor(.indigo) } }
                    }
                }
            }
        }
        .padding(12)
    }
}
