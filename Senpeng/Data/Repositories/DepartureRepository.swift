import Foundation

/// Provides the upcoming departures from a stop.
///
/// View models depend on this protocol instead of the network,
/// so tests and previews can use fake departures.
protocol DepartureRepository: Sendable {

    /// Returns the SL departures from a stop in the next hour, soonest first.
    /// - Parameter siteID: SL's site ID, for example "9192" for Slussen.
    /// - Returns: The departures.
    /// - Throws: `NetworkError` if they can't be loaded.
    func departures(siteID: String) async throws(NetworkError) -> [Departure]
}
