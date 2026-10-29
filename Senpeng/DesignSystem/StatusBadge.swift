import SwiftUI

/// A small label that shows a status with an icon, text and a soft colored background.
///
/// Example: a green check with "You may get money back" on a trip card.
struct StatusBadge: View {

    /// The text of the badge, from the String Catalog.
    private let title: LocalizedStringKey

    /// The color and default icon of the badge.
    private let style: StatusStyle

    /// The SF Symbol shown before the text.
    private let systemImage: String

    /// Creates a status badge.
    /// - Parameters:
    ///   - title: The text of the badge.
    ///   - style: The status style, which sets the color.
    ///   - systemImage: An SF Symbol to use instead of the style's default icon.
    init(_ title: LocalizedStringKey, style: StatusStyle, systemImage: String? = nil) {
        self.title = title
        self.style = style
        self.systemImage = systemImage ?? style.defaultSymbol
    }

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(AppColor.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(style.color)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.s)
        // A light tint keeps the badge calm; the icon and text carry the meaning.
        .background(style.color.opacity(0.15), in: .capsule)
    }
}

#Preview("Light") {
    VStack(alignment: .leading, spacing: Spacing.s) {
        StatusBadge("Coming soon", style: .success)
        StatusBadge("Coming soon", style: .warning)
        StatusBadge("Coming soon", style: .danger)
        StatusBadge("Coming soon", style: .neutral)
    }
    .padding(Spacing.l)
    .appBackground()
}

#Preview("Dark") {
    VStack(alignment: .leading, spacing: Spacing.s) {
        StatusBadge("Coming soon", style: .success)
        StatusBadge("Coming soon", style: .warning)
        StatusBadge("Coming soon", style: .danger)
        StatusBadge("Coming soon", style: .neutral)
    }
    .padding(Spacing.l)
    .appBackground()
    .preferredColorScheme(.dark)
}
