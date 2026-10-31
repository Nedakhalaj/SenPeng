import Foundation
import Observation

/// The logic of the stop search screen.
///
/// Loads SL's stop list once, then searches it on the device every time the
/// user types, so results appear instantly without network requests.
@MainActor
@Observable
final class StopSearchViewModel {

    /// What the user typed in the search field. Updates the results on every change.
    var query = "" {
        didSet { updateResults() }
    }

    /// The screen's state. When loaded, holds the stops that match `query`.
    private(set) var state: LoadState<[Site]> = .idle

    /// The prepared stop list, once loaded.
    private var index: SiteSearchIndex?

    /// Provides the stop list.
    private let repository: any SiteRepository

    /// Creates the view model.
    /// - Parameter repository: Provides SL's stop list.
    init(repository: any SiteRepository) {
        self.repository = repository
    }

    /// Loads the stop list, unless it's already loaded or loading.
    ///
    /// Called when the screen appears, and again by "Try again" after an error.
    func load() async {
        if index != nil {
            return
        }
        if case .loading = state {
            return
        }

        state = .loading
        do {
            let sites = try await repository.sites()
            index = await SiteSearchIndex.make(from: sites)
            updateResults()
        } catch {
            // A cancelled load (the user left the screen) isn't an error;
            // the next appearance simply starts again.
            if let message = error.userFacingError {
                state = .failed(message)
            } else {
                state = .idle
            }
        }
    }

    /// Searches the loaded list for the current query.
    private func updateResults() {
        guard let index else {
            return
        }
        state = .loaded(index.search(query))
    }
}
