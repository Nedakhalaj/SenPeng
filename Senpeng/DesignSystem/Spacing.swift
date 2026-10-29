import CoreGraphics

// Short T-shirt size names (xs, s, m, l) are a common design convention and
// read well at the call site (`Spacing.l`), so the short-name rule is off here.
// swiftlint:disable identifier_name

/// Fixed spacing values for padding and gaps, in points.
///
/// Views use only these values, so spacing stays consistent across the app.
enum Spacing {

    /// 4 pt. Tiny gaps, for example between an icon and its text.
    static let xs: CGFloat = 4

    /// 8 pt. Small gaps inside a component.
    static let s: CGFloat = 8

    /// 12 pt. Gap between cards.
    static let m: CGFloat = 12

    /// 16 pt. Card padding and screen side padding.
    static let l: CGFloat = 16

    /// 24 pt. Gap between sections.
    static let xl: CGFloat = 24

    /// 32 pt. Large gaps, for example around an empty state.
    static let xxl: CGFloat = 32
}
// swiftlint:enable identifier_name
