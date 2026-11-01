import Foundation
import Testing
@testable import Senpeng

/// Checks the My trips screen's logic with fake trips.
@MainActor
@Suite("Trip history view model")
struct TripHistoryViewModelTests {

    private let trip = TripFactory.make(arrivalDelay: 0)

    @Test("Starts idle, before the screen appears")
    func startsIdle() {
        let viewModel = TripHistoryViewModel(repository: FakeTripRepository())

        #expect(viewModel.state == .idle)
    }

    @Test("Loading shows the saved trips")
    func loads() async throws {
        let viewModel = TripHistoryViewModel(repository: FakeTripRepository(trips: [trip]))

        await viewModel.load()

        guard case .loaded(let history) = viewModel.state else {
            Issue.record("Expected loaded trips")
            return
        }
        #expect(history.otherTrips.map(\.trip) == [trip])
    }

    @Test("A first load that fails shows a friendly error")
    func firstLoadFails() async {
        let viewModel = TripHistoryViewModel(repository: UnavailableTripRepository())

        await viewModel.load()

        #expect(viewModel.state == .failed(.unexpected))
    }

    @Test("Deleting removes the trip from the list")
    func delete() async {
        let repository = FakeTripRepository(trips: [trip])
        let viewModel = TripHistoryViewModel(repository: repository)
        await viewModel.load()

        let didDelete = await viewModel.delete(id: trip.id)

        #expect(didDelete)
        #expect(repository.saved.isEmpty)
        guard case .loaded(let history) = viewModel.state else {
            Issue.record("Expected loaded trips")
            return
        }
        #expect(history.isEmpty)
    }

    @Test("A delete that fails reports it, so the screen stays open")
    func deleteFails() async {
        let viewModel = TripHistoryViewModel(repository: UnavailableTripRepository())

        let didDelete = await viewModel.delete(id: trip.id)

        #expect(!didDelete)
    }

    @Test("Saved changes appear on the next load")
    func reloadShowsChanges() async {
        let repository = FakeTripRepository()
        let viewModel = TripHistoryViewModel(repository: repository)
        await viewModel.load()

        try? await repository.save(trip)
        await viewModel.load()

        guard case .loaded(let history) = viewModel.state else {
            Issue.record("Expected loaded trips")
            return
        }
        #expect(!history.isEmpty)
    }
}
