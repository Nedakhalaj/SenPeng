#if DEBUG
import Foundation

/// A fake `ArrivalRepository` for SwiftUI previews.
struct PreviewArrivalRepository: ArrivalRepository {

    /// What the fake returns: nil gives an arrival 12 minutes after the departure, 3 minutes late.
    var error: ArrivalLookupError?

    func arrival(for query: ArrivalQuery) async throws(ArrivalLookupError) -> ArrivalEstimate {
        if let error {
            throw error
        }
        let scheduled = query.scheduledDeparture.addingTimeInterval(12 * 60)
        return ArrivalEstimate(scheduled: scheduled, expected: scheduled.addingTimeInterval(3 * 60))
    }
}

/// A fake `TripRepository` for SwiftUI previews. Nothing is stored.
struct PreviewTripRepository: TripRepository {

    /// The trips the fake lists. Empty by default.
    var trips: [Trip] = []

    /// An example trip that arrives in a few minutes.
    static func sampleTrip(from now: Date = Date()) -> Trip {
        Trip(
            line: "14",
            transportMode: .metro,
            lineDestination: "Mörby centrum",
            journeyID: "preview",
            origin: PreviewSiteRepository.sampleSites[0].transportStop,
            destination: PreviewSiteRepository.sampleSites[2].transportStop,
            scheduledDeparture: now.addingTimeInterval(-60),
            scheduledArrival: now.addingTimeInterval(5 * 60),
            createdAt: now.addingTimeInterval(-60)
        )
    }

    func allTrips() async throws(PersistenceError) -> [Trip] {
        trips
    }

    func trip(id: UUID) async throws(PersistenceError) -> Trip? {
        nil
    }

    func save(_ trip: Trip) async throws(PersistenceError) {}

    func delete(id: UUID) async throws(PersistenceError) {}

    func deleteAll() async throws(PersistenceError) {}
}
#endif
