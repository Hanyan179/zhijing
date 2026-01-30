import SwiftUI

/// The specific history view for Timeline context.
/// Shows a list of days, but is designed to be a "sidebar" or "drawer" content.
public struct TimelineHistoryView: View {
    @StateObject private var vm = HistoryViewModel()
    @EnvironmentObject private var appState: AppState
    
    // Callback to trigger the transition to the Super Page
    var onExpandToSuperPage: () -> Void
    var onSelectDate: (() -> Void)?
    
    @State private var showDatePicker = false
    
    public init(onExpandToSuperPage: @escaping () -> Void, onSelectDate: (() -> Void)? = nil) {
        self.onExpandToSuperPage = onExpandToSuperPage
        self.onSelectDate = onSelectDate
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Title now shows "YYYY.MM"
                Text(formatYearMonth(vm.currentDisplayDate))
                    .font(Typography.header)
                    .foregroundColor(Colors.slateText)
                Spacer()
                // Replaced standard close button with "Collapse" text or cleaner icon if needed
                /*
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    // Trigger close
                }) {
                    Image(systemName: "chevron.left") // Use chevron instead of xmark for "Back/Close" feel
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                */
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Colors.systemGray)
                TextField(NSLocalizedString("searchMemory", comment: ""), text: $vm.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // List
            ScrollView {
                LazyVStack(spacing: 12) {
                    
                    ForEach(vm.timelines.filter { timeline in
                        // Filter out days with no data
                        guard !timeline.items.isEmpty else { return false }
                        // Apply search filter
                        if vm.searchText.isEmpty { return true }
                        return (timeline.title?.contains(vm.searchText) ?? false) || timeline.date.contains(vm.searchText)
                    }, id: \.id) { timeline in
                        VStack(alignment: .leading, spacing: 8) {
                            // Date & Status
                            HStack {
                                Text(timeline.date)
                                    .font(.caption)
                                    .foregroundColor(Colors.slate500)
                                Spacer()
                                
                                if timeline.date == DateUtilities.today {
                                    Text(NSLocalizedString("backToToday", comment: ""))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Colors.indigo)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Colors.indigo.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            // Title (or Placeholder) - Tappable
                            Button(action: { 
                                appState.selectedDate = timeline.date
                                onSelectDate?()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Show title if exists, otherwise show first text content
                                    Text(timeline.title ?? firstTextContent(from: timeline))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Colors.slateText)
                                        .lineLimit(1)
                                    
                                    // Tags (Icons) - Only show if tags exist
                                    if !timeline.tags.isEmpty {
                                        HStack(spacing: 8) {
                                            ForEach(timeline.tags.prefix(5), id: \.self) { tag in
                                                Image(systemName: Icons.categoryIconName(tag))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Colors.slate500)
                                            }
                                            if timeline.tags.count > 5 {
                                                Text("+\(timeline.tags.count - 5)")
                                                    .font(.caption2)
                                                    .foregroundColor(Colors.slate500)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Colors.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 4) // Added subtle horizontal padding for breathing room inside scroll
                    }
                }
                .padding(.horizontal, 16) // Reduced from 20 to align better with standard margins
                .padding(.bottom, 20)
            }
        }
        .background(Colors.background) // Slightly off-white background for card contrast
        // Swipe Right Gesture to Expand
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 { // Swipe Right
                        onExpandToSuperPage()
                    }
                }
        )
        .sheet(isPresented: $showDatePicker) {
            YearMonthPickerSheet(
                currentDate: vm.currentDisplayDate,
                minDate: vm.minDate,
                maxDate: vm.maxDate
            ) { targetDate in
                // Logic: Filter view model to this month
                vm.jumpToMonth(date: targetDate)
                
                // Note: We do NOT select a date immediately (onSelectDate is not called).
                // We just refresh the list. User must pick a day card to navigate.
            }
        }
    }
    
    private func formatYearMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM"
        return f.string(from: date)
    }
    
    /// Extract first text content from timeline items
    private func firstTextContent(from timeline: DailyTimeline) -> String {
        // Iterate through items to find first text content
        for item in timeline.items {
            let entries: [JournalEntry]
            switch item {
            case .scene(let scene):
                entries = scene.entries
            case .journey(let journey):
                entries = journey.entries
            }
            
            // Find first entry with text content
            for entry in entries {
                if let content = entry.content, !content.isEmpty {
                    return content
                }
            }
        }
        
        // Fallback if no content found
        return Localization.tr("noContent")
    }
}
