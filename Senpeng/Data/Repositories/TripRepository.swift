import Foundation

/// Saves and loads the user's trips.
///
/// View models depend on this protocol instead of the database,
/// so tests and previews can use a fake repository.
protocol TripRepository: Sendable {

    /// Loads all saved trips, newest departure first.
    /// - Returns: The trips.
    /// - Throws: `PersistenceError` if the trips can't be read.
    func allTrips() async throws(PersistenceError) -> [Trip]

    /// Loads one trip.
    /// - Parameter id: The trip's ID.
    /// - Returns: The trip, or `nil` if no trip has that ID.
    /// - Throws: `PersistenceError` if the trip can't be read.
    func trip(id: UUID) async throws(PersistenceError) -> Trip?

    /// Saves a new trip, or updates it if a trip with the same ID exists.
    /// - Parameter trip: The trip to save.
    /// - Throws: `PersistenceError` if the trip can't be saved.
    func save(_ trip: Trip) async throws(PersistenceError)

    /// Deletes one trip. Does nothing if no trip has that ID.
    /// - Parameter id: The trip's ID.
    /// - Throws: `PersistenceError` if the change can't be saved.
    func delete(id: UUID) async throws(PersistenceError)

    /// Deletes every saved trip, for "Delete all data" in Settings.
    /// - Throws: `PersistenceError` if the change can't be saved.
    func deleteAll() async throws(PersistenceError)
}
