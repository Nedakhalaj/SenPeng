import SwiftUI

/// The departures from one stop in the next hour, updated automatically.
///
/// Refreshes every 30 seconds while visible and the app is active, and on pull-to-refresh.
struct DeparturesView: View {

    /// The screen's logic and state.
    @State private var viewModel: DeparturesViewModel

    /// Whether the app is active, so updates stop in the background.
    @Environment(\.scenePhase) private var scenePhase

    /// Creates the screen.
    /// - Parameters:
    ///   - site: The stop whose departures are shown.
    ///   - repository: Provides the departures.
    init(site: Site, repository: any DepartureRepository) {
        _viewModel = State(initialValue: DeparturesViewModel(site: site, repository: repository))
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
                DepartureRow(departure: departure)
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
        DeparturesView(site: PreviewSiteRepository.sampleSites[0], repository: PreviewDepartureRepository())
    }
}

#Preview("Error") {
    NavigationStack {
        DeparturesView(
            site: PreviewSiteRepository.sampleSites[0],
            repository: PreviewDepartureRepository(result: .failure(.offline))
        )
    }
    .preferredColorScheme(.dark)
}
