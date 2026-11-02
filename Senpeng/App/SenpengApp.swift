import SwiftUI

/// The entry point of the Senpeng app.
///
/// Creates the app's building blocks once, then the main window with the root navigation.
@main
struct SenpengApp: App {

    /// The app's network and storage, shared by all screens.
    private let container = AppContainer.forCurrentLaunch()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
