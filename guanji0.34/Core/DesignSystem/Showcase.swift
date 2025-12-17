import SwiftUI

public struct ShowcaseItem<Content: View>: View {
    public let label: String
    public let content: Content
    public init(label: String, @ViewBuilder content: () -> Content) { self.label = label; self.content = content() }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(Colors.systemGray)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .modifier(Materials.card())
    }
}
