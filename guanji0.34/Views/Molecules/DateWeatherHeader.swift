import SwiftUI

public struct DateWeatherHeader: View {
    public let dateText: String
    public init(dateText: String) { self.dateText = dateText }
    public var body: some View {
        HStack(spacing: 8) {
            Text(dateText).font(.system(size: 18, weight: .semibold)).foregroundColor(Colors.slateText)
            Image(systemName: "cloud.drizzle").foregroundColor(Colors.systemGray)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }
}
