import SwiftUI

/// The stop search screen: the user types a stop name and sees matching stops.
///
/// Shows a hint before typing, a loading state while the stop list downloads,
/// an error with "Try again", and "No results" when nothing matches.
struct StopSearchView: View {

    /// The screen's logic and state.
    @State private var viewModel: StopSearchViewModel

    /// Creates the screen.
    /// - Parameter repository: Provides SL's stop list.
    init(repository: any SiteRepository) {
        _viewModel = State(initialValue: StopSearchViewModel(repository: repository))
    }

    var body: some View {
        content
            .appBackground()
            .searchable(text: $viewModel.query, prompt: Text("Search for a stop"))
            .task { await viewModel.load() }
    }

    /// The main content for the current state.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading stops…")
        case .failed(let error):
            errorView(error)
        case .loaded(let sites):
            if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView(
                    "Find your stop",
                    systemImage: "magnifyingglass",
                    description: Text("Search for the stop where you get on.")
                )
            } else if sites.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                resultsList(sites)
            }
        }
    }

    /// The list of matching stops.
    private func resultsList(_ sites: [Site]) -> some View {
        List(sites) { site in
            SiteRow(site: site)
                .listRowBackground(AppColor.surface)
        }
        .scrollContentBackground(.hidden)
    }

    /// A calm error message with a button to try again.
    private func errorView(_ error: UserFacingError) -> some View {
        ContentUnavailableView {
            Label("Couldn't load stops", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.message)
        } actions: {
            Button("Try again") {
                Task { await viewModel.load() }
            }
            .primaryButtonStyle()
        }
    }
}

#Preview("Stops") {
    NavigationStack {
        StopSearchView(repository: PreviewSiteRepository())
            .navigationTitle("Now")
    }
}

#Preview("Error") {
    NavigationStack {
        StopSearchView(repository: PreviewSiteRepository(result: .failure(.offline)))
            .navigationTitle("Now")
    }
    .preferredColorScheme(.dark)
}
