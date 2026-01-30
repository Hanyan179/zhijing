import SwiftUI

public struct CategoryPillBar: View {
    public let categories: [EntryCategory]
    public let onSelect: (EntryCategory) -> Void
    public var onEdit: (() -> Void)?
    public var dark: Bool
    public init(categories: [EntryCategory], onSelect: @escaping (EntryCategory) -> Void, onEdit: (() -> Void)? = nil, dark: Bool = false) {
        self.categories = categories
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.dark = dark
    }
    private func icon(_ c: EntryCategory) -> String { Icons.categoryIconName(c) }
    private var bgColor: Color { dark ? Colors.slatePrimary : Color.white }
    private var fgColor: Color { dark ? Color.white : Colors.slate600 }
    public var body: some View {
        HStack(spacing: 12) {
            if let onEdit = onEdit {
                RoundIconButton(systemName: "pencil", action: {
                    onEdit()
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                })
            }
            ForEach(categories, id: \.self) { c in
                RoundIconButton(systemName: icon(c), action: {
                    onSelect(c)
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                })
            }
        }
        .foregroundColor(fgColor)
        .padding(8)
        .background(bgColor.opacity(0.8))
        .clipShape(Capsule())
    }
}
