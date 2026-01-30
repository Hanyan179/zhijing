import SwiftUI

public struct SceneHeader: View {
    public let scene: SceneGroup
    public let isEditing: Bool
    public var onEditLocation: (() -> Void)?
    
    public init(scene: SceneGroup, isEditing: Bool, onEditLocation: (() -> Void)? = nil) {
        self.scene = scene
        self.isEditing = isEditing
        self.onEditLocation = onEditLocation
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Location (Moved to front)
            LocationBadge(location: scene.location, onClick: onEditLocation, onLongPress: onEditLocation, showIcon: true)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Colors.indigo, lineWidth: isEditing ? 1.5 : 0)
                )

            Text("•")
                .foregroundColor(Colors.slate500)
                .font(.caption)

            // Time Range
            Text(scene.timeRange)
                .font(Typography.caption)
                .foregroundColor(Colors.slate500)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Colors.slateLight.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        // Vertical padding is handled by SceneBlock
    }
}
