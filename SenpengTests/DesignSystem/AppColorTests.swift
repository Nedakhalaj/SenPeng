import Testing
import UIKit
@testable import Senpeng

/// Checks that the color palette exists and is readable in light and dark mode.
@Suite("App colors")
struct AppColorTests {

    /// Light and dark mode, to test every color in both.
    private static let appearances: [UIUserInterfaceStyle] = [.light, .dark]

    /// Every color named in `ColorAsset` must exist in the asset catalog.
    @Test("Color asset exists", arguments: ColorAsset.allCases)
    func colorAssetExists(_ asset: ColorAsset) {
        #expect(UIColor(named: asset.rawValue) != nil)
    }

    /// Body text needs a contrast of at least 4.5:1 (WCAG AA).
    @Test(
        "Text is readable on its background",
        arguments: [ColorAsset.textPrimary, .textSecondary, .accent],
        [ColorAsset.background, .surface]
    )
    func textIsReadable(_ text: ColorAsset, on background: ColorAsset) throws {
        for style in Self.appearances {
            let ratio = try contrastRatio(text, background, style: style)
            #expect(ratio >= 4.5, "\(text) on \(background) in \(style == .dark ? "dark" : "light") mode: \(ratio)")
        }
    }

    /// The main button's text must be readable on the accent color, in both modes.
    @Test("Text on the main button is readable")
    func onAccentIsReadable() throws {
        for style in Self.appearances {
            let ratio = try contrastRatio(.onAccent, .accent, style: style)
            #expect(ratio >= 4.5, "On accent in \(style == .dark ? "dark" : "light") mode: \(ratio)")
        }
    }

    /// Status icons need a contrast of at least 3:1 (WCAG AA for graphics).
    @Test(
        "Status color is visible on the background",
        arguments: [ColorAsset.success, .warning, .danger, .neutralStatus]
    )
    func statusColorIsVisible(_ status: ColorAsset) throws {
        for style in Self.appearances {
            let ratio = try contrastRatio(status, .background, style: style)
            #expect(ratio >= 3, "\(status) in \(style == .dark ? "dark" : "light") mode: \(ratio)")
        }
    }

    /// Calculates the WCAG contrast ratio between two colors.
    /// - Parameters:
    ///   - first: One of the two colors.
    ///   - second: The other color.
    ///   - style: Light or dark mode.
    /// - Returns: A ratio from 1 (no contrast) to 21 (black on white).
    private func contrastRatio(_ first: ColorAsset, _ second: ColorAsset, style: UIUserInterfaceStyle) throws -> Double {
        let firstLuminance = try relativeLuminance(of: first, style: style)
        let secondLuminance = try relativeLuminance(of: second, style: style)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculates how bright a color looks to the human eye, using the WCAG formula.
    /// - Parameters:
    ///   - asset: The color to measure.
    ///   - style: Light or dark mode.
    /// - Returns: A value from 0 (black) to 1 (white).
    private func relativeLuminance(of asset: ColorAsset, style: UIUserInterfaceStyle) throws -> Double {
        let color = try #require(UIColor(named: asset.rawValue))
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Converts a gamma-encoded sRGB channel to linear light (WCAG 2.x definition).
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.039_28 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
