import SwiftUI

extension View {

    /// Styles a button as the screen's main action.
    ///
    /// Prominent Liquid Glass on iOS 26 and later, a filled button before.
    /// Each screen should have at most one main action.
    ///
    /// - Returns: The button with the main action style.
    @ViewBuilder
    func primaryButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
                .controlSize(.large)
        } else {
            buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    /// Styles a button as a secondary action.
    ///
    /// Regular Liquid Glass on iOS 26 and later, a bordered button before.
    ///
    /// - Returns: The button with the secondary action style.
    @ViewBuilder
    func secondaryButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
                .controlSize(.large)
        } else {
            buttonStyle(.bordered)
                .controlSize(.large)
        }
    }
}
