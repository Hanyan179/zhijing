import Foundation

/// Test the DailyDataExporter functionality
enum DailyDataExporterTests {
    
    /// Test exporting today's data
    static func testExportToday() {
        print("Testing Daily Data Export...")
        print("=" * 60)
        
        let today = DateUtilities.today
        let exported = DailyDataExporter.exportDay(today)
        
        print(exported)
        
        print("\n✅ Export test completed")
        print("Exported \(exported.count) characters")
    }
    
    /// Test exporting a specific date
    static func testExportSpecificDate(_ date: String) {
        print("Testing Daily Data Export for \(date)...")
        print("=" * 60)
        
        let exported = DailyDataExporter.exportDay(date)
        
        print(exported)
        
        print("\n✅ Export test completed")
        print("Exported \(exported.count) characters")
    }
    
    /// Run all tests
    static func runAll() {
        testExportToday()
        print("\n\n")
        
        // Test yesterday
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let yesterdayString = DateUtilities.format(yesterday)
            testExportSpecificDate(yesterdayString)
        }
    }
}

// Helper extension for string repetition
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
