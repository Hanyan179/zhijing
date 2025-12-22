import SwiftUI
import Charts

/// Line chart for mood trend over time
/// Shows valence value changes from MindStateRecord
struct MoodTrendChart: View {
    let data: [(date: String, value: Int)]  // Sorted by date, value is valenceValue
    
    private var displayData: [(date: Date, value: Int)] {
        data.compactMap { item in
            guard let date = parseDate(item.date) else { return nil }
            return (date: date, value: item.value)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.MoodTrend"))
                .font(.headline)
            
            if !displayData.isEmpty {
                Chart(displayData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Mood", item.value)
                    )
                    .foregroundStyle(Colors.rose.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Mood", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Colors.rose.opacity(0.3), Colors.rose.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Mood", item.value)
                    )
                    .foregroundStyle(Colors.rose)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, displayData.count / 5))) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartYScale(domain: -3...3)
                
                // Legend
                HStack(spacing: 16) {
                    legendItem(label: Localization.tr("Insight.MoodPositive"), color: .green)
                    legendItem(label: Localization.tr("Insight.MoodNeutral"), color: .gray)
                    legendItem(label: Localization.tr("Insight.MoodNegative"), color: .red)
                }
                .font(.caption2)
                .padding(.top, 8)
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
    
    // MARK: - Helper Views
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Sample data with mood fluctuations
        MoodTrendChart(data: [
            (date: "2024.12.01", value: 1),
            (date: "2024.12.03", value: 2),
            (date: "2024.12.05", value: 0),
            (date: "2024.12.07", value: -1),
            (date: "2024.12.09", value: 1),
            (date: "2024.12.11", value: 3),
            (date: "2024.12.13", value: 2),
            (date: "2024.12.15", value: 0),
            (date: "2024.12.17", value: 1)
        ])
        
        // Empty data
        MoodTrendChart(data: [])
    }
    .padding()
}
