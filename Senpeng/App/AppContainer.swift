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

    /// Creates a container with the given building blocks.
    /// - Parameter siteRepository: Provides SL's list of all stops.
    init(siteRepository: any SiteRepository) {
        self.siteRepository = siteRepository
    }

    /// Creates the container used by the real app.
    /// - Returns: A container with live network and storage.
    static func live() -> AppContainer {
        let apiClient = LiveAPIClient(session: .makeSenpengSession())
        return AppContainer(siteRepository: LiveSiteRepository(apiClient: apiClient))
    }

    #if DEBUG
    /// A container with fake data for SwiftUI previews.
    static var preview: AppContainer {
        AppContainer(siteRepository: PreviewSiteRepository())
    }
    #endif
}
