import SwiftUI

public struct PermissionLocationSheet: View {
    public var onGrant: () -> Void
    public var onOpenSettings: () -> Void
    public init(onGrant: @escaping () -> Void, onOpenSettings: @escaping () -> Void) { self.onGrant = onGrant; self.onOpenSettings = onOpenSettings }
    public var body: some View {
        VStack(spacing: 12) {
            Text(Localization.tr("privacyTitle")).font(Typography.header).foregroundColor(Colors.slateText)
            HStack(spacing: 8) {
                Image(systemName: "location").foregroundColor(Colors.systemGray)
                Text(Localization.tr("permLocationDesc")).font(Typography.body).foregroundColor(Colors.slateText)
            }
            HStack(spacing: 12) {
                Button(action: onGrant) { Text(Localization.tr("grantAccess")).font(Typography.body).foregroundColor(Colors.slateText) }
                    .padding(.vertical, 8).padding(.horizontal, 12).background(Colors.cardBackground).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5)))
                Button(action: onOpenSettings) { Text(Localization.tr("openSettings")).font(Typography.body).foregroundColor(Colors.slateText) }
                    .padding(.vertical, 8).padding(.horizontal, 12).background(Colors.cardBackground).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5)))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

