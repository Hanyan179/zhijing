import Foundation

public enum DateUtilities {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()
    
    public static var today: String {
        let now = Date()
        let calendar = Calendar.current
        
        // Get user preference for Day End Time (Daily Cutoff)
        // Default is "00:00", meaning standard midnight transition.
        // If set to "04:00", then 3 AM counts as the previous day.
        let endTimeStr = UserDefaults.standard.string(forKey: "pref_day_end_time") ?? "00:00"
        let parts = endTimeStr.split(separator: ":").compactMap { Int($0) }
        
        if parts.count == 2 {
            let endHour = parts[0]
            let endMinute = parts[1]
            
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            
            // If current time is strictly before the cutoff time, it counts as the previous day.
            // We restrict this logic to early morning hours (00:00 - 12:00) to avoid ambiguity.
            // If user sets 22:00, we ignore it to prevent the "whole day is yesterday" bug.
            if endHour <= 12 {
                if currentHour < endHour || (currentHour == endHour && currentMinute < endMinute) {
                    if let prevDay = calendar.date(byAdding: .day, value: -1, to: now) {
                        return formatter.string(from: prevDay)
                    }
                }
            }
        }
        
        return formatter.string(from: now)
    }
    
    public static func format(_ date: Date) -> String {
        return formatter.string(from: date)
    }
    
    /// Alias for format(_:) for API consistency
    public static func formatDate(_ date: Date) -> String {
        return format(date)
    }
    
    public static func parse(_ dateString: String) -> Date? {
        return formatter.date(from: dateString)
    }
}
