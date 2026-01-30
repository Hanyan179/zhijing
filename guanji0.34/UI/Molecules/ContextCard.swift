import SwiftUI

/// A minimal card displaying activity context summary
/// Tap to open detail sheet for editing
public struct ContextCard: View {
    let activity: ActivityType
    let context: ActivityContext
    let onTap: () -> Void
    
    public init(
        activity: ActivityType,
        context: ActivityContext,
        onTap: @escaping () -> Void
    ) {
        self.activity = activity
        self.context = context
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity icon
                Image(systemName: activity.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(Colors.indigo)
                    .frame(width: 32)
                
                // Activity name
                Text(Localization.tr(activity.localizedKey))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Current companion types
                if !context.companions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(context.companions.prefix(2), id: \.self) { companion in
                            Text(Localization.tr(companion.localizedKey))
                                .font(.caption)
                                .foregroundColor(Colors.slateText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        if context.companions.count > 2 {
                            Text("+\(context.companions.count - 2)")
                                .font(.caption)
                                .foregroundColor(Colors.slateText)
                        }
                    }
                }
                
                // Expand arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Colors.systemGray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// A list of context cards for all selected activities
public struct ContextCardList: View {
    let activities: [ActivityType]
    let contexts: [ActivityType: ActivityContext]
    let onSelectActivity: (ActivityType) -> Void
    
    public init(
        activities: [ActivityType],
        contexts: [ActivityType: ActivityContext],
        onSelectActivity: @escaping (ActivityType) -> Void
    ) {
        self.activities = activities
        self.contexts = contexts
        self.onSelectActivity = onSelectActivity
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ForEach(activities, id: \.self) { activity in
                let context = contexts[activity] ?? ActivityContext(
                    activityType: activity,
                    companions: activity.defaultCompanions
                )
                
                ContextCard(
                    activity: activity,
                    context: context
                ) {
                    onSelectActivity(activity)
                }
            }
        }
        .padding()
    }
}
