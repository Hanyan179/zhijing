import SwiftUI
import Charts

/// Pie/donut chart for activity type distribution
/// Shows breakdown of user's tracked activities
struct ActivityPieChart: View {
    let data: [String: Int]  // ActivityType rawValue -> count
    
    private var sortedData: [(type: String, count: Int)] {
        data.map { (type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var totalCount: Int {
        data.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.ActivityDistribution"))
                .font(.headline)
            
            if !sortedData.isEmpty {
                HStack(alignment: .top, spacing: 20) {
                    // Donut chart (iOS 17+) or Bar chart fallback (iOS 16)
                    if #available(iOS 17.0, *) {
                        Chart(sortedData, id: \.type) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Activity", localizedActivityName(item.type)))
                        }
                        .frame(width: 140, height: 140)
                        .chartLegend(.hidden)
                    } else {
                        // Fallback to horizontal bar chart for iOS 16
                        Chart(sortedData.prefix(5), id: \.type) { item in
                            BarMark(
                                x: .value("Count", item.count),
                                y: .value("Activity", localizedActivityName(item.type))
                            )
                            .foregroundStyle(colorForActivity(item.type))
                        }
                        .frame(width: 140, height: 140)
                        .chartLegend(.hidden)
                    }
                    
                    // Legend with percentages
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sortedData.prefix(5), id: \.type) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForActivity(item.type))
                                    .frame(width: 8, height: 8)
                                
                                Text(localizedActivityName(item.type))
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(percentage(item.count))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if sortedData.count > 5 {
                            Text(Localization.tr("Insight.AndMore"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(Localization.tr("Insight.NoData"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .background(Colors.background)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func localizedActivityName(_ rawValue: String) -> String {
        guard let activityType = ActivityType(rawValue: rawValue) else {
            return rawValue
        }
        return Localization.tr(activityType.localizedKey)
    }
    
    private func colorForActivity(_ rawValue: String) -> Color {
        guard let activityType = ActivityType(rawValue: rawValue) else {
            return Colors.indigo
        }
        
        // Use different colors based on activity group
        switch activityType.group {
        case .competence:
            return Colors.blue
        case .identity:
            return Colors.orange
        case .social:
            return Colors.emerald
        }
    }
    
    private func percentage(_ count: Int) -> Int {
        guard totalCount > 0 else { return 0 }
        return Int(round(Double(count) / Double(totalCount) * 100))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Sample data with various activities
        ActivityPieChart(data: [
            "work": 15,
            "exercise": 10,
            "reading": 8,
            "date": 5,
            "gaming": 3,
            "shopping": 2
        ])
        
        // Empty data
        ActivityPieChart(data: [:])
    }
    .padding()
}
