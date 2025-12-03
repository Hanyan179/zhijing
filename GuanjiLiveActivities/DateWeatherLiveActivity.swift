import ActivityKit
import WidgetKit
import SwiftUI

struct DateWeatherLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DateWeatherAttributes.self) { context in
            HStack(spacing: 6) {
                Text(context.state.dateText).font(.system(size: 16, weight: .semibold))
                Image(systemName: context.state.symbolName)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Text(context.state.dateText).font(.system(size: 16, weight: .semibold))
                        Image(systemName: context.state.symbolName)
                    }
                }
            } compactLeading: {
                Text(context.state.dateText)
            } compactTrailing: {
                Image(systemName: context.state.symbolName)
            } minimal: {
                Image(systemName: context.state.symbolName)
            }
        }
    }
}
