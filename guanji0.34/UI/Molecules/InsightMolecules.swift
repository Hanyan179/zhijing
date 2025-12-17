import SwiftUI

public struct StateAnalysisCard: View {
    @ObservedObject public var vm: InsightViewModel
    public init(vm: InsightViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("", selection: $vm.analysisMode) {
                    Text(NSLocalizedString("mood", comment: "")).tag("mood")
                    Text(NSLocalizedString("energy", comment: "")).tag("energy")
                }
                .pickerStyle(.segmented)
                Spacer()
                Text(NSLocalizedString("dominant", comment: "")).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
            .padding(.horizontal, 6)
            RingChart(items: vm.analysisMode == "mood" ? vm.chartItemsMood : vm.chartItemsEnergy, dominantLabel: vm.dominantLabel)
        }
        .modifier(Materials.prism())
    }
}

public struct RankingItemView: View {
    public let name: String
    public let count: Int
    public let percent: Int
    public init(name: String, count: Int, percent: Int) { self.name = name; self.count = count; self.percent = percent }
    public var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Colors.slateLight).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.system(size: 13, weight: .medium)).foregroundColor(Colors.slateText)
                ZStack(alignment: .leading) {
                    Capsule().fill(Colors.slateLight).frame(height: 6)
                    Capsule().fill(.indigo).frame(width: CGFloat(percent), height: 6)
                }
            }
            Spacer()
            Text("\(count)").font(.system(size: 12)).foregroundColor(Colors.systemGray)
        }
    }
}

public struct RankingListView: View {
    @ObservedObject public var vm: InsightViewModel
    public init(vm: InsightViewModel) { self.vm = vm }
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("", selection: $vm.rankingMode) {
                    Text(NSLocalizedString("people", comment: "")).tag("people")
                    Text(NSLocalizedString("location", comment: "")).tag("location")
                }
                .pickerStyle(.segmented)
                Spacer()
            }
            .padding(.horizontal, 6)
            VStack(spacing: 10) {
                ForEach(vm.rankingMode == "people" ? Array(vm.peopleRanking.prefix(5)) : Array(vm.locationRanking.prefix(5)), id: \.name) { item in
                    RankingItemView(name: item.name, count: item.count, percent: item.percent)
                }
            }
        }
        .modifier(Materials.prism())
    }
}

public struct KeywordsCloudView: View {
    public let words: [String]
    public init(words: [String]) { self.words = words }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Image(systemName: "magnifyingglass").foregroundColor(.black); Text(NSLocalizedString("recentFocus", comment: "")).font(.system(size: 15, weight: .semibold)).foregroundColor(.black) }
            Wrap(words: words)
        }
        .modifier(Materials.card())
    }

    struct Wrap: View {
        let words: [String]
        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(words, id: \.self) { w in
                    Text(w).font(.system(size: 12)).foregroundColor(Colors.slateText).padding(.horizontal, 8).padding(.vertical, 6).background(Color.white.opacity(0.6)).clipShape(Capsule())
                }
            }
        }
    }
}
