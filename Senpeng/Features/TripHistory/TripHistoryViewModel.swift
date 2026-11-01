import Foundation
import Observation
import os

/// The logic of the My trips screen.
@MainActor
@Observable
final class TripHistoryViewModel {

    /// The screen's state. When loaded, holds the trips sorted into sections.
    private(set) var state: LoadState<TripHistory> = .idle

    /// Saves and loads the trips.
    private let repository: any TripRepository

    /// Decides whether a trip may qualify for delay money.
    private let checker = EligibilityChecker()

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// Creates the view model.
    /// - Parameters:
    ///   - repository: Saves and loads the trips.
    ///   - now: Returns the current time.
    init(repository: any TripRepository, now: @escaping @Sendable () -> Date = { Date() }) {
        self.repository = repository
        self.now = now
    }

    /// Loads the trips. Called when the screen appears and whenever a trip changes.
    func load() async {
        // The spinner only shows the first time; later reloads keep the list on screen.
        if case .loaded = state {} else {
            state = .loading
        }

        do {
            let trips = try await repository.allTrips()
            state = .loaded(await TripHistory.make(trips: trips, now: now(), checker: checker))
        } catch {
            Logger.persistence.error("Loading trips failed")
            if case .loaded = state {
                return
            }
            state = .failed(error.userFacingError)
        }
    }

    /// Deletes a trip and reloads the list.
    /// - Parameter id: The trip's ID.
    /// - Returns: `true` if the trip was deleted.
    @discardableResult
    func delete(id: UUID) async -> Bool {
        do {
            try await repository.delete(id: id)
            await load()
            return true
        } catch {
            Logger.persistence.error("Deleting a trip failed")
            return false
        }
    }
}
