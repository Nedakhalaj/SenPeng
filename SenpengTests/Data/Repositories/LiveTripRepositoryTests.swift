import Foundation
import SwiftData
import Testing
@testable import Senpeng

/// Checks saving, loading and deleting trips in an in-memory database.
///
/// Each test creates its own database, so tests never affect each other.
@Suite("Live trip repository")
struct LiveTripRepositoryTests {

    @Test("A saved trip can be loaded again")
    func saveAndLoad() async throws {
        let repository = try makeRepository()
        let trip = TripFactory.make(arrivalDelay: 25 * 60)

        try await repository.save(trip)

        #expect(try await repository.trip(id: trip.id) == trip)
    }

    @Test("Saving a trip again updates it instead of adding a copy")
    func saveUpdatesExisting() async throws {
        let repository = try makeRepository()
        var trip = TripFactory.make()
        try await repository.save(trip)

        trip.actualArrival = trip.scheduledArrival.addingTimeInterval(30 * 60)
        trip.delaySource = .historical
        trip.claimStatus = .submitted
        try await repository.save(trip)

        let trips = try await repository.allTrips()
        #expect(trips == [trip])
    }

    @Test("Trips are listed with the newest departure first")
    func sortedNewestFirst() async throws {
        let repository = try makeRepository()
        let older = TripFactory.make(departureOffset: 0)
        let newer = TripFactory.make(departureOffset: 3_600)
        try await repository.save(older)
        try await repository.save(newer)

        let trips = try await repository.allTrips()

        #expect(trips.map(\.id) == [newer.id, older.id])
    }

    @Test("Deleting a trip removes only that trip")
    func deleteOne() async throws {
        let repository = try makeRepository()
        let kept = TripFactory.make()
        let removed = TripFactory.make()
        try await repository.save(kept)
        try await repository.save(removed)

        try await repository.delete(id: removed.id)

        #expect(try await repository.allTrips() == [kept])
    }

    @Test("Deleting an unknown trip does nothing")
    func deleteUnknown() async throws {
        let repository = try makeRepository()
        let trip = TripFactory.make()
        try await repository.save(trip)

        try await repository.delete(id: UUID())

        #expect(try await repository.allTrips() == [trip])
    }

    @Test("Delete all removes every trip")
    func deleteAll() async throws {
        let repository = try makeRepository()
        try await repository.save(TripFactory.make())
        try await repository.save(TripFactory.make())

        try await repository.deleteAll()

        #expect(try await repository.allTrips().isEmpty)
    }

    @Test("An unknown trip ID returns nil")
    func unknownTrip() async throws {
        let repository = try makeRepository()

        #expect(try await repository.trip(id: UUID()) == nil)
    }

    /// Creates a repository on a fresh in-memory database.
    private func makeRepository() throws -> LiveTripRepository {
        LiveTripRepository(modelContainer: try ModelContainer.makeSenpengContainer(inMemory: true))
    }
}
