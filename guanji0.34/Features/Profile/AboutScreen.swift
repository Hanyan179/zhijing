import SwiftUI
import Foundation

public struct AboutScreen: View {
    public init() {}
    @EnvironmentObject private var appState: AppState
    public var body: some View {
        List {
            Section(Localization.tr("about")) {
                HStack {
                    Label(Localization.tr("appVersion"), systemImage: "number")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                    Spacer()
                    Text("0.34")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label(Localization.tr("buildNumber"), systemImage: "hammer")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                    Spacer()
                    Text("2025-12-02")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Text(Localization.tr("comingSoon"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listStyle(.insetGrouped)
        .tint(Colors.indigo)
        .navigationTitle(Localization.tr("about"))
        .id(appState.lang.rawValue)
    }
}
