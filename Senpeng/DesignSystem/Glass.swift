import SwiftUI

extension View {

    /// Gives the view the standard card look.
    ///
    /// Uses Liquid Glass on iOS 26 and later, and a frosted material on older
    /// versions. Feature views use this instead of calling `glassEffect` directly,
    /// so every card looks the same and the fallback lives in one place.
    ///
    /// - Parameters:
    ///   - cornerRadius: The card's corner radius.
    ///   - interactive: Whether the glass reacts to touch. Use `true` for tappable cards.
    ///   - tint: An optional status color, applied very lightly. Most cards have no tint.
    /// - Returns: The view with a glass card background.
    @ViewBuilder
    func glassCard(
        cornerRadius: CGFloat = Radius.card,
        interactive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        if #available(iOS 26, *) {
            glassEffect(
                .regular.tint(tint?.opacity(0.15)).interactive(interactive),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }
}

/// Groups glass elements that sit close together.
///
/// On iOS 26 and later, glass inside a group blends together and renders
/// faster. On older versions it just shows the content.
struct GlassGroup<Content: View>: View {

    /// The space at which neighboring glass shapes start to blend.
    private let spacing: CGFloat

    /// The glass elements in the group.
    private let content: Content

    /// Creates a glass group.
    /// - Parameters:
    ///   - spacing: The space at which neighboring glass shapes start to blend.
    ///   - content: The glass elements in the group.
    init(spacing: CGFloat = Spacing.m, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
