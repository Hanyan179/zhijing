import SwiftUI

public struct OverviewCard: View {
    public let streak: Int
    public let totalDays: Int
    public let totalEntries: Int
    public init(streak: Int, totalDays: Int, totalEntries: Int) { self.streak = streak; self.totalDays = totalDays; self.totalEntries = totalEntries }
    public var body: some View {
        HStack {
            VStack { Image(systemName: "flame"); Text("\(streak)").font(.system(size: 18, weight: .bold, design: .monospaced)); Text(NSLocalizedString("streak", comment: "")).font(Typography.fontEngraved) }.frame(maxWidth: .infinity)
            Divider().frame(height: 48)
            VStack { Image(systemName: "calendar"); Text("\(totalDays)").font(.system(size: 18, weight: .bold, design: .monospaced)); Text(NSLocalizedString("days", comment: "")).font(Typography.fontEngraved) }.frame(maxWidth: .infinity)
            Divider().frame(height: 48)
            VStack { Image(systemName: "doc.text"); Text("\(totalEntries)").font(.system(size: 18, weight: .bold, design: .monospaced)); Text(NSLocalizedString("entries", comment: "")).font(Typography.fontEngraved) }.frame(maxWidth: .infinity)
        }
        .padding(16)
        .modifier(Materials.prism())
    }
}

public struct RingChartItem: Identifiable { public let id = UUID(); public let value: Double; public let color: Color }

public struct RingChart: View {
    public let items: [RingChartItem]
    public let dominantLabel: String
    public init(items: [RingChartItem], dominantLabel: String) { self.items = items; self.dominantLabel = dominantLabel }
    public var body: some View {
        ZStack {
            Circle().stroke(Colors.slateLight, lineWidth: 18)
            ringSegments
            Circle().fill(Colors.slateLight).frame(width: 140, height: 140)
            VStack { Text(NSLocalizedString("dominant", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray); Text(dominantLabel).font(.system(size: 15, weight: .bold)) }
        }
        .frame(width: 180, height: 180)
    }
    private var ringSegments: some View {
        let total = max(1, items.reduce(0) { $0 + $1.value })
        return ZStack {
            ForEach(0..<items.count, id: \.self) { idx in
                let prev = (0..<idx).reduce(0.0) { acc, j in acc + items[j].value }
                let start = prev / total
                let end = (prev + items[idx].value) / total
                Circle()
                    .trim(from: CGFloat(start), to: CGFloat(end))
                    .stroke(items[idx].color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

public struct HeatmapGrid: View {
    public let hourCounts: [Int]
    public init(hourCounts: [Int]) { self.hourCounts = hourCounts }
    public var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(0..<24, id: \.self) { idx in
                    let count = hourCounts.indices.contains(idx) ? hourCounts[idx] : 0
                    let maxCount = max(1, hourCounts.max() ?? 1)
                    let opacity = count > 0 ? (Double(count) / Double(maxCount)) * 0.9 + 0.1 : 0.05
                    Rectangle().fill(Colors.slatePrimary.opacity(opacity)).aspectRatio(1, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            HStack {
                Text(NSLocalizedString("am", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Spacer()
                Text(NSLocalizedString("pm", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Spacer()
                Text(NSLocalizedString("activityDensity", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
        }
        .padding(16)
        .modifier(Materials.prism())
    }
}
