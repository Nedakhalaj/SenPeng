import Foundation
import Observation
import os

/// The logic of the departures screen for one stop.
///
/// Loads the departures and refreshes them regularly while the screen is visible.
/// If a refresh fails, the last departures stay on screen instead of an error.
@MainActor
@Observable
final class DeparturesViewModel {

    /// The stop whose departures are shown.
    let site: Site

    /// The screen's state. When loaded, holds the departures, soonest first.
    private(set) var state: LoadState<[Departure]> = .idle

    /// Provides the departures.
    private let repository: any DepartureRepository

    /// How long to wait between automatic refreshes.
    private let refreshInterval: Duration

    /// Creates the view model.
    /// - Parameters:
    ///   - site: The stop whose departures are shown.
    ///   - repository: Provides the departures.
    ///   - refreshInterval: Time between automatic refreshes. 30 seconds by default,
    ///     the shortest allowed by the project rules, to respect SL's rate limits.
    init(site: Site, repository: any DepartureRepository, refreshInterval: Duration = .seconds(30)) {
        self.site = site
        self.repository = repository
        self.refreshInterval = refreshInterval
    }

    /// Refreshes the departures now, then again every `refreshInterval`, until cancelled.
    ///
    /// The view runs this in `.task`, so it stops automatically when the screen
    /// disappears or the app goes to the background.
    func keepUpdated() async {
        while !Task.isCancelled {
            await refresh()
            do {
                try await Task.sleep(for: refreshInterval)
            } catch {
                return
            }
        }
    }

    /// Loads the latest departures once. Used by pull-to-refresh and "Try again".
    func refresh() async {
        switch state {
        case .idle, .failed:
            state = .loading
        case .loading, .loaded:
            break
        }

        do {
            state = .loaded(try await repository.departures(siteID: site.id))
        } catch {
            handle(error)
        }
    }

    /// Updates the state after a failed load.
    private func handle(_ error: NetworkError) {
        guard let message = error.userFacingError else {
            // Cancelled: the screen was left. Nothing to show.
            if case .loading = state {
                state = .idle
            }
            return
        }
        if case .loaded = state {
            // Old departures are more useful than an error; the next refresh may work.
            Logger.networking.notice("Keeping previous departures after refresh failed")
            return
        }
        state = .failed(message)
    }
}
