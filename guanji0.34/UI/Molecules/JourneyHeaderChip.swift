import SwiftUI

public struct JourneyHeaderChip: View {
    public let mode: TransportMode
    public let destination: LocationVO
    public var onTapDestination: (() -> Void)?
    public var onLongPressDestination: (() -> Void)?
    public let durationText: String
    public init(mode: TransportMode, destination: LocationVO, durationText: String, onTapDestination: (() -> Void)? = nil, onLongPressDestination: (() -> Void)? = nil) {
        self.mode = mode
        self.destination = destination
        self.durationText = durationText
        self.onTapDestination = onTapDestination
        self.onLongPressDestination = onLongPressDestination
    }
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: Icons.transportIconName(mode))
                .foregroundColor(Colors.slate500)
            Text("•")
                .foregroundColor(Colors.slate500)
            LocationBadge(location: destination, onClick: {
                // Prevent interaction if still moving
                if destination.displayText != "Moving..." {
                    onTapDestination?()
                }
            }, onLongPress: onLongPressDestination, showIcon: false)
            Text("•")
                .foregroundColor(Colors.slate500)
            Text(durationText)
                .font(Typography.caption)
                .foregroundColor(Colors.slate600)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Colors.slateLight)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
