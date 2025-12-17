import SwiftUI

/// Summary card for displaying Daily Tracker record in Timeline
public struct DailyTrackerSummaryCard: View {
    let record: DailyTrackerRecord
    let onTap: () -> Void
    
    public init(
        record: DailyTrackerRecord,
        onTap: @escaping () -> Void
    ) {
        self.record = record
        self.onTap = onTap
    }
    
    private var bodyEnergyLevel: BodyEnergyLevel {
        BodyEnergyLevel.from(record.bodyEnergy)
    }
    
    private var moodWeatherLevel: MindValence {
        // Use 0-100 continuous scale mapping (same as StatusSliderCard)
        MindValence.from(record.moodWeather)
    }
    
    /// Convert MindValence color string to SwiftUI Color
    private var moodWeatherColor: Color {
        switch moodWeatherLevel {
        case .veryUnpleasant, .unpleasant:
            return Color(red: 0.90, green: 0.50, blue: 0.55)
        case .slightlyUnpleasant:
            return Color(red: 0.94, green: 0.60, blue: 0.64)
        case .neutral:
            return Colors.systemGray
        case .slightlyPleasant:
            return Color(red: 0.38, green: 0.74, blue: 0.52)
        case .pleasant, .veryPleasant:
            return Color(red: 0.32, green: 0.68, blue: 0.50)
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with status icons
                HStack(spacing: 16) {
                    // Body Energy
                    HStack(spacing: 6) {
                        Image(systemName: bodyEnergyLevel.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(bodyEnergyLevel.color)
                        Text(Localization.tr(bodyEnergyLevel.titleKey))
                            .font(.subheadline)
                            .foregroundColor(bodyEnergyLevel.color)
                    }
                    
                    // Mood Weather
                    HStack(spacing: 6) {
                        Image(systemName: moodWeatherLevel.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(moodWeatherColor)
                        Text(Localization.tr(moodWeatherLevel.titleKey))
                            .font(.subheadline)
                            .foregroundColor(moodWeatherColor)
                    }
                    
                    Spacer()
                    
                    // Completed indicator
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Colors.teal)
                }
                
                // Activities
                if !record.activities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(record.activities) { context in
                                ActivityMiniChip(activity: context.activityType)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// Mini chip for displaying activity in summary
struct ActivityMiniChip: View {
    let activity: ActivityType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: activity.iconName)
                .font(.system(size: 12))
            Text(Localization.tr(activity.localizedKey))
                .font(.caption)
        }
        .foregroundColor(Colors.slateText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Preview Support

#if DEBUG
extension DailyTrackerSummaryCard {
    static var preview: some View {
        DailyTrackerSummaryCard(
            record: DailyTrackerRecord(
                date: DateUtilities.today,
                bodyEnergy: 65,      // 0-100 scale (65 = fresh)
                moodWeather: 75,     // 0-100 scale (75 = pleasant)
                activities: [
                    ActivityContext(activityType: .work, companions: [.alone]),
                    ActivityContext(activityType: .exercise, companions: [.friends]),
                    ActivityContext(activityType: .gaming, companions: [.alone])
                ]
            )
        ) {
            print("Tapped")
        }
        .padding()
    }
}
#endif
