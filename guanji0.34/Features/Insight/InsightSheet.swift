import SwiftUI

/// Insight Sheet - Three-Zone Layout
/// Zone 1: Overview (Always displayed)
/// Zone 2: Feature Usage (Conditionally displayed when hasAnyData)
/// Zone 3: Data Insight (Conditionally displayed when sufficient data)
public struct InsightSheet: View {
    @StateObject private var vm = InsightViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Colors.background
                    .ignoresSafeArea()
                
                if vm.isLoading {
                    // Loading indicator with Robot Avatar
                    VStack(spacing: 16) {
                        RobotAvatar(mood: .processing, size: 100)
                        
                        Text(Localization.tr("Insight.Loading"))
                            .font(.caption)
                            .foregroundColor(Colors.slate600)
                    }
                } else {
                    // Main content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Zone 1: Overview Section (Always displayed)
                            OverviewSection(stats: vm.overview)
                            
                            // Zone 2: Feature Usage Section (Conditionally displayed)
                            if vm.showZone2 {
                                FeatureUsageSection(stats: vm.featureUsage)
                            }
                            
                            // Zone 3: Data Insight Section (Conditionally displayed)
                            if vm.showZone3 {
                                DataInsightSection(
                                    stats: vm.dataInsight,
                                    showHourChart: vm.showHourChart,
                                    showActivityChart: vm.showActivityChart,
                                    showMoodChart: vm.showMoodChart,
                                    showLocationRank: vm.showLocationRank,
                                    showLoveRank: vm.showLoveRank
                                )
                            }
                            
                            // Footer: "洞察引擎" label
                            HStack {
                                Spacer()
                                Text(Localization.tr("Insight.Engine"))
                                    .font(Typography.fontEngraved)
                                    .foregroundColor(Colors.systemGray)
                            }
                            .padding(.top, 8)
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle(Localization.tr("Insight.Title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    InsightSheet()
}
