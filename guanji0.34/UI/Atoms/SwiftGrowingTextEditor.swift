import SwiftUI

public struct SwiftGrowingTextEditor: View {
    @Binding public var text: String
    @State private var measuredHeight: CGFloat = 36
    public init(text: Binding<String>) { self._text = text }
    public var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .font(.system(size: 16))
                .frame(minHeight: measuredHeight, maxHeight: min(measuredHeight, 160))
                .scrollDisabled(true)
                .padding(.horizontal, 6)
            Text(text.isEmpty ? "" : (text + " "))
                .font(.system(size: 16))
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .opacity(0)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { measuredHeight = max(36, geo.size.height) }
                            .onChange(of: text) { _ in measuredHeight = max(36, geo.size.height) }
                    }
                )
        }
    }
}
