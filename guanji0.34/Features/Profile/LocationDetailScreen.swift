import SwiftUI
import Foundation
import MapKit
import CoreLocation

public struct LocationDetailScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    public init(vm: ProfileViewModel) { self.vm = vm }
    @State private var showMapPicker: Bool = false
    private var mapping: AddressMapping? { vm.selectedMapping }
    private var fences: [AddressFence] {
        guard let mid = mapping?.id else { return [] }
        return vm.addressFences.filter { $0.mappingId == mid }
    }
    private var colors: [String] { ["indigo", "violet", "rose", "pink", "emerald", "teal", "sky", "blue", "amber", "orange", "slate"] }
    private var icons: [String] { ["home", "building", "briefcase", "bag", "graduation", "heart", "tree", "airplane", "bed", "food", "mappin"] }
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "indigo": return Colors.indigo
        case "violet": return Colors.violet
        case "rose": return Colors.rose
        case "pink": return Colors.pink
        case "emerald": return Colors.emerald
        case "teal": return Colors.teal
        case "sky": return Colors.sky
        case "blue": return Colors.blue
        case "amber": return Colors.amber
        case "orange": return Colors.orange
        case "slate": return Colors.slatePrimary
        default: return Colors.systemGray
        }
    }
    public var body: some View {
        List {
            Section(header: Text(Localization.tr("placeName")).foregroundColor(Colors.slateText)) {
                if let m = mapping {
                    TextField(Localization.tr("placeName"), text: Binding(
                        get: { vm.addressMappings.first(where: { $0.id == m.id })?.name ?? m.name },
                        set: { vm.updateMappingName(id: m.id, name: $0) }
                    ))
                }
            }

            Section(header: Text(Localization.tr("appearance")).foregroundColor(Colors.slateText)) {
                if let m = mapping {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { id in
                                Button(action: { vm.updateMappingIcon(id: m.id, icon: id) }) {
                                    ZStack {
                                        if m.icon == id {
                                            Circle()
                                                .fill(colorFor(m.color ?? "slate").opacity(0.15))
                                                .frame(width: 44, height: 44)
                                        }
                                        Image(systemName: iconSystemName(id))
                                            .foregroundColor((m.icon == id) ? colorFor(m.color ?? "slate") : Colors.slateText)
                                            .font(.system(size: 18))
                                    }
                                    .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { c in
                                Button(action: { vm.updateMappingColor(id: m.id, color: c) }) {
                                    ZStack {
                                        Circle()
                                            .fill(colorFor(c))
                                            .frame(width: 32, height: 32)
                                            .shadow(color: Colors.slateText.opacity(0.1), radius: 2, x: 0, y: 1)
                                        
                                        if m.color == c {
                                            Circle()
                                                .stroke(Colors.background, lineWidth: 2)
                                                .frame(width: 34, height: 34)
                                            Circle()
                                                .stroke(colorFor(c), lineWidth: 2)
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
            }

            Section(header: HStack {
                Text(Localization.tr("physicalAnchors")).foregroundColor(Colors.slateText)
                Spacer()
                Button(action: { showMapPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Colors.indigo)
                }
            }) {
                ForEach(fences) { f in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(f.originalRawName).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText)
                                Text(String(format: Localization.tr("latLngFormat"), String(format: "%.4f", f.lat), String(format: "%.4f", f.lng))).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundColor(Colors.systemGray)
                            }
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Slider(value: Binding(get: { currentFenceRadius(f.id) }, set: { vm.updateFenceRadius(fenceId: f.id, radius: $0) }), in: 50...1000, step: 50)
                            Text(String(format: Localization.tr("radiusMetersFormat"), "\(Int(currentFenceRadius(f.id)))")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete { indexSet in
                    indexSet.forEach { idx in
                        let f = fences[idx]
                        vm.deleteFence(fenceId: f.id)
                    }
                }
            }

            if let m = mapping {
                Section(header: Text("")) {
                    Button(action: { vm.deleteMapping(id: m.id); dismiss() }) { Text(Localization.tr("deletePlace")).foregroundColor(.red) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Colors.background.ignoresSafeArea())
        .id(appState.lang.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundColor(Colors.indigo)
                }
            }
        }
        .sheet(isPresented: $showMapPicker) {
            if let m = mapping {
                let fences = vm.addressFences.filter { $0.mappingId == m.id }
                let initialRegion: MKCoordinateRegion? = {
                    guard !fences.isEmpty else { return nil }
                    var minLat = fences.first!.lat
                    var maxLat = fences.first!.lat
                    var minLng = fences.first!.lng
                    var maxLng = fences.first!.lng
                    for f in fences {
                        minLat = min(minLat, f.lat)
                        maxLat = max(maxLat, f.lat)
                        minLng = min(minLng, f.lng)
                        maxLng = max(maxLng, f.lng)
                    }
                    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLng + maxLng) / 2.0)
                    let latDelta = max(0.02, (maxLat - minLat) * 1.5)
                    let lngDelta = max(0.02, (maxLng - minLng) * 1.5)
                    return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta))
                }()
                NavigationStack { LocationMapPickerScreen(vm: vm, mappingId: m.id, initialRegion: initialRegion) }
            }
        }
    }

    private func currentFenceRadius(_ id: String) -> Double {
        vm.addressFences.first(where: { $0.id == id })?.radius ?? 50
    }

    private func iconSystemName(_ id: String) -> String {
        switch id {
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
}
