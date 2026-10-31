import Foundation

/// Provides SL's list of all stops.
///
/// View models depend on this protocol instead of the network,
/// so tests and previews can use a fake list.
protocol SiteRepository: Sendable {

    /// Returns all of SL's stops.
    /// - Returns: The stops, in no particular order.
    /// - Throws: `NetworkError` if the list can't be downloaded and no saved copy exists.
    func sites() async throws(NetworkError) -> [Site]
}
