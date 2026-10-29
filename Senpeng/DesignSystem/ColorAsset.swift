import Foundation

/// The names of the color assets in `Assets.xcassets`.
///
/// Keeping the names in one enum means a typo can't slip into the code,
/// and tests can check that every asset really exists.
enum ColorAsset: String, CaseIterable {
    case background
    case surface
    case textPrimary
    case textSecondary
    case separator
    // Xcode's default name for the app tint color.
    case accent = "AccentColor"
    case success
    case warning
    case danger
    case neutralStatus
}
