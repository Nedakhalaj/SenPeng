import SwiftUI

/// A neutral badge with the vehicle icon and line number, for example 🚇 14.
///
/// Deliberately not in SL's line colors, so the app doesn't copy SL's branding.
struct LineBadge: View {

    /// The line, for example "14".
    let line: String

    /// The kind of vehicle, which sets the icon.
    let mode: TransportMode

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: mode.symbolName)
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel(Text(mode.displayName))
            Text(line)
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppColor.textPrimary)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.s)
        .background(AppColor.separator, in: .rect(cornerRadius: Radius.control))
        // A line number must never split over two lines, also at the largest text sizes.
        .fixedSize()
    }
}

#Preview {
    VStack(spacing: Spacing.s) {
        LineBadge(line: "14", mode: .metro)
        LineBadge(line: "471", mode: .bus)
        LineBadge(line: "41", mode: .train)
        LineBadge(line: "82", mode: .ferry)
    }
    .padding(Spacing.l)
    .appBackground()
}
