import Foundation

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

    /// Creates a container with the given building blocks.
    /// - Parameters:
    ///   - siteRepository: Provides SL's list of all stops.
    ///   - departureRepository: Provides the real-time departures from a stop.
    init(siteRepository: any SiteRepository, departureRepository: any DepartureRepository) {
        self.siteRepository = siteRepository
        self.departureRepository = departureRepository
    }

    /// Creates the container used by the real app.
    /// - Returns: A container with live network and storage.
    static func live() -> AppContainer {
        // One shared client, so all requests share connections and the cache.
        let apiClient = LiveAPIClient(session: .makeSenpengSession())
        return AppContainer(
            siteRepository: LiveSiteRepository(apiClient: apiClient),
            departureRepository: LiveDepartureRepository(apiClient: apiClient)
        )
    }

    #if DEBUG
    /// A container with fake data for SwiftUI previews.
    static var preview: AppContainer {
        AppContainer(siteRepository: PreviewSiteRepository(), departureRepository: PreviewDepartureRepository())
    }
    #endif
}
