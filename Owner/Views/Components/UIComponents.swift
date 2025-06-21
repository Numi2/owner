import SwiftUI

// MARK: - Glass Card Modifier
/// A reusable modifier that applies a frosted glass background, rounded corners, and a soft drop shadow.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.15), radius: shadowRadius, x: 0, y: 4)
    }
}

extension View {
    /// Quickly wraps any view in a modern glass-style card.
    func glassCard(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 10) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// MARK: - Scale Button Style
/// Adds a subtle spring-based scale animation when a button is pressed.
struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Gradient Helpers
extension LinearGradient {
    /// A convenience gradient used throughout the app for primary accents.
    static let primaryAccent = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}