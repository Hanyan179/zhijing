import Foundation
import Combine

/// Date range options for export
public enum DateRange {
    case last7Days
    case last30Days
    case last90Days
    case allTime
}

/// Exported data model
public struct ExportedData: Identifiable {
    public let id = UUID()
    public let dayId: String
    public let content: String
}

/// ViewModel for Data Export Screen
public class DataExportViewModel: ObservableObject {
    @Published public var selectedRange: DateRange = .last30Days
    @Published public var availableDates: [String] = []
    @Published public var isLoading = false
    @Published public var exportedData: ExportedData?
    @Published public var showError = false
    @Published public var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Watch for range changes
        $selectedRange
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadAvailableDates()
            }
            .store(in: &cancellables)
    }
    
    /// Load available dates based on selected range
    public func loadAvailableDates() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let dates = self.fetchAvailableDates()
            
            DispatchQueue.main.async {
                self.availableDates = dates
                self.isLoading = false
            }
        }
    }
    
    /// Export data for a specific day
    public func exportDay(_ dayId: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let content = DailyDataExporter.exportDay(dayId)
            
            DispatchQueue.main.async {
                self.exportedData = ExportedData(dayId: dayId, content: content)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchAvailableDates() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        
        // Determine date range
        let startDate: Date
        switch selectedRange {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: today) ?? today
        case .allTime:
            // Go back 1 year as a reasonable limit
            startDate = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        }
        
        // Collect all dates with data
        var datesWithData: [String] = []
        var currentDate = today
        
        while currentDate >= startDate {
            let dayId = DateUtilities.format(currentDate)
            
            // Check if this date has any data
            if hasDataForDate(dayId) {
                datesWithData.append(dayId)
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return datesWithData
    }
    
    private func hasDataForDate(_ dayId: String) -> Bool {
        // Check Timeline
        let timeline = TimelineRepository.shared.getDailyTimeline(for: dayId)
        if !timeline.items.isEmpty || timeline.title != nil || timeline.weather != nil {
            return true
        }
        
        // Check AI Conversations
        let conversations = AIConversationRepository.shared.getConversations(for: dayId)
        if !conversations.isEmpty {
            return true
        }
        
        // Check Questions
        let questions = QuestionRepository.shared.getAll().filter { $0.dayId == dayId }
        if !questions.isEmpty {
            return true
        }
        
        // Check Mind State
        let mindStates = MindStateRepository().load(for: dayId)
        if !mindStates.isEmpty {
            return true
        }
        
        // Check Daily Tracker
        if DailyTrackerRepository.shared.load(for: dayId) != nil {
            return true
        }
        
        return false
    }
}

