import SwiftUI

public struct EditHeaderBar: View {
    public let onCancel: () -> Void
    public let onDone: () -> Void
    public init(onCancel: @escaping () -> Void, onDone: @escaping () -> Void) { self.onCancel = onCancel; self.onDone = onDone }
    public var body: some View {
        HStack {
            RoundIconButton(systemName: "chevron.left", accent: nil, action: onCancel)
            Spacer()
            RoundIconButton(systemName: "checkmark", accent: Colors.emerald, action: onDone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .modifier(Materials.glass())
    }
}
