import CoreGraphics

/// Corner radius values, in points.
///
/// Elements inside a card use `Radius.card - padding`, so the corners
/// stay parallel (concentric) with the card's corners.
enum Radius {

    /// Cards, for example a departure or trip card.
    static let card: CGFloat = 24

    /// Small controls such as badges and text fields.
    static let control: CGFloat = 14
}
