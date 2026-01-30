import SwiftUI

/// A selectable capsule-shaped chip button
public struct SelectableChip: View {
    let text: String
    let icon: String?
    let isSelected: Bool
    let accent: Color
    let action: () -> Void
    
    public init(
        text: String,
        icon: String? = nil,
        isSelected: Bool,
        accent: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.accent = accent
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(text)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? accent : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A compact version of SelectableChip for activity display
public struct CompactActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    public init(
        activity: ActivityType,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.activity = activity
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: activity.iconName)
                    .font(.system(size: 14))
                Text(Localization.tr(activity.localizedKey))
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Colors.indigo : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A chip for displaying companion type
public struct CompanionChip: View {
    let companion: CompanionType
    let isSelected: Bool
    let action: () -> Void
    
    public init(
        companion: CompanionType,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.companion = companion
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: companion.iconName)
                    .font(.system(size: 12))
                Text(Localization.tr(companion.localizedKey))
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Colors.indigo : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
