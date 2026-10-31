import Foundation

/// Finds when a departure arrives at the user's destination.
///
/// View models depend on this protocol instead of the network,
/// so tests and previews can use fake arrival times.
protocol ArrivalRepository: Sendable {

    /// Looks up the planned arrival, and the expected arrival if SL has live data.
    /// - Parameter query: The departure, and where the user gets on and off.
    /// - Returns: The arrival times at the destination.
    /// - Throws: `ArrivalLookupError.notOnRoute` if the departure doesn't stop there,
    ///   or `.network` if the request fails.
    func arrival(for query: ArrivalQuery) async throws(ArrivalLookupError) -> ArrivalEstimate
}
