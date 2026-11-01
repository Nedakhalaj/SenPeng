import Foundation
import Observation
import os

/// Follows the trip the user is on: finds it, updates its live arrival, and saves
/// the real arrival time once live data shows the vehicle has arrived.
///
/// The real arrival is what a later claim is based on, so it's only saved from live
/// data. Without live data nothing is saved: an unknown delay must never look like
/// "on time".
@MainActor
@Observable
final class ActiveTripViewModel {

    /// What the app knows about the user's current trip.
    enum Status: Equatable {

        /// There's no trip to follow.
        case none

        /// On the way. The estimate is `nil` until the first lookup has answered.
        case following(Trip, ArrivalEstimate?)

        /// The vehicle has arrived and the real arrival is saved.
        case arrived(Trip)

        /// Changes when the trip or its stage changes, but not on every live update,
        /// so other screens know when to reload.
        var changeToken: String {
            switch self {
            case .none: "none"
            case .following(let trip, _): "following-\(trip.id)"
            case .arrived(let trip): "arrived-\(trip.id)"
            }
        }
    }

    /// What the app knows about the user's current trip.
    private(set) var status = Status.none

    /// Saves and loads the trips.
    private let tripRepository: any TripRepository

    /// Finds the live arrival time.
    private let arrivalRepository: any ArrivalRepository

    /// Decides whether a trip may qualify for delay money.
    private let eligibilityChecker = EligibilityChecker()

    /// How long to wait between automatic updates.
    private let refreshInterval: Duration

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// Creates the view model.
    /// - Parameters:
    ///   - tripRepository: Saves and loads the trips.
    ///   - arrivalRepository: Finds the live arrival time.
    ///   - refreshInterval: Time between automatic updates. 30 seconds by default,
    ///     the shortest allowed by the project rules, to respect SL's rate limits.
    ///   - now: Returns the current time.
    init(
        tripRepository: any TripRepository,
        arrivalRepository: any ArrivalRepository,
        refreshInterval: Duration = .seconds(30),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.tripRepository = tripRepository
        self.arrivalRepository = arrivalRepository
        self.refreshInterval = refreshInterval
        self.now = now
    }

    /// Whether a trip may qualify for delay money, right now.
    /// - Parameter trip: The trip to judge.
    /// - Returns: The result, based on the rules valid on the trip's date.
    func eligibility(for trip: Trip) -> EligibilityResult {
        eligibilityChecker.eligibility(for: trip, now: now())
    }

    /// Updates the trip now, then again every `refreshInterval`, until cancelled.
    ///
    /// The view runs this in `.task`, so it stops when the app goes to the background.
    /// Without a current trip, each round only reads the device's database.
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

    /// Finds the current trip and updates its live arrival once.
    func refresh() async {
        // An arrived trip stays on screen until the user taps "Done".
        if case .arrived = status {
            return
        }

        let trip: Trip?
        do {
            trip = try await tripRepository.allTrips().first { $0.isActive(at: now()) }
        } catch {
            Logger.persistence.error("Loading the current trip failed")
            return
        }
        guard let trip else {
            status = .none
            return
        }

        // Keep showing the last estimate until the new one has answered.
        status = .following(trip, lastEstimate(for: trip))
        await updateArrival(of: trip)
    }

    /// Deletes the current trip, after the user confirmed "Remove trip".
    func removeTrip() async {
        guard let trip = currentTrip else {
            return
        }
        do {
            try await tripRepository.delete(id: trip.id)
            status = .none
        } catch {
            Logger.persistence.error("Removing the trip failed")
        }
    }

    /// Closes an arrived trip, after the user tapped "Done".
    func dismissArrived() {
        status = .none
    }

    /// The trip being shown, if any.
    private var currentTrip: Trip? {
        switch status {
        case .none:
            nil
        case .following(let trip, _), .arrived(let trip):
            trip
        }
    }

    /// The estimate already known for this trip, if any.
    private func lastEstimate(for trip: Trip) -> ArrivalEstimate? {
        if case .following(let current, let estimate) = status, current.id == trip.id {
            return estimate
        }
        return nil
    }

    /// Looks up the live arrival, and saves it as the real arrival if it has passed.
    private func updateArrival(of trip: Trip) async {
        let estimate: ArrivalEstimate
        do {
            estimate = try await arrivalRepository.arrival(for: ArrivalQuery(trip: trip))
        } catch {
            // The last estimate stays on screen; the next round may work.
            Logger.networking.notice("Updating the live arrival failed")
            return
        }

        // Only live data counts: the arrival must be measured, not assumed.
        guard let expected = estimate.expected, now() >= expected else {
            status = .following(trip, estimate)
            return
        }

        var arrivedTrip = trip
        arrivedTrip.actualArrival = expected
        arrivedTrip.delaySource = .live
        do {
            try await tripRepository.save(arrivedTrip)
            status = .arrived(arrivedTrip)
        } catch {
            // Not saved, so still following: the next round tries again.
            Logger.persistence.error("Saving the real arrival failed")
            status = .following(trip, estimate)
        }
    }
}
