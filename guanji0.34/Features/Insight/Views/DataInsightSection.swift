import SwiftUI
import Charts

/// Zone 3: Data Insight Section - Conditionally displayed based on thresholds
/// Shows data visualizations when sufficient data is available
struct DataInsightSection: View {
    let stats: DataInsightStats
    let showHourChart: Bool
    let showActivityChart: Bool
    let showMoodChart: Bool
    let showLocationRank: Bool
    let showLoveRank: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.tr("Insight.DataInsight"))
                .font(.headline)
                .foregroundColor(Colors.text)
                .padding(.horizontal)
            
            // Hour Distribution Chart
            if showHourChart {
                HourDistributionChartView(hourDistribution: stats.hourDistribution)
            }
            
            // Activity Distribution Chart
            if showActivityChart {
                ActivityDistributionChartView(activityDistribution: stats.activityDistribution)
            }
            
            // Mood Trend Chart
            if showMoodChart {
                MoodTrendChartView(moodTrend: stats.moodTrend)
            }
            
            // Top Locations Ranking
            if showLocationRank {
                TopLocationsRankingView(topLocations: stats.topLocations)
            }
            
            // Love Sources Ranking
            if showLoveRank {
                LoveSourcesRankingView(loveSources: stats.loveSources)
            }
        }
    }
}

// MARK: - Hour Distribution Chart

/// 24-hour bar chart showing entry distribution throughout the day
private struct HourDistributionChartView: View {
    let hourDistribution: [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.HourDistribution"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Colors.text)
            
            Chart {
                ForEach(0..<24, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", hour),
                        y: .value("Count", hourDistribution[hour])
                    )
                    .foregroundStyle(Colors.indigo.gradient)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Activity Distribution Chart

/// Pie/donut chart showing activity type distribution
private struct ActivityDistributionChartView: View {
    let activityDistribution: [String: Int]
    
    // Color mapping for activity types
    private let activityColors: [String: Color] = [
        "work": Colors.blue,
        "exercise": Colors.emerald,
        "social": Colors.pink,
        "leisure": Colors.amber,
        "learning": Colors.violet,
        "rest": Colors.teal
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.ActivityDistribution"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Colors.text)
            
            if #available(iOS 17.0, *) {
                Chart {
                    ForEach(Array(activityDistribution.keys.sorted()), id: \.self) { activity in
                        SectorMark(
                            angle: .value("Count", activityDistribution[activity] ?? 0),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(activityColors[activity] ?? Colors.slate500)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, spacing: 8)
            } else {
                // Fallback to horizontal bar chart for iOS 16
                Chart {
                    ForEach(Array(activityDistribution.keys.sorted()), id: \.self) { activity in
                        BarMark(
                            x: .value("Count", activityDistribution[activity] ?? 0),
                            y: .value("Activity", Localization.tr("Activity.\(activity.capitalized)"))
                        )
                        .foregroundStyle(activityColors[activity] ?? Colors.slate500)
                    }
                }
                .frame(height: 200)
            }
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(activityDistribution.keys.sorted()), id: \.self) { activity in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(activityColors[activity] ?? Colors.slate500)
                            .frame(width: 8, height: 8)
                        
                        Text(Localization.tr("Activity.\(activity.capitalized)"))
                            .font(.caption)
                            .foregroundColor(Colors.slate600)
                        
                        Spacer()
                        
                        Text("\(activityDistribution[activity] ?? 0)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Colors.text)
                    }
                }
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Mood Trend Chart

/// Line chart showing mood (valence) trend over time
private struct MoodTrendChartView: View {
    let moodTrend: [(date: String, value: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.MoodTrend"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Colors.text)
            
            Chart {
                ForEach(Array(moodTrend.enumerated()), id: \.offset) { index, dataPoint in
                    LineMark(
                        x: .value("Date", index),
                        y: .value("Mood", dataPoint.value)
                    )
                    .foregroundStyle(Colors.rose.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", index),
                        y: .value("Mood", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Colors.rose.opacity(0.3), Colors.rose.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let index = value.as(Int.self),
                           index >= 0 && index < moodTrend.count {
                            // Show abbreviated date
                            let dateStr = moodTrend[index].date
                            let components = dateStr.split(separator: ".")
                            if components.count >= 2 {
                                Text("\(components[1])/\(components[2])")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYScale(domain: -5...5)
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Top Locations Ranking

/// Ranking list showing most visited locations
private struct TopLocationsRankingView: View {
    let topLocations: [(name: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.TopLocations"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Colors.text)
            
            VStack(spacing: 8) {
                ForEach(Array(topLocations.prefix(5).enumerated()), id: \.offset) { index, location in
                    RankingRow(
                        rank: index + 1,
                        name: location.name,
                        count: location.count,
                        icon: "mappin.circle.fill",
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

// MARK: - Love Sources Ranking

/// Ranking list showing love log sources
private struct LoveSourcesRankingView: View {
    let loveSources: [(name: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.LoveSources"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Colors.text)
            
            VStack(spacing: 8) {
                ForEach(Array(loveSources.prefix(5).enumerated()), id: \.offset) { index, source in
                    RankingRow(
                        rank: index + 1,
                        name: source.name,
                        count: source.count,
                        icon: "heart.fill",
                        color: Colors.pink
                    )
                }
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Ranking Row Component

/// Reusable ranking row component
private struct RankingRow: View {
    let rank: Int
    let name: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(rankColor)
                .clipShape(Circle())
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            // Name
            Text(name)
                .font(.body)
                .foregroundColor(Colors.text)
                .lineLimit(1)
            
            Spacer()
            
            // Count
            Text("\(count)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Colors.slate600)
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Colors.amber
        case 2: return Colors.slate500
        case 3: return Colors.orange
        default: return Colors.slate600
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Full data
            DataInsightSection(
                stats: DataInsightStats(
                    hourDistribution: [2, 1, 0, 0, 0, 1, 3, 5, 8, 12, 15, 18, 20, 16, 14, 10, 8, 6, 5, 4, 3, 2, 1, 1],
                    activityDistribution: ["work": 25, "exercise": 15, "social": 20, "leisure": 18, "learning": 12, "rest": 10],
                    moodTrend: [
                        ("2024.12.01", 3),
                        ("2024.12.03", 2),
                        ("2024.12.05", 4),
                        ("2024.12.07", 1),
                        ("2024.12.09", 3),
                        ("2024.12.11", 5),
                        ("2024.12.13", 2),
                        ("2024.12.15", 4)
                    ],
                    topLocations: [
                        ("Home", 45),
                        ("Office", 32),
                        ("Gym", 18),
                        ("Coffee Shop", 12),
                        ("Park", 8)
                    ],
                    loveSources: [
                        ("Mom", 25),
                        ("Sarah", 18),
                        ("Alex", 15),
                        ("Friend", 10),
                        ("Partner", 8)
                    ]
                ),
                showHourChart: true,
                showActivityChart: true,
                showMoodChart: true,
                showLocationRank: true,
                showLoveRank: true
            )
            
            // Partial data
            DataInsightSection(
                stats: DataInsightStats(
                    hourDistribution: [1, 0, 0, 0, 0, 0, 2, 3, 5, 8, 10, 12, 15, 10, 8, 5, 3, 2, 1, 0, 0, 0, 0, 0],
                    activityDistribution: [:],
                    moodTrend: [],
                    topLocations: [("Home", 10), ("Office", 5), ("Gym", 3)],
                    loveSources: []
                ),
                showHourChart: true,
                showActivityChart: false,
                showMoodChart: false,
                showLocationRank: true,
                showLoveRank: false
            )
        }
        .padding()
    }
    .background(Colors.background)
}
