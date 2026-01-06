import SwiftUI
import Foundation

public struct DataMaintenanceScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    public init(vm: ProfileViewModel) { self.vm = vm }
    @EnvironmentObject private var appState: AppState
    @State private var showExportSheet = false
    
    public var body: some View {
        List {
            Section {
                HStack {
                    Label {
                        Text(Localization.tr("dayEndTime"))
                    } icon: {
                        Image(systemName: "moon.stars")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Colors.indigo)
                    }
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
                Button(action: { showExportSheet = true }) {
                    Label {
                        Text(Localization.tr("exportData"))
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Colors.indigo)
                    }
                }
                .foregroundStyle(.primary)
                
                Button(action: {}) {
                    Label {
                        Text(Localization.tr("importData"))
                    } icon: {
                        Image(systemName: "square.and.arrow.down")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Colors.indigo)
                    }
                }
                .foregroundStyle(.primary)
            }
            
            Section(header: Text("AI 知识提取 (调试)")) {
                NavigationLink(destination: DailyExportView()) {
                    Label {
                        Text("AI养料导出/导入")
                    } icon: {
                        Image(systemName: "brain.head.profile")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Colors.indigo)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tint(Colors.indigo)
        .navigationTitle(Localization.tr("dataMaintenance"))
        .id(appState.lang.rawValue)
        .sheet(isPresented: $showExportSheet) {
            DataExportScreen()
        }
    }
}
