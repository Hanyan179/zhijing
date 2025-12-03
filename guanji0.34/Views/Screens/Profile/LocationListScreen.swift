import SwiftUI
import Foundation

public struct LocationListScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("mappedLocations"))
            ListGroup {
                ForEach(vm.addressMappings) { m in
                    let fenceCount = vm.addressFences.filter { $0.mappingId == m.id }.count
                    Button(action: { vm.selectedMapping = m; vm.view = .locationDetail }) {
                        HStack {
                            HStack(spacing: 12) { Image(systemName: "mappin.circle").foregroundColor(Color(.systemGray)); Text(m.name).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                            Spacer()
                            HStack(spacing: 6) { Text("\(fenceCount)").font(.system(size: 12)).foregroundColor(Colors.systemGray); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                }
            }
        }
        .id(appState.lang.rawValue)
    }
}
