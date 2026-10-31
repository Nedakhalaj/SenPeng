#if DEBUG
import Foundation

/// A fake `ArrivalRepository` for SwiftUI previews.
struct PreviewArrivalRepository: ArrivalRepository {

    /// What the fake returns: nil gives an arrival 12 minutes after the departure, 3 minutes late.
    var error: ArrivalLookupError?

    func arrival(
        of departure: Departure,
        from origin: Site,
        to destination: Site
    ) async throws(ArrivalLookupError) -> ArrivalEstimate {
        if let error {
            throw error
        }
        let scheduled = departure.scheduled.addingTimeInterval(12 * 60)
        return ArrivalEstimate(scheduled: scheduled, expected: scheduled.addingTimeInterval(3 * 60))
    }
}

/// A fake `TripRepository` for SwiftUI previews. Nothing is stored.
struct PreviewTripRepository: TripRepository {

    func allTrips() async throws(PersistenceError) -> [Trip] {
        []
    }

    func trip(id: UUID) async throws(PersistenceError) -> Trip? {
        nil
    }

    func save(_ trip: Trip) async throws(PersistenceError) {}

    func delete(id: UUID) async throws(PersistenceError) {}

    func deleteAll() async throws(PersistenceError) {}
}
#endif
