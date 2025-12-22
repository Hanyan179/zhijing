import SwiftUI

/// Zone 1: Overview Section - Always displayed
/// Shows core recording statistics: streak, total days, total entries, total words
struct OverviewSection: View {
    let stats: OverviewStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.Overview"))
                .font(.headline)
                .foregroundColor(Colors.text)
            
            HStack(spacing: 16) {
                OverviewStatItem(
                    icon: "flame.fill",
                    value: stats.streak,
                    label: Localization.tr("Insight.Streak"),
                    color: Colors.orange
                )
                
                OverviewStatItem(
                    icon: "calendar",
                    value: stats.totalDays,
                    label: Localization.tr("Insight.TotalDays"),
                    color: Colors.blue
                )
                
                OverviewStatItem(
                    icon: "doc.text",
                    value: stats.totalEntries,
                    label: Localization.tr("Insight.TotalEntries"),
                    color: Colors.emerald
                )
                
                OverviewStatItem(
                    icon: "character",
                    value: stats.totalWords,
                    label: Localization.tr("Insight.TotalWords"),
                    color: Colors.violet
                )
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

/// Individual stat item with icon, value, and label for Overview section
private struct OverviewStatItem: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Colors.text)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Colors.slate600)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OverviewSection(stats: OverviewStats(
            streak: 7,
            totalDays: 45,
            totalEntries: 123,
            totalWords: 15678
        ))
        
        OverviewSection(stats: OverviewStats.empty)
    }
    .padding()
    .background(Colors.background)
}
