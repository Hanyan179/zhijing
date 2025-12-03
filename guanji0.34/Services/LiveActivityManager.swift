import Foundation
import ActivityKit

public enum LiveActivityManager {
    public static func start(dateText: String, weatherSymbolName: String) {
        guard DynamicIslandSupport.hasDynamicIsland() else { return }
        if #available(iOS 16.1, *) {
            if Activity<DateWeatherAttributes>.activities.isEmpty {
                let attributes = DateWeatherAttributes()
                let state = DateWeatherAttributes.ContentState(dateText: dateText, symbolName: weatherSymbolName)
                _ = try? Activity<DateWeatherAttributes>.request(attributes: attributes, contentState: state)
            } else {
                update(dateText: dateText, weatherSymbolName: weatherSymbolName)
            }
        }
    }

    public static func update(dateText: String, weatherSymbolName: String) {
        if #available(iOS 16.1, *) {
            let state = DateWeatherAttributes.ContentState(dateText: dateText, symbolName: weatherSymbolName)
            for a in Activity<DateWeatherAttributes>.activities {
                Task { await a.update(using: state) }
            }
        }
    }

    public static func endAll() {
        if #available(iOS 16.2, *) {
            for a in Activity<DateWeatherAttributes>.activities {
                Task { await a.end(dismissalPolicy: .immediate) }
            }
        } else if #available(iOS 16.1, *) {
            for a in Activity<DateWeatherAttributes>.activities {
                Task { await a.end() }
            }
        }
    }
}
