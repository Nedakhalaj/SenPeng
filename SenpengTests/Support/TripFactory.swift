import Foundation
@testable import Senpeng

/// Creates example trips for tests, with sensible defaults.
enum TripFactory {

    /// A fixed point in time, so tests don't depend on the clock.
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    /// Creates a trip on line 14 from Slussen to T-Centralen.
    /// - Parameters:
    ///   - id: The trip's ID.
    ///   - departureOffset: Seconds after `referenceDate` the trip departs.
    ///   - arrivalDelay: How late it arrived, in seconds, or `nil` if unknown.
    ///   - claimStatus: Whether a claim was submitted.
    /// - Returns: The trip.
    static func make(
        id: UUID = UUID(),
        departureOffset: TimeInterval = 0,
        arrivalDelay: TimeInterval? = nil,
        claimStatus: ClaimStatus = .notSubmitted
    ) -> Trip {
        let departure = referenceDate.addingTimeInterval(departureOffset)
        // The scheduled ride from Slussen to T-Centralen takes 3 minutes.
        let arrival = departure.addingTimeInterval(3 * 60)
        return Trip(
            id: id,
            line: "14",
            transportMode: .metro,
            lineDestination: "Mörby centrum",
            journeyID: "journey-1",
            origin: TransportStop(id: "9192", name: "Slussen", globalID: "9091001000009192"),
            destination: TransportStop(id: "9001", name: "T-Centralen", globalID: "9091001000009001"),
            scheduledDeparture: departure,
            scheduledArrival: arrival,
            actualArrival: arrivalDelay.map { arrival.addingTimeInterval($0) },
            delaySource: arrivalDelay == nil ? nil : .live,
            claimStatus: claimStatus,
            createdAt: departure
        )
    }
}
