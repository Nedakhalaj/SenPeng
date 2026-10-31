import SwiftUI

/// The top-level navigation of the app: three tabs, as defined in the design rules.
///
/// Each tab shows a placeholder until its feature is built. The system `TabView`
/// gets Liquid Glass automatically on iOS 26 and later. While the user is on a trip,
/// a small glass bar above the tabs shows it, on every tab.
struct RootView: View {

    /// The app's building blocks, passed on to each tab's screen.
    private let container: AppContainer

    /// Follows the trip the user is on.
    @State private var activeTrip: ActiveTripViewModel

    /// Whether the current trip's details are showing.
    @State private var isShowingTrip = false

    /// Whether the app is active, so live updates stop in the background.
    @Environment(\.scenePhase) private var scenePhase

    /// Creates the root navigation.
    /// - Parameter container: The app's building blocks.
    init(container: AppContainer) {
        self.container = container
        _activeTrip = State(initialValue: ActiveTripViewModel(
            tripRepository: container.tripRepository,
            arrivalRepository: container.arrivalRepository
        ))
    }

    var body: some View {
        tabs
            .tint(AppColor.accent)
            // Restarts when the app becomes active again, and stops when it leaves.
            .task(id: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                await activeTrip.keepUpdated()
            }
            .sheet(isPresented: $isShowingTrip) {
                ActiveTripView(viewModel: activeTrip)
            }
    }

    /// The three tabs.
    private var tabs: some View {
        TabView {
            NavigationStack {
                StopSearchView(repository: container.siteRepository)
                    .navigationTitle("Now")
                    .navigationDestination(for: Site.self) { site in
                        DeparturesView(site: site, repository: container.departureRepository) { departure in
                            StartTripView(viewModel: StartTripViewModel(
                                departure: departure,
                                origin: site,
                                siteRepository: container.siteRepository,
                                arrivalRepository: container.arrivalRepository,
                                tripRepository: container.tripRepository
                            )) {
                                Task { await activeTrip.refresh() }
                            }
                        }
                    }
            }
            .safeAreaInset(edge: .bottom) { tripBar }
            .tabItem { Label("Now", systemImage: "tram.fill") }

            NavigationStack {
                ComingSoonView()
                    .navigationTitle("My trips")
            }
            .safeAreaInset(edge: .bottom) { tripBar }
            .tabItem { Label("My trips", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                ComingSoonView()
                    .navigationTitle("Settings")
            }
            .safeAreaInset(edge: .bottom) { tripBar }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }

    /// The glass bar for the current trip, or nothing without a trip.
    @ViewBuilder
    private var tripBar: some View {
        switch activeTrip.status {
        case .none:
            EmptyView()
        case .following(let trip, let estimate):
            tripBar(trip: trip, minutesLate: estimate?.expectedMinutesLate)
        case .arrived(let trip):
            tripBar(trip: trip, minutesLate: trip.minutesLate)
        }
    }

    /// The glass bar for a trip, placed with the standard side padding.
    private func tripBar(trip: Trip, minutesLate: Int?) -> some View {
        ActiveTripBar(trip: trip, minutesLate: minutesLate) {
            isShowingTrip = true
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
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
