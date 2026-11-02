import SwiftUI

/// The app's color palette: calm neutral grays with one muted accent.
///
/// Every color has a light and a dark version in the asset catalog.
/// Views use only these colors, never hex values or system colors like `.red`.
enum AppColor {

    /// Page background. Warm off-white in light mode, soft near-black in dark mode.
    static let background = Color(ColorAsset.background)

    /// Solid surfaces such as inputs and list rows where glass doesn't fit.
    static let surface = Color(ColorAsset.surface)

    /// Titles and body text.
    static let textPrimary = Color(ColorAsset.textPrimary)

    /// Supporting text such as times and captions.
    static let textSecondary = Color(ColorAsset.textSecondary)

    /// Dividers and outlines.
    static let separator = Color(ColorAsset.separator)

    /// Main buttons, links and selected states. Use sparingly.
    static let accent = Color(ColorAsset.accent)

    /// Text on the accent color, for example on the main button. It's light on the dark
    /// accent in light mode, and dark on the light accent in dark mode, so it stays readable.
    static let onAccent = Color(ColorAsset.onAccent)

    /// Positive status, for example "You may get money back".
    static let success = Color(ColorAsset.success)

    /// Attention status, for example a delay or a deadline coming soon.
    static let warning = Color(ColorAsset.warning)

    /// Errors and passed deadlines.
    static let danger = Color(ColorAsset.danger)

    /// Neutral status, for example "On time" or "Not eligible".
    static let neutralStatus = Color(ColorAsset.neutralStatus)
}

private extension Color {

    /// Creates a color from the asset catalog.
    /// - Parameter asset: The name of the color asset.
    init(_ asset: ColorAsset) {
        self.init(asset.rawValue)
    }
}
