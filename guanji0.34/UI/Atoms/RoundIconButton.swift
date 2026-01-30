import SwiftUI

public struct RoundIconView: View {
    public let systemName: String
    public let accent: Color?
    public init(systemName: String, accent: Color? = nil) {
        self.systemName = systemName
        self.accent = accent
    }
    public var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                Image(systemName: systemName).font(.system(size: 18, weight: .semibold)).foregroundStyle(accent ?? Colors.text)
            } else {
                Image(systemName: systemName).font(.system(size: 18, weight: .semibold)).foregroundColor(accent ?? Colors.text)
            }
        }
        .frame(width: 40, height: 40)
        .background(.regularMaterial, in: Circle())
        .overlay(
            Circle().stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
    }
}

public struct RoundIconButton: View {
    public let systemName: String
    public let accent: Color?
    public let action: () -> Void
    public init(systemName: String, accent: Color? = nil, action: @escaping () -> Void) { 
        self.systemName = systemName
        self.accent = accent
        self.action = action 
    }
    public var body: some View {
        Button(action: action) {
            RoundIconView(systemName: systemName, accent: accent)
        }
        .buttonStyle(.plain)
    }
}
