import Foundation
import os
@testable import Senpeng

/// An `ArrivalRepository` whose answer each test decides, and which remembers the questions.
@MainActor
final class FakeArrivalRepository: ArrivalRepository {

    /// What `arrival(for:)` returns next.
    var result: Result<ArrivalEstimate, ArrivalLookupError>

    /// Every query asked, in order.
    private(set) var queries: [ArrivalQuery] = []

    init(result: Result<ArrivalEstimate, ArrivalLookupError>) {
        self.result = result
    }

    func arrival(for query: ArrivalQuery) async throws(ArrivalLookupError) -> ArrivalEstimate {
        queries.append(query)
        return try result.get()
    }
}

/// A `TripRepository` that keeps trips in memory, and can fail on demand.
@MainActor
final class FakeTripRepository: TripRepository {

    /// The saved trips.
    private(set) var saved: [Trip]

    /// When set, saving fails with this error.
    var saveError: PersistenceError?

    /// Creates the repository.
    /// - Parameter trips: The trips already saved.
    init(trips: [Trip] = []) {
        saved = trips
    }

    func allTrips() async throws(PersistenceError) -> [Trip] {
        saved
    }

    func trip(id: UUID) async throws(PersistenceError) -> Trip? {
        saved.first { $0.id == id }
    }

    func save(_ trip: Trip) async throws(PersistenceError) {
        if let saveError {
            throw saveError
        }
        if let index = saved.firstIndex(where: { $0.id == trip.id }) {
            saved[index] = trip
        } else {
            saved.append(trip)
        }
    }

    func delete(id: UUID) async throws(PersistenceError) {
        saved.removeAll { $0.id == id }
    }

    func deleteAll() async throws(PersistenceError) {
        saved.removeAll()
    }
}

/// A clock a test can move forward, to test what happens as time passes.
final class TestClock: Sendable {

    /// The current time. Locked because the code under test may read it from another thread.
    private let time: OSAllocatedUnfairLock<Date>

    /// Creates a clock.
    /// - Parameter date: The start time.
    init(_ date: Date) {
        time = OSAllocatedUnfairLock(initialState: date)
    }

    /// The current time.
    var now: Date {
        time.withLock { $0 }
    }

    /// Moves the clock to a new time.
    /// - Parameter date: The new time.
    func set(_ date: Date) {
        time.withLock { $0 = date }
    }
}
