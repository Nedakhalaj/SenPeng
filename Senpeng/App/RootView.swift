import SwiftUI

/// The top-level navigation of the app: three tabs, as defined in the design rules.
///
/// Each tab shows a placeholder until its feature is built. The system `TabView`
/// gets Liquid Glass automatically on iOS 26 and later.
struct RootView: View {

    /// The app's building blocks, passed on to each tab's screen.
    let container: AppContainer

    var body: some View {
        TabView {
            NavigationStack {
                StopSearchView(repository: container.siteRepository)
                    .navigationTitle("Now")
                    .navigationDestination(for: Site.self) { site in
                        DeparturesView(site: site, repository: container.departureRepository)
                    }
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
        .tint(AppColor.accent)
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
        .appBackground()
    }
}

#Preview("Light") {
    RootView(container: .preview)
}

#Preview("Dark") {
    RootView(container: .preview)
        .preferredColorScheme(.dark)
}
