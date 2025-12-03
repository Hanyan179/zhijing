import SwiftUI
import Foundation

public struct DataMaintenanceScreen: View {
    public init() {}
    @EnvironmentObject private var appState: AppState
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("dataMaintenance"))
            ListGroup {
                HStack { Image(systemName: "map").foregroundColor(Colors.systemGray); Text(Localization.tr("locationManagement")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                HStack { Image(systemName: "person.2").foregroundColor(Colors.systemGray); Text(Localization.tr("peopleManagement")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); Text(Localization.tr("comingSoon")).font(.system(size: 12)).foregroundColor(Colors.systemGray) }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                Button(action: {}) {
                    HStack { Image(systemName: "trash").foregroundColor(.red); Text(Localization.tr("clearCache")).font(.system(size: 14, weight: .medium)).foregroundColor(.red); Spacer(); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                }
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                Button(action: {}) {
                    HStack { Image(systemName: "arrow.clockwise").foregroundColor(Colors.systemGray); Text(Localization.tr("reindexData")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                }
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                Button(action: {}) {
                    HStack { Image(systemName: "square.and.arrow.up").foregroundColor(Colors.systemGray); Text(Localization.tr("exportData")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                }
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                Button(action: {}) {
                    HStack { Image(systemName: "square.and.arrow.down").foregroundColor(Colors.systemGray); Text(Localization.tr("importData")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText); Spacer(); Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.system(size: 12)) }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                }
            }
            Text(Localization.tr("comingSoon")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
        }
        .id(appState.lang.rawValue)
    }
}
