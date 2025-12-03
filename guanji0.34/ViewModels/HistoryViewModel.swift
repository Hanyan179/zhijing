import SwiftUI
import Combine

public final class HistoryViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public private(set) var previewDates: [String] = []
    public init() { generatePreviews() }
    public func generatePreviews() {
        previewDates = [ChronologyAnchor.TODAY_DATE, ChronologyAnchor.YESTERDAY_DATE, ChronologyAnchor.THREE_DAYS_AGO, ChronologyAnchor.ONE_YEAR_AGO_DATE, ChronologyAnchor.TWO_YEARS_AGO_DATE]
    }
}
