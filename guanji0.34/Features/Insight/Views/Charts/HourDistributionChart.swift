import SwiftUI
import Charts

/// 24-hour distribution bar chart for journal entries
/// Shows when user tends to write entries throughout the day
struct HourDistributionChart: View {
    let data: [Int]  // 24 values [0-23] representing entry count per hour
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("Insight.HourDistribution"))
                .font(.headline)
            
            Chart {
                ForEach(0..<24, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", hour),
                        y: .value("Count", data[hour])
                    )
                    .foregroundStyle(Colors.indigo.gradient)
                }
            }
            .frame(height: 200)
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
        .background(Colors.background)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Sample data with peak hours
        HourDistributionChart(data: [
            0, 0, 0, 0, 0, 1,  // 0-5
            2, 3, 5, 8, 6, 4,  // 6-11
            3, 2, 4, 6, 8, 10, // 12-17
            12, 15, 18, 14, 8, 3 // 18-23
        ])
        
        // Empty data
        HourDistributionChart(data: Array(repeating: 0, count: 24))
    }
    .padding()
}
