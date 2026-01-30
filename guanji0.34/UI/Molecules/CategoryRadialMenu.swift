import SwiftUI

public struct CategoryRadialMenu: View {
    public let categories: [EntryCategory]
    public let onSelect: (EntryCategory) -> Void
    public var onEdit: (() -> Void)?
    public init(categories: [EntryCategory], onSelect: @escaping (EntryCategory) -> Void, onEdit: (() -> Void)? = nil) {
        self.categories = categories
        self.onSelect = onSelect
        self.onEdit = onEdit
    }
    private func icon(_ c: EntryCategory) -> String { Icons.categoryIconName(c) }
    private func label(_ c: EntryCategory) -> String { Icons.categoryLabel(c) }
    private func angle(for index: Int, count: Int) -> Double { (-Double.pi / 2.0) + (2.0 * Double.pi / Double(max(count, 1))) * Double(index) }
    public var body: some View {
        let size: CGFloat = 180
        let radius: CGFloat = 64
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().stroke(Color.white.opacity(0.6)))
                .overlay(Circle().stroke(Color.black.opacity(0.03)))
            if let onEdit = onEdit {
                Button(action: {
                    onEdit()
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }) {
                    ZStack { Circle().fill(Colors.slateLight); Image(systemName: "pencil").foregroundColor(Colors.slate600) }
                        .frame(width: 48, height: 48)
                }
                .position(x: size / 2.0, y: size / 2.0)
            }
            ForEach(Array(categories.enumerated()), id: \.offset) { idx, c in
                let a = angle(for: idx, count: categories.count)
                let x = cos(a) * radius
                let y = sin(a) * radius
                Button(action: {
                    onSelect(c)
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }) {
                    ZStack { Circle().fill(Color.white); Image(systemName: icon(c)).foregroundColor(Colors.slate600) }
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color(.systemGray5)))
                }
                .position(x: size / 2.0 + CGFloat(x), y: size / 2.0 + CGFloat(y))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .transition(.scale.combined(with: .opacity))
    }
}
