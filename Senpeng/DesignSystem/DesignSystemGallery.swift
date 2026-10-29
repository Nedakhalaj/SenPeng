#if DEBUG
import SwiftUI

/// A preview-only screen that shows every part of the design system together.
///
/// Open this file in Xcode and look at the canvas to check colors, cards,
/// buttons and badges in light and dark mode. It isn't included in release builds,
/// so its texts are not translated.
struct DesignSystemGallery: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                colorsSection
                cardsSection
                buttonsSection
            }
            .padding(Spacing.l)
        }
        .appBackground()
    }

    /// Every palette color as a swatch with its name.
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("Colors")
            ForEach(ColorAsset.allCases, id: \.self) { asset in
                HStack(spacing: Spacing.m) {
                    RoundedRectangle(cornerRadius: Radius.control)
                        .fill(Color(asset.rawValue))
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.control)
                                .stroke(AppColor.separator)
                        }
                    Text(verbatim: asset.rawValue)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    /// Glass cards: a plain one and a tinted, tappable one.
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("Cards")
            GlassGroup {
                VStack(spacing: Spacing.m) {
                    sampleCard(title: "Line 14 to Mörby centrum", detail: "Departs 08:12 · 4 min late")
                        .glassCard()
                    sampleCard(title: "Slussen → T-Centralen", detail: "Arrived 23 min late")
                        .glassCard(interactive: true, tint: AppColor.success)
                }
            }
        }
    }

    /// The main and secondary button styles.
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("Buttons")
            Button {} label: {
                Text(verbatim: "I'm on this train")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()

            Button {} label: {
                Text(verbatim: "Pick another stop")
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
        }
    }

    /// A section heading.
    private func sectionTitle(_ title: String) -> some View {
        Text(verbatim: title)
            .font(.headline)
            .foregroundStyle(AppColor.textSecondary)
    }

    /// Example card content with a title, detail line and status badges.
    private func sampleCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(verbatim: title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(verbatim: detail)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(AppColor.textSecondary)
            HStack(spacing: Spacing.s) {
                ForEach(StatusStyle.allCases, id: \.self) { style in
                    Image(systemName: style.defaultSymbol)
                        .foregroundStyle(style.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
    }
}

#Preview("Light") {
    DesignSystemGallery()
}

#Preview("Dark") {
    DesignSystemGallery()
        .preferredColorScheme(.dark)
}
#endif
