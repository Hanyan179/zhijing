import SwiftUI

/// A chip for displaying activity tags (user-created only)
public struct TagInputChip: View {
    let tag: ActivityTag
    let isSelected: Bool
    let action: () -> Void
    
    public init(
        tag: ActivityTag,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.tag = tag
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                // Star indicator for user-created tags
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : Colors.amber)
                
                Text(tag.text)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : Colors.slateDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Colors.indigo : Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A simple text-based tag chip
public struct SimpleTagChip: View {
    let text: String
    let isSelected: Bool
    let showStar: Bool
    let action: () -> Void
    
    public init(
        text: String,
        isSelected: Bool,
        showStar: Bool = true,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.isSelected = isSelected
        self.showStar = showStar
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if showStar {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white : Colors.amber)
                }
                
                Text(text)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : Colors.slateDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Colors.indigo : Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Add new tag button
public struct AddTagButton: View {
    let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                Text(Localization.tr("save_as_tag"))
                    .font(.subheadline)
            }
            .foregroundColor(Colors.indigo)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Colors.indigo.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
