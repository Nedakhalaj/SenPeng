import Foundation

/// Finds when a chosen departure arrives at the user's destination.
///
/// View models depend on this protocol instead of the network,
/// so tests and previews can use fake arrival times.
protocol ArrivalRepository: Sendable {

    /// Looks up the planned and live expected arrival of a departure at a destination.
    /// - Parameters:
    ///   - departure: The departure the user is on.
    ///   - origin: The stop where the user got on.
    ///   - destination: The stop where the user gets off.
    /// - Returns: The arrival times at the destination.
    /// - Throws: `ArrivalLookupError.notOnRoute` if the departure doesn't stop there,
    ///   or `.network` if the request fails.
    func arrival(
        of departure: Departure,
        from origin: Site,
        to destination: Site
    ) async throws(ArrivalLookupError) -> ArrivalEstimate
}
