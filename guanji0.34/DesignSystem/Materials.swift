import SwiftUI

public enum Materials {
    public static func prism() -> some ViewModifier { PrismModifier() }
    public static func glass() -> some ViewModifier { GlassModifier() }
    public static func card() -> some ViewModifier { CardModifier() }
}

struct PrismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.6)))
    }
}

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.03)))
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

