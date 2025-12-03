import SwiftUI
import Combine

public final class AppState: ObservableObject {
    @Published public var selectedDate: String = ChronologyAnchor.TODAY_DATE
    @Published public var focusEntryId: String? = nil
    @Published public var lang: Lang = Localization.current
    public init() {}
}
