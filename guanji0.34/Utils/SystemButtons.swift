import SwiftUI

public struct SystemIconButton: View {
    public enum Kind { case back, next, save }
    public let kind: Kind
    public let accent: Color?
    public let action: () -> Void
    public init(kind: Kind, accent: Color? = nil, action: @escaping () -> Void) { self.kind = kind; self.accent = accent; self.action = action }
    private var symbolName: String {
        switch kind {
        case .back: return "chevron.left"
        case .next: return "chevron.right.circle.fill"
        case .save: return "checkmark.circle.fill"
        }
    }
    public var body: some View {
        Button(action: action) {
            let img = Image(systemName: symbolName).font(.system(size: 18, weight: .semibold))
            Group {
                if #available(iOS 17.0, *) {
                    img.foregroundStyle(accent ?? Colors.text)
                } else {
                    img.foregroundColor(accent ?? Colors.text)
                }
            }
            .frame(width: 40, height: 40)
            .background(.regularMaterial, in: Circle())
            .overlay(
                Circle().stroke(Color.black.opacity(0.05), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GrabberHandle: View {
    var body: some View {
        Capsule()
            .fill(Colors.slateLight)
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }
}
