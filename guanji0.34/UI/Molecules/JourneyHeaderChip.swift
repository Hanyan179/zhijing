import SwiftUI

public struct JourneyHeaderChip: View {
    public let mode: TransportMode
    public let destination: LocationVO
    public var onTapDestination: (() -> Void)?
    public var onLongPressDestination: (() -> Void)?
    
    public init(mode: TransportMode, destination: LocationVO, onTapDestination: (() -> Void)? = nil, onLongPressDestination: (() -> Void)? = nil) {
        self.mode = mode
        self.destination = destination
        self.onTapDestination = onTapDestination
        self.onLongPressDestination = onLongPressDestination
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: Icons.transportIconName(mode))
                .foregroundColor(Colors.slate500)
            Text("→")
                .foregroundColor(Colors.slate500)
            LocationBadge(location: destination, onClick: {
                // Prevent interaction if still moving
                if destination.displayText != "Moving..." {
                    onTapDestination?()
                }
            }, onLongPress: onLongPressDestination, showIcon: true)
        }
    }
}
