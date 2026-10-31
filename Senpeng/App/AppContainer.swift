import Foundation
import os
import SwiftData

/// Creates the app's real building blocks (network, repositories) once,
/// and hands them to the screens that need them.
///
/// Screens get protocols from here, never create their own dependencies,
/// so previews and tests can pass fakes instead.
@MainActor
final class AppContainer {

    /// Provides SL's list of all stops.
    let siteRepository: any SiteRepository

    /// Provides the real-time departures from a stop.
    let departureRepository: any DepartureRepository

    /// Finds when a departure arrives at the user's destination.
    let arrivalRepository: any ArrivalRepository

    /// Saves and loads the user's trips.
    let tripRepository: any TripRepository

    /// Creates a container with the given building blocks.
    /// - Parameters:
    ///   - siteRepository: Provides SL's list of all stops.
    ///   - departureRepository: Provides the real-time departures from a stop.
    ///   - arrivalRepository: Finds when a departure arrives at the user's destination.
    ///   - tripRepository: Saves and loads the user's trips.
    init(
        siteRepository: any SiteRepository,
        departureRepository: any DepartureRepository,
        arrivalRepository: any ArrivalRepository,
        tripRepository: any TripRepository
    ) {
        self.siteRepository = siteRepository
        self.departureRepository = departureRepository
        self.arrivalRepository = arrivalRepository
        self.tripRepository = tripRepository
    }

    /// Creates the container used by the real app.
    /// - Returns: A container with live network and storage.
    static func live() -> AppContainer {
        // One shared client, so all requests share connections and the cache.
        let apiClient = LiveAPIClient(session: .makeSenpengSession())
        return AppContainer(
            siteRepository: LiveSiteRepository(apiClient: apiClient),
            departureRepository: LiveDepartureRepository(apiClient: apiClient),
            arrivalRepository: LiveArrivalRepository(apiClient: apiClient),
            tripRepository: makeTripRepository()
        )
    }

    /// Opens the on-device database for trips.
    /// - Returns: The real repository, or one that reports errors if the database can't
    ///   be opened, so search and departures keep working instead of the app crashing.
    private static func makeTripRepository() -> any TripRepository {
        do {
            return LiveTripRepository(modelContainer: try ModelContainer.makeSenpengContainer())
        } catch {
            Logger.persistence.fault("Database unavailable: \(String(describing: error), privacy: .private)")
            return UnavailableTripRepository()
        }
    }

    #if DEBUG
    /// A container with fake data for SwiftUI previews.
    static var preview: AppContainer {
        AppContainer(
            siteRepository: PreviewSiteRepository(),
            departureRepository: PreviewDepartureRepository(),
            arrivalRepository: PreviewArrivalRepository(),
            tripRepository: PreviewTripRepository()
        )
    }
    #endif
}
