import SwiftUI

/// The "Super Page" - A comprehensive history hub.
/// This view is designed to be the full-screen destination for browsing all history.
public struct GlobalHistoryView: View {
    @StateObject private var vm = HistoryViewModel()
    @EnvironmentObject private var appState: AppState
    var onClose: (() -> Void)? = nil
    
    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Custom Header to replace NavigationStack/Toolbar
            HStack {
                Text(Localization.tr("allMemories"))
                    .font(Typography.header)
                    .foregroundColor(Colors.slateText)
                Spacer()
                Button(action: { onClose?() }) {
                    Text(Localization.tr("done"))
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Colors.indigo)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Colors.background)
            
            ZStack {
                Colors.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Summary / Stats Section
                        HistoryStatsCard()
                        
                        // The Main List
                        ForEach(vm.timelines.filter { vm.searchText.isEmpty ? true : ($0.title?.contains(vm.searchText) ?? false) || $0.date.contains(vm.searchText) }, id: \.id) { timeline in
                            HistoryDayCard(timeline: timeline) {
                                appState.selectedDate = timeline.date
                                onClose?()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Subcomponents

struct HistoryStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(Typography.header)
                .foregroundColor(Colors.slateText)
            
            HStack(spacing: 16) {
                StatItem(label: "Days", value: "12") // Mock
                StatItem(label: "Entries", value: "48") // Mock
                StatItem(label: "Locations", value: "5") // Mock
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Colors.indigo)
            Text(label)
                .font(Typography.caption)
                .foregroundColor(Colors.slate500)
        }
    }
}

struct HistoryDayCard: View {
    let timeline: DailyTimeline
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Title (Optional)
                    if let title = timeline.title, !title.isEmpty {
                        Text(title)
                            .font(Typography.header)
                            .foregroundColor(Colors.slateText)
                            .lineLimit(1)
                    }
                    
                    // Date
                    Text(timeline.date)
                        .font(timeline.title == nil ? Typography.header : Typography.body)
                        .foregroundColor(timeline.title == nil ? Colors.slateText : Colors.slate500)
                    
                    // Tags
                    if !timeline.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(timeline.tags.prefix(3), id: \.self) { tag in
                                Text(Icons.categoryLabel(tag))
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(Colors.slate500)
                                    .cornerRadius(4)
                            }
                            if timeline.tags.count > 3 {
                                Text("+\(timeline.tags.count - 3)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Colors.slate500)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Colors.slate500)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}
