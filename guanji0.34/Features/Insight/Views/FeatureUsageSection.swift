import SwiftUI

/// Zone 2: Feature Usage Section - Conditionally displayed
/// Shows feature usage statistics when count > 0
struct FeatureUsageSection: View {
    let stats: FeatureUsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.FeatureUsage"))
                .font(.headline)
                .foregroundColor(Colors.text)
            
            VStack(spacing: 8) {
                // AI Conversation
                if stats.aiConversations > 0 {
                    FeatureRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: Localization.tr("Insight.AIConversation"),
                        value: String(format: Localization.tr("Insight.AIConversationValue"), stats.aiConversations, stats.aiMessages),
                        color: Colors.indigo
                    )
                }
                
                // Daily Tracker
                if stats.trackerDays > 0 {
                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        title: Localization.tr("Insight.DailyTracker"),
                        value: String(format: Localization.tr("Insight.DailyTrackerValue"), stats.trackerDays),
                        color: Colors.emerald
                    )
                }
                
                // Mind State
                if stats.mindRecords > 0 {
                    FeatureRow(
                        icon: "heart.fill",
                        title: Localization.tr("Insight.MindState"),
                        value: String(format: Localization.tr("Insight.MindStateValue"), stats.mindRecords),
                        color: Colors.rose
                    )
                }
                
                // Time Capsule
                if stats.capsuleTotal > 0 {
                    FeatureRow(
                        icon: "clock.fill",
                        title: Localization.tr("Insight.TimeCapsule"),
                        value: String(format: Localization.tr("Insight.TimeCapsuleValue"), stats.capsuleTotal, stats.capsulePending),
                        color: Colors.amber
                    )
                }
                
                // Love Log
                if stats.loveLogCount > 0 {
                    FeatureRow(
                        icon: "heart.circle.fill",
                        title: Localization.tr("Insight.LoveLog"),
                        value: String(format: Localization.tr("Insight.LoveLogValue"), stats.loveLogCount),
                        color: Colors.pink
                    )
                }
                
                // Relationships
                if stats.relationshipCount > 0 {
                    FeatureRow(
                        icon: "person.2.fill",
                        title: Localization.tr("Insight.Relationships"),
                        value: String(format: Localization.tr("Insight.RelationshipsValue"), stats.relationshipCount),
                        color: Colors.teal
                    )
                }
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

/// Individual feature row with icon, title, and value
private struct FeatureRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            // Title
            Text(title)
                .font(.body)
                .foregroundColor(Colors.text)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.body)
                .foregroundColor(Colors.slate600)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Full data
        FeatureUsageSection(stats: FeatureUsageStats(
            aiConversations: 15,
            aiMessages: 87,
            trackerDays: 23,
            mindRecords: 12,
            capsuleTotal: 8,
            capsulePending: 3,
            loveLogCount: 25,
            relationshipCount: 5
        ))
        
        // Partial data
        FeatureUsageSection(stats: FeatureUsageStats(
            aiConversations: 5,
            aiMessages: 20,
            trackerDays: 0,
            mindRecords: 3,
            capsuleTotal: 0,
            capsulePending: 0,
            loveLogCount: 0,
            relationshipCount: 2
        ))
        
        // Empty data (should not be shown in real usage)
        FeatureUsageSection(stats: FeatureUsageStats.empty)
    }
    .padding()
    .background(Colors.background)
}
