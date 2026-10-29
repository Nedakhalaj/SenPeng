import SwiftUI

extension View {

    /// Fills the screen behind the view with the app's calm page background.
    ///
    /// The color also extends under the status bar and tab bar, so glass
    /// elements always sit on the same neutral color.
    ///
    /// - Returns: The view on the app background.
    func appBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
    }
}
