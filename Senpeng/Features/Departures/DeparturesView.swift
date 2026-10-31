import SwiftUI

/// The departures from one stop in the next hour, updated automatically.
///
/// Refreshes every 30 seconds while visible and the app is active, and on pull-to-refresh.
/// Tapping a departure opens the sheet for starting a trip on it. The sheet is passed in,
/// so this screen doesn't need to know what starting a trip requires.
struct DeparturesView<StartTrip: View>: View {

    /// The screen's logic and state.
    @State private var viewModel: DeparturesViewModel

    /// The departure the user tapped, which opens the sheet.
    @State private var selectedDeparture: Departure?

    /// Whether the app is active, so updates stop in the background.
    @Environment(\.scenePhase) private var scenePhase

    /// Creates the sheet for starting a trip on a departure.
    private let startTrip: (Departure) -> StartTrip

    /// Creates the screen.
    /// - Parameters:
    ///   - site: The stop whose departures are shown.
    ///   - repository: Provides the departures.
    ///   - startTrip: Creates the sheet for starting a trip on a departure.
    init(
        site: Site,
        repository: any DepartureRepository,
        @ViewBuilder startTrip: @escaping (Departure) -> StartTrip
    ) {
        _viewModel = State(initialValue: DeparturesViewModel(site: site, repository: repository))
        self.startTrip = startTrip
    }

    var body: some View {
        content
            .appBackground()
            .navigationTitle(viewModel.site.name)
            .navigationBarTitleDisplayMode(.inline)
            // Restarts when the app becomes active again, and stops when it leaves.
            .task(id: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                await viewModel.keepUpdated()
            }
            .sheet(item: $selectedDeparture) { departure in
                startTrip(departure)
            }
    }

    /// The main content for the current state.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading departures…")
        case .failed(let error):
            LoadErrorView(title: "Couldn't load departures", error: error) {
                await viewModel.refresh()
            }
        case .loaded(let departures) where departures.isEmpty:
            ContentUnavailableView(
                "No departures",
                systemImage: "clock",
                description: Text("No departures in the next hour.")
            )
        case .loaded(let departures):
            List(departures) { departure in
                Button {
                    selectedDeparture = departure
                } label: {
                    DepartureRow(departure: departure)
                }
                // Nobody can be on a cancelled departure.
                .disabled(departure.isCancelled)
                .accessibilityHint(Text("Choose where you get off"))
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

#Preview("Departures") {
    NavigationStack {
        DeparturesView(site: PreviewSiteRepository.sampleSites[0], repository: PreviewDepartureRepository()) { _ in
            EmptyView()
        }
    }
}

#Preview("Error") {
    NavigationStack {
        DeparturesView(
            site: PreviewSiteRepository.sampleSites[0],
            repository: PreviewDepartureRepository(result: .failure(.offline))
        ) { _ in
            EmptyView()
        }
    }
    .preferredColorScheme(.dark)
}
