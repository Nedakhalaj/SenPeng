import Foundation

/// A `TripRepository` used when the on-device database can't be opened.
///
/// Every call fails with an error the screens already know how to show,
/// so the app keeps working (search, departures) instead of crashing at launch.
struct UnavailableTripRepository: TripRepository {

    func allTrips() async throws(PersistenceError) -> [Trip] {
        throw .fetchFailed
    }

    func trip(id: UUID) async throws(PersistenceError) -> Trip? {
        throw .fetchFailed
    }

    func save(_ trip: Trip) async throws(PersistenceError) {
        throw .saveFailed
    }

    func delete(id: UUID) async throws(PersistenceError) {
        throw .saveFailed
    }

    func deleteAll() async throws(PersistenceError) {
        throw .saveFailed
    }
}
