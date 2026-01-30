import SwiftUI
import CoreLocation

public struct LocationBadge: View {
    public let location: LocationVO
    public var onClick: (() -> Void)?
    public var onLongPress: (() -> Void)?
    public var align: HorizontalAlignment
    public var showIcon: Bool
    public init(location: LocationVO, onClick: (() -> Void)? = nil, onLongPress: (() -> Void)? = nil, alignRight: Bool = false, showIcon: Bool = true) {
        self.location = location
        self.onClick = onClick
        self.onLongPress = onLongPress
        self.align = alignRight ? .trailing : .leading
        self.showIcon = showIcon
    }

    public var body: some View {
        Button(action: {
            // New logic: If raw/unmapped, click triggers edit directly
            if location.status == .raw {
                onClick?()
            }
        }) {
            HStack(spacing: 6) {
                if showIcon {
                    Image(systemName: location.icon ?? "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundColor(location.status == .raw ? Colors.indigo : colorFor(location.color))
                }
                
                // Show raw coordinates if raw status and display text is still placeholder-ish
                if location.status == .raw && location.displayText.hasPrefix("Location") {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(location.displayText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(String(format: "%.4f, %.4f", location.snapshot.lat, location.snapshot.lng))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(location.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(location.status == .raw ? Colors.indigo : Colors.slateText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(location.status == .raw ? Colors.indigo.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Colors.indigo, lineWidth: location.status == .raw ? 1 : 0)
            )
        }
        .simultaneousGesture(LongPressGesture().onEnded { _ in 
             if location.status == .raw && location.displayText.hasPrefix("Location") {
                // Try retry logic if it's still placeholder
                LocationService.shared.resolveAddress(location: CLLocation(latitude: location.snapshot.lat, longitude: location.snapshot.lng)) { _ in
                    // We rely on the repository update logic which might need to be triggered manually here or just rely on the user to use the naming sheet.
                }
            }
            // Mapped: Long press triggers
            if location.status == .mapped {
                onLongPress?()
            }
        })
        .disabled(false) // Always enable to allow gesture
    }
    
    private func colorFor(_ name: String?) -> Color {
        guard let n = name else { return Colors.slateText }
        switch n {
        case "indigo": return .indigo
        case "violet": return .purple
        case "rose": return .pink
        case "teal": return .teal
        default: return Colors.slateText
        }
    }
}
