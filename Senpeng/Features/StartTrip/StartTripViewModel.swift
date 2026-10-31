import Foundation
import Observation

/// The logic of the "I'm on this train" sheet.
///
/// The user chooses where they get off, the app checks when the departure
/// arrives there, and the user confirms. The trip is then saved on the device.
@MainActor
@Observable
final class StartTripViewModel {

    /// Where the user is in the flow.
    enum Step: Equatable {

        /// Searching for the stop where they get off.
        case choosingDestination

        /// Asking SL when the departure arrives at the chosen stop.
        case checkingArrival(Site)

        /// The arrival is known; waiting for the user to confirm.
        case readyToStart(Site, ArrivalEstimate)

        /// The arrival couldn't be found.
        case arrivalFailed(Site, UserFacingError)

        /// The trip is saved, so the sheet can close.
        case saved
    }

    /// The departure the user is on.
    let departure: Departure

    /// The stop where the user gets on.
    let origin: Site

    /// What the user typed in the search field. Updates the results on every change.
    var query = "" {
        didSet { updateResults() }
    }

    /// The stop list's state. When loaded, holds the stops that match `query`.
    private(set) var destinations: LoadState<[Site]> = .idle

    /// Where the user is in the flow.
    private(set) var step = Step.choosingDestination

    /// The message to show if saving failed, so the user can try again.
    private(set) var saveError: UserFacingError?

    /// The prepared stop list, once loaded.
    private var index: SiteSearchIndex?

    /// Provides SL's stop list.
    private let siteRepository: any SiteRepository

    /// Finds the arrival time at the chosen stop.
    private let arrivalRepository: any ArrivalRepository

    /// Saves the trip.
    private let tripRepository: any TripRepository

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// Creates the view model.
    /// - Parameters:
    ///   - departure: The departure the user is on.
    ///   - origin: The stop where the user gets on.
    ///   - siteRepository: Provides SL's stop list.
    ///   - arrivalRepository: Finds the arrival time at the chosen stop.
    ///   - tripRepository: Saves the trip.
    ///   - now: Returns the current time.
    init(
        departure: Departure,
        origin: Site,
        siteRepository: any SiteRepository,
        arrivalRepository: any ArrivalRepository,
        tripRepository: any TripRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.departure = departure
        self.origin = origin
        self.siteRepository = siteRepository
        self.arrivalRepository = arrivalRepository
        self.tripRepository = tripRepository
        self.now = now
    }

    /// Loads the stop list for the search, unless it's already loaded or loading.
    func loadStops() async {
        if index != nil {
            return
        }
        if case .loading = destinations {
            return
        }

        destinations = .loading
        do {
            // The user can't get off where they got on, so that stop is left out.
            let sites = try await siteRepository.sites().filter { $0.id != origin.id }
            index = await SiteSearchIndex.make(from: sites)
            updateResults()
        } catch {
            if let message = error.userFacingError {
                destinations = .failed(message)
            } else {
                destinations = .idle
            }
        }
    }

    /// Checks when the departure arrives at the chosen stop. Also used by "Try again".
    /// - Parameter destination: The stop where the user gets off.
    func choose(_ destination: Site) async {
        step = .checkingArrival(destination)
        do {
            let arrival = try await arrivalRepository.arrival(of: departure, from: origin, to: destination)
            step = .readyToStart(destination, arrival)
        } catch {
            if let message = error.userFacingError {
                step = .arrivalFailed(destination, message)
            } else {
                step = .choosingDestination
            }
        }
    }

    /// Goes back to searching for another stop.
    func changeDestination() {
        saveError = nil
        step = .choosingDestination
    }

    /// Saves the trip, after the user tapped "I'm on this train".
    func startTrip() async {
        guard case .readyToStart(let destination, let arrival) = step else {
            return
        }

        saveError = nil
        let trip = Trip(
            line: departure.line,
            transportMode: departure.transportMode,
            lineDestination: departure.destination,
            journeyID: departure.journeyID,
            origin: origin.transportStop,
            destination: destination.transportStop,
            scheduledDeparture: departure.scheduled,
            scheduledArrival: arrival.scheduled,
            createdAt: now()
        )

        do {
            try await tripRepository.save(trip)
            step = .saved
        } catch {
            saveError = error.userFacingError
        }
    }

    /// Searches the loaded list for the current query.
    private func updateResults() {
        guard let index else {
            return
        }
        destinations = .loaded(index.search(query))
    }
}
