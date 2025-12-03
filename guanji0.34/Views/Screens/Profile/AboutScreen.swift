import SwiftUI
import Foundation

public struct AboutScreen: View {
    public init() {}
    @EnvironmentObject private var appState: AppState
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("about"))
        ListGroup {
            HStack {
                HStack(spacing: 12) { Image(systemName: "number").foregroundColor(Color(.systemGray)); Text(Localization.tr("appVersion")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                Spacer()
                Text("0.34").font(.system(size: 12)).foregroundColor(Colors.systemGray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

            HStack {
                HStack(spacing: 12) { Image(systemName: "hammer").foregroundColor(Color(.systemGray)); Text(Localization.tr("buildNumber")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                Spacer()
                Text("2025-12-02").font(.system(size: 12)).foregroundColor(Colors.systemGray)
            }
        }
        Text(Localization.tr("comingSoon")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
    }
    .id(appState.lang.rawValue)
}
}
