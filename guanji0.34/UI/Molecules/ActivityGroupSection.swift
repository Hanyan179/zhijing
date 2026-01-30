import SwiftUI

/// A section displaying activities for a specific group
public struct ActivityGroupSection: View {
    let group: ActivityGroup
    let selectedActivities: Set<ActivityType>
    let onToggle: (ActivityType) -> Void
    
    public init(
        group: ActivityGroup,
        selectedActivities: Set<ActivityType>,
        onToggle: @escaping (ActivityType) -> Void
    ) {
        self.group = group
        self.selectedActivities = selectedActivities
        self.onToggle = onToggle
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group title
            Text(Localization.tr(group.localizedKey))
                .font(.subheadline)
                .foregroundColor(Colors.slateText)
                .textCase(.uppercase)
            
            // Activity grid
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: 10)],
                spacing: 10
            ) {
                ForEach(group.activities) { activity in
                    CompactActivityChip(
                        activity: activity,
                        isSelected: selectedActivities.contains(activity)
                    ) {
                        onToggle(activity)
                    }
                }
            }
        }
    }
}

/// A complete activity selection view with all three groups
public struct ActivitySelectionView: View {
    @Binding var selectedActivities: Set<ActivityType>
    let onToggle: (ActivityType) -> Void
    
    public init(
        selectedActivities: Binding<Set<ActivityType>>,
        onToggle: @escaping (ActivityType) -> Void
    ) {
        self._selectedActivities = selectedActivities
        self.onToggle = onToggle
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Group A: Competence & Habits
            ActivityGroupSection(
                group: .competence,
                selectedActivities: selectedActivities,
                onToggle: onToggle
            )
            
            // Group B: Identity & Personality
            ActivityGroupSection(
                group: .identity,
                selectedActivities: selectedActivities,
                onToggle: onToggle
            )
            
            // Group C: Social & Relations
            ActivityGroupSection(
                group: .social,
                selectedActivities: selectedActivities,
                onToggle: onToggle
            )
        }
        .padding()
    }
}
