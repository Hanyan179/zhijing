import SwiftUI
import Foundation

public struct DataMaintenanceScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    public init(vm: ProfileViewModel) { self.vm = vm }
    @EnvironmentObject private var appState: AppState
    public var body: some View {
        List {
            Section {
                HStack {
                    Label(Localization.tr("dayEndTime"), systemImage: "moon.stars")
                    Spacer()
                    DatePicker("", selection: Binding(get: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        return formatter.date(from: vm.dayEndTime) ?? formatter.date(from: "00:00")!
                    }, set: { newVal in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        vm.dayEndTime = formatter.string(from: newVal)
                    }), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
                Text(Localization.tr("dayEndTimeDescription"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let hour = Int(vm.dayEndTime.split(separator: ":").first ?? "0"), hour > 12 {
                    Text("⚠️ \(Localization.tr("dayEndTimeWarning"))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Section {
                NavigationLink(destination: NarrativeUserProfileScreen()) {
                    Label(Localization.tr("myProfile"), systemImage: "person.text.rectangle")
                }
                NavigationLink(destination: LocationListScreen(vm: vm)) {
                    Label(Localization.tr("locationManagement"), systemImage: "map")
                }
                NavigationLink(destination: RelationshipManagementScreen()) {
                    Label(Localization.tr("peopleManagement"), systemImage: "person.2.fill")
                }
            }
            
            Section {
                Button(action: {}) {
                    Label(Localization.tr("exportData"), systemImage: "square.and.arrow.up")
                }
                .foregroundStyle(.primary)
                
                Button(action: {}) {
                    Label(Localization.tr("importData"), systemImage: "square.and.arrow.down")
                }
                .foregroundStyle(.primary)
            }
        }
        .listStyle(.insetGrouped)
        .tint(Colors.indigo)
        .navigationTitle(Localization.tr("dataMaintenance"))
        .id(appState.lang.rawValue)
    }
}
