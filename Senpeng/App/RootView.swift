import SwiftUI

/// The top-level navigation of the app: three tabs, as defined in the design rules.
///
/// Each tab shows a placeholder until its feature is built. The system `TabView`
/// gets Liquid Glass automatically on iOS 26 and later.
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ComingSoonView()
                    .navigationTitle("Now")
            }
            .tabItem { Label("Now", systemImage: "tram.fill") }

            NavigationStack {
                ComingSoonView()
                    .navigationTitle("My trips")
            }
            .tabItem { Label("My trips", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                ComingSoonView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

/// Temporary content for tabs whose feature isn't built yet.
private struct ComingSoonView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming soon",
            systemImage: "hammer",
            description: Text("This part of Senpeng is being built.")
        )
    }
}

#Preview("Light") {
    RootView()
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}
