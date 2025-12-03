import SwiftUI
import Foundation

public struct LocationDetailScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    private var mapping: AddressMapping? { vm.selectedMapping }
    private var fences: [AddressFence] {
        guard let mid = mapping?.id else { return [] }
        return vm.addressFences.filter { $0.mappingId == mid }
    }
    private var colors: [String] { ["indigo", "amber", "rose", "emerald", "sky", "slate"] }
    private var icons: [String] { ["home", "briefcase", "coffee", "heart", "tree", "vacation", "map"] }
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "indigo": return .indigo
        case "amber": return .yellow
        case "rose": return .pink
        case "emerald": return .green
        case "sky": return .cyan
        case "slate": return Colors.slatePrimary
        default: return Colors.systemGray
        }
    }
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("placeName"))
            if let m = mapping {
                TextField(m.name, text: Binding(
                    get: { vm.addressMappings.first(where: { $0.id == m.id })?.name ?? m.name },
                    set: { vm.updateMappingName(id: m.id, name: $0) }
                ))
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
            }
            
            GroupLabel(label: Localization.tr("appearance"))
            if let m = mapping {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(icons, id: \.self) { id in
                            Button(action: { vm.updateMappingIcon(id: m.id, icon: id) }) {
                                Image(systemName: iconSystemName(id)).foregroundColor(Colors.slateText)
                            }
                            .frame(width: 36, height: 36)
                            .background((m.icon == id) ? Colors.slateDark.opacity(0.9) : Color.white.opacity(0.6))
                            .foregroundColor((m.icon == id) ? .white : Colors.slateText)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(colors, id: \.self) { c in
                            Button(action: { vm.updateMappingColor(id: m.id, color: c) }) {
                                Circle().fill(colorFor(c)).frame(width: 24, height: 24)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke((m.color == c) ? Colors.slateDark : Color.clear, lineWidth: 2))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            GroupLabel(label: Localization.tr("physicalAnchors"))
            ListGroup {
                ForEach(fences) { f in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(f.originalRawName).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText)
                                Text(String(format: Localization.tr("latLngFormat"), String(format: "%.4f", f.lat), String(format: "%.4f", f.lng))).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundColor(Colors.systemGray)
                            }
                            Spacer()
                            Button(action: { vm.deleteFence(fenceId: f.id) }) { Text(Localization.tr("deleteAnchor")).font(.system(size: 11)).foregroundColor(.red) }
                        }
                        HStack(spacing: 8) {
                            Slider(value: Binding(get: { currentFenceRadius(f.id) }, set: { vm.updateFenceRadius(fenceId: f.id, radius: $0) }), in: 50...1000, step: 50)
                            Text(String(format: Localization.tr("radiusMetersFormat"), "\(Int(currentFenceRadius(f.id)))")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                }
            }
            
            if let m = mapping {
                Button(action: { vm.deleteMapping(id: m.id); vm.view = .locationList }) { Text(Localization.tr("deletePlace")).font(.system(size: 13, weight: .bold)).foregroundColor(.red) }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .id(appState.lang.rawValue)
    }

    private func currentFenceRadius(_ id: String) -> Double {
        vm.addressFences.first(where: { $0.id == id })?.radius ?? 50
    }

    private func iconSystemName(_ id: String) -> String {
        switch id {
        case "home": return "house"
        case "briefcase": return "briefcase"
        case "coffee": return "cup.and.saucer"
        case "heart": return "heart.fill"
        case "tree": return "tree"
        case "vacation": return "airplane"
        default: return "mappin.circle"
        }
    }
}
