import SwiftUI

public enum Materials {
    public static func prism() -> some ViewModifier { PrismModifier() }
    public static func glass() -> some ViewModifier { GlassModifier() }
    public static func card() -> some ViewModifier { CardModifier() }
    public static func mindCard() -> some ViewModifier { MindCardModifier() }
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

struct MindCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                    RoundedRectangle(cornerRadius: 28).stroke(Color.black.opacity(0.04), lineWidth: 0.8)
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}
