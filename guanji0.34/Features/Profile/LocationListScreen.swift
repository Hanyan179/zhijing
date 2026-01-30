import SwiftUI
import Foundation

public struct LocationListScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""
    @State private var showAdd: Bool = false
    @State private var newPlace: String = ""
    @State private var navToDetail: Bool = false
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        List {
            Section(header: Text(Localization.tr("locationManagement"))) {
                ForEach(filteredMappings) { m in
                    let fencesForMap = vm.addressFences.filter { $0.mappingId == m.id }
                    let fenceCount = fencesForMap.count
                    let subtitle: String? = fencesForMap.first?.originalRawName
                    NavigationLink(destination: LocationDetailScreen(vm: vm).onAppear { vm.selectedMapping = m }) {
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: iconSystemName(m.icon)).foregroundColor(colorFor(m.color)).frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(m.name).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText)
                                    if let sub = subtitle { Text(sub).font(.system(size: 11)).foregroundColor(Colors.systemGray) }
                                }
                            }
                            Spacer()
                            HStack(spacing: 6) { Text("\(fenceCount)").font(.system(size: 12)).foregroundColor(Colors.systemGray) }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer, prompt: Localization.tr("searchPlace"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { vm.addAndSelectMapping(name: Localization.tr("untitledPlace")); navToDetail = true }) { Image(systemName: "plus") }
            }
        }
        .navigationDestination(isPresented: $navToDetail) {
            LocationDetailScreen(vm: vm)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("locationManagement"))
        .id(appState.lang.rawValue)
    }

    private var filteredMappings: [AddressMapping] {
        if query.isEmpty { return vm.addressMappings }
        return vm.addressMappings.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func iconSystemName(_ id: String?) -> String {
        switch id ?? "mappin" {
        case "home": return "house"
        case "building": return "building.2"
        case "briefcase": return "briefcase"
        case "bag": return "bag"
        case "graduation": return "graduationcap"
        case "heart": return "heart.fill"
        case "tree": return "tree"
        case "airplane": return "airplane"
        case "bed": return "bed.double"
        case "food": return "fork.knife"
        default: return "mappin.circle"
        }
    }

    private func colorFor(_ name: String?) -> Color {
        switch name ?? "slate" {
        case "indigo": return Colors.indigo
        case "amber": return Colors.amber
        case "rose": return Colors.rose
        case "emerald": return Colors.emerald
        case "sky": return Colors.sky
        case "slate": return Colors.slatePrimary
        default: return Colors.systemGray
        }
    }
}
