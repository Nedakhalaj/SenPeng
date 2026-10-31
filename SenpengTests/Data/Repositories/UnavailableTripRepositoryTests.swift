import Foundation
import Testing
@testable import Senpeng

/// Checks that an unavailable database reports errors instead of pretending to work.
@Suite("Unavailable trip repository")
struct UnavailableTripRepositoryTests {

    private let repository = UnavailableTripRepository()

    @Test("Reading fails")
    func readingFails() async {
        await #expect(throws: PersistenceError.fetchFailed) {
            try await repository.allTrips()
        }
    }

    @Test("Saving fails, so the user is told the trip wasn't saved")
    func savingFails() async {
        await #expect(throws: PersistenceError.saveFailed) {
            try await repository.save(TripFactory.make())
        }
    }
}
