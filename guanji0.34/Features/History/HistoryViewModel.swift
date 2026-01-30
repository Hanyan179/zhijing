import SwiftUI
import Combine

public final class HistoryViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public private(set) var timelines: [DailyTimeline] = []
    @Published public private(set) var currentDisplayDate: Date = Date()
    
    // Store all data internally
    private var allTimelines: [DailyTimeline] = []
    
    // Range of available data
    public var minDate: Date?
    public var maxDate: Date?
    
    public init() { 
        fetchTimelines() 
    }
    
    public func fetchTimelines() {
        // Fetch real timeline data from Repository
        self.allTimelines = TimelineRepository.shared.getAllTimelines()
        
        // Calculate ranges
        if let first = allTimelines.min(by: { $0.date < $1.date }),
           let last = allTimelines.max(by: { $0.date < $1.date }) {
            self.minDate = DateUtilities.parse(first.date)
            self.maxDate = DateUtilities.parse(last.date)
        }
        
        // Initial load: Show current month
        filterData(for: currentDisplayDate)
    }
    
    public func jumpToMonth(date: Date) {
        self.currentDisplayDate = date
        filterData(for: date)
    }
    
    public var hasEarlierData: Bool {
        guard let min = minDate else { return false }
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: currentDisplayDate)
        let minComponents = calendar.dateComponents([.year, .month], from: min)
        
        // If current display month is strictly after min data month, we have earlier data
        if let cYear = currentComponents.year, let cMonth = currentComponents.month,
           let mYear = minComponents.year, let mMonth = minComponents.month {
            if cYear > mYear { return true }
            if cYear == mYear && cMonth > mMonth { return true }
        }
        return false
    }
    
    private func filterData(for date: Date) {
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month], from: date)
        
        // 1. Filter by Month
        let filtered = allTimelines.filter { timeline in
            guard let d = DateUtilities.parse(timeline.date) else { return false }
            let c = calendar.dateComponents([.year, .month], from: d)
            return c.year == targetComponents.year && c.month == targetComponents.month
        }
        
        // 2. Sort
        // Logic:
        // - If viewing "Current Month" (or future?): Descending (New -> Old) "从大到小"
        // - If viewing "Past Month": Ascending (Old -> New) "从小到大"
        
        let isCurrentMonth = calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        
        if isCurrentMonth {
            // Descending
            self.timelines = filtered.sorted(by: { $0.date > $1.date })
        } else {
            // Ascending
            self.timelines = filtered.sorted(by: { $0.date < $1.date })
        }
    }
}
