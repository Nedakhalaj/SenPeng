import Foundation
import Testing
@testable import Senpeng

/// Checks how the current trip is followed and when its real arrival is saved.
///
/// The example trip leaves at `referenceDate` and should arrive 3 minutes later.
@MainActor
@Suite("Active trip view model")
struct ActiveTripViewModelTests {

    private let trip = TripFactory.make()
    private let clock = TestClock(TripFactory.referenceDate)

    /// The timetable's arrival of the example trip.
    private var scheduledArrival: Date {
        trip.scheduledArrival
    }

    @Test("Without trips there's nothing to follow")
    func noTrips() async {
        let viewModel = makeViewModel(trips: FakeTripRepository())

        await viewModel.refresh()

        #expect(viewModel.status == .none)
    }

    @Test("A trip with a known real arrival isn't followed")
    func finishedTrip() async {
        let viewModel = makeViewModel(trips: FakeTripRepository(trips: [TripFactory.make(arrivalDelay: 60)]))

        await viewModel.refresh()

        #expect(viewModel.status == .none)
    }

    @Test("A trip isn't followed more than 2 hours after its planned arrival")
    func tooOldTrip() async {
        clock.set(scheduledArrival.addingTimeInterval(2 * 60 * 60 + 1))
        let viewModel = makeViewModel(trips: FakeTripRepository(trips: [trip]))

        await viewModel.refresh()

        #expect(viewModel.status == .none)
    }

    @Test("A trip on the way shows its live estimate, and asks about that trip")
    func following() async {
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: scheduledArrival.addingTimeInterval(240))
        let arrivals = FakeArrivalRepository(result: .success(estimate))
        let viewModel = makeViewModel(trips: FakeTripRepository(trips: [trip]), arrivals: arrivals)

        await viewModel.refresh()

        #expect(viewModel.status == .following(trip, estimate))
        #expect(arrivals.queries == [ArrivalQuery(trip: trip)])
    }

    @Test("Without live data nothing is saved, however late it gets: unknown never means on time")
    func noLiveDataSavesNothing() async {
        clock.set(scheduledArrival.addingTimeInterval(60 * 60))
        let trips = FakeTripRepository(trips: [trip])
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: nil)
        let viewModel = makeViewModel(trips: trips, arrivals: FakeArrivalRepository(result: .success(estimate)))

        await viewModel.refresh()

        #expect(viewModel.status == .following(trip, estimate))
        #expect(trips.saved == [trip])
        #expect(trips.saved.first?.actualArrival == nil)
    }

    @Test("Before the expected arrival, the real arrival isn't saved")
    func notArrivedYet() async {
        let trips = FakeTripRepository(trips: [trip])
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: scheduledArrival.addingTimeInterval(60))
        clock.set(scheduledArrival.addingTimeInterval(59))
        let viewModel = makeViewModel(trips: trips, arrivals: FakeArrivalRepository(result: .success(estimate)))

        await viewModel.refresh()

        #expect(trips.saved.first?.actualArrival == nil)
    }

    @Test("When the live arrival has passed, the real arrival is saved as measured live")
    func arrivalSaved() async {
        let trips = FakeTripRepository(trips: [trip])
        let actualArrival = scheduledArrival.addingTimeInterval(25 * 60)
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: actualArrival)
        clock.set(actualArrival)
        let viewModel = makeViewModel(trips: trips, arrivals: FakeArrivalRepository(result: .success(estimate)))

        await viewModel.refresh()

        var expectedTrip = trip
        expectedTrip.actualArrival = actualArrival
        expectedTrip.delaySource = .live
        #expect(trips.saved == [expectedTrip])
        #expect(viewModel.status == .arrived(expectedTrip))
    }

    @Test("If saving the arrival fails, it's still following and tries again next time")
    func saveFailureRetries() async {
        let trips = FakeTripRepository(trips: [trip])
        trips.saveError = .saveFailed
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: scheduledArrival)
        clock.set(scheduledArrival)
        let viewModel = makeViewModel(trips: trips, arrivals: FakeArrivalRepository(result: .success(estimate)))

        await viewModel.refresh()
        #expect(viewModel.status == .following(trip, estimate))

        trips.saveError = nil
        await viewModel.refresh()
        #expect(trips.saved.first?.delaySource == .live)
    }

    @Test("If an update fails, the last estimate stays on screen")
    func updateFailureKeepsEstimate() async {
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: scheduledArrival.addingTimeInterval(240))
        let arrivals = FakeArrivalRepository(result: .success(estimate))
        let viewModel = makeViewModel(trips: FakeTripRepository(trips: [trip]), arrivals: arrivals)
        await viewModel.refresh()

        arrivals.result = .failure(.network(.offline))
        await viewModel.refresh()

        #expect(viewModel.status == .following(trip, estimate))
    }

    @Test("Removing the trip deletes it")
    func remove() async {
        let trips = FakeTripRepository(trips: [trip])
        let viewModel = makeViewModel(trips: trips)
        await viewModel.refresh()

        await viewModel.removeTrip()

        #expect(trips.saved.isEmpty)
        #expect(viewModel.status == .none)
    }

    @Test("An arrived trip stays until Done, and doesn't come back after")
    func arrivedUntilDone() async {
        let trips = FakeTripRepository(trips: [trip])
        let estimate = ArrivalEstimate(scheduled: scheduledArrival, expected: scheduledArrival)
        clock.set(scheduledArrival)
        let viewModel = makeViewModel(trips: trips, arrivals: FakeArrivalRepository(result: .success(estimate)))
        await viewModel.refresh()
        let arrived = viewModel.status

        await viewModel.refresh()
        #expect(viewModel.status == arrived)

        viewModel.dismissArrived()
        await viewModel.refresh()
        #expect(viewModel.status == .none)
    }

    @Test("A trip that arrived more than 20 minutes late may qualify; a smaller delay doesn't")
    func eligibility() {
        let viewModel = makeViewModel(trips: FakeTripRepository())
        let veryLate = TripFactory.make(arrivalDelay: 25 * 60)
        let slightlyLate = TripFactory.make(arrivalDelay: 5 * 60)

        guard case .eligible = viewModel.eligibility(for: veryLate) else {
            Issue.record("Expected the trip to be eligible")
            return
        }
        #expect(viewModel.eligibility(for: slightlyLate) == .delayTooShort)
    }

    /// Creates a view model with fake repositories and the test clock.
    private func makeViewModel(
        trips: FakeTripRepository,
        arrivals: FakeArrivalRepository? = nil
    ) -> ActiveTripViewModel {
        let fallback = ArrivalEstimate(scheduled: scheduledArrival, expected: nil)
        let clock = clock
        return ActiveTripViewModel(
            tripRepository: trips,
            arrivalRepository: arrivals ?? FakeArrivalRepository(result: .success(fallback)),
            now: { clock.now }
        )
    }
}
