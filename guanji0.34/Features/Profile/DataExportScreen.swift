import SwiftUI
import Foundation

/// Data Export Screen - Export daily data by date
public struct DataExportScreen: View {
    @StateObject private var vm = DataExportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Export Options Section
                Section {
                    Picker(Localization.tr("Export.DateRange"), selection: $vm.selectedRange) {
                        Text(Localization.tr("Export.Range.Last7Days")).tag(DateRange.last7Days)
                        Text(Localization.tr("Export.Range.Last30Days")).tag(DateRange.last30Days)
                        Text(Localization.tr("Export.Range.Last90Days")).tag(DateRange.last90Days)
                        Text(Localization.tr("Export.Range.AllTime")).tag(DateRange.allTime)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(Localization.tr("Export.Options"))
                }
                
                // Date List Section
                Section {
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if vm.availableDates.isEmpty {
                        Text(Localization.tr("Export.NoData"))
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(vm.availableDates, id: \.self) { dayId in
                            DateExportRow(
                                dayId: dayId,
                                onExport: { vm.exportDay(dayId) }
                            )
                        }
                    }
                } header: {
                    Text(Localization.tr("Export.AvailableDates"))
                } footer: {
                    if !vm.availableDates.isEmpty {
                        Text(Localization.tr("Export.Footer"))
                            .font(.caption)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Localization.tr("Export.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("Action.Close")) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $vm.exportedData) { data in
                ExportShareSheet(exportData: data)
            }
            .alert(Localization.tr("Export.Error"), isPresented: $vm.showError) {
                Button(Localization.tr("Action.OK"), role: .cancel) {}
            } message: {
                if let error = vm.errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                vm.loadAvailableDates()
            }
        }
    }
}

/// Date Export Row - Single date item with export button
struct DateExportRow: View {
    let dayId: String
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDisplayDate(dayId))
                    .font(.body)
                Text(dayId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onExport) {
                Label(Localization.tr("Export.Action"), systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .tint(Colors.indigo)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDisplayDate(_ dayId: String) -> String {
        guard let date = DateUtilities.parse(dayId) else {
            return dayId
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// Export Share Sheet - UIActivityViewController wrapper
struct ExportShareSheet: UIViewControllerRepresentable {
    let exportData: ExportedData
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [exportData.content],
            applicationActivities: nil
        )
        
        // Suggest filename
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                print("Export completed for \(exportData.dayId)")
            }
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

