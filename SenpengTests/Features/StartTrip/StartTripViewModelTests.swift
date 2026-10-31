import Foundation
import Testing
@testable import Senpeng

/// Checks the "I'm on this train" flow with fake data.
@MainActor
@Suite("Start trip view model")
struct StartTripViewModelTests {

    private let slussen = Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192")
    private let centralen = Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001")
    private let now = TripFactory.referenceDate
    private let departure = PreviewDepartureRepository.sampleDepartures(from: TripFactory.referenceDate)[0]
    private let arrival = ArrivalEstimate(
        scheduled: TripFactory.referenceDate.addingTimeInterval(600),
        expected: TripFactory.referenceDate.addingTimeInterval(780)
    )

    @Test("The stop the user gets on at can't be chosen as the destination")
    func originIsLeftOut() async {
        let viewModel = makeViewModel()
        await viewModel.loadStops()

        viewModel.query = "slussen"

        #expect(viewModel.destinations == .loaded([]))
    }

    @Test("Typing shows the matching stops")
    func searchFindsDestination() async {
        let viewModel = makeViewModel()
        await viewModel.loadStops()

        viewModel.query = "centralen"

        #expect(viewModel.destinations == .loaded([centralen]))
    }

    @Test("Choosing a stop on the route shows the arrival")
    func choosingShowsArrival() async {
        let viewModel = makeViewModel()

        await viewModel.choose(centralen)

        #expect(viewModel.step == .readyToStart(centralen, arrival))
    }

    @Test("Choosing a stop that isn't on the route explains the problem")
    func notOnRoute() async {
        let viewModel = makeViewModel(arrivalResult: .failure(.notOnRoute))

        await viewModel.choose(centralen)

        #expect(viewModel.step == .arrivalFailed(centralen, .notOnRoute))
    }

    @Test("A cancelled arrival check goes back to the search")
    func cancelledLookup() async {
        let viewModel = makeViewModel(arrivalResult: .failure(.network(.cancelled)))

        await viewModel.choose(centralen)

        #expect(viewModel.step == .choosingDestination)
    }

    @Test("Change stop goes back to the search")
    func changeDestination() async {
        let viewModel = makeViewModel()
        await viewModel.choose(centralen)

        viewModel.changeDestination()

        #expect(viewModel.step == .choosingDestination)
    }

    @Test("Starting saves the trip with everything needed for a claim")
    func startSavesTrip() async throws {
        let trips = FakeTripRepository()
        let viewModel = makeViewModel(trips: trips)
        await viewModel.choose(centralen)

        await viewModel.startTrip()

        #expect(viewModel.step == .saved)
        let trip = try #require(trips.saved.first)
        #expect(trips.saved.count == 1)
        #expect(trip.line == departure.line)
        #expect(trip.transportMode == departure.transportMode)
        #expect(trip.lineDestination == departure.destination)
        #expect(trip.journeyID == departure.journeyID)
        #expect(trip.origin == slussen.transportStop)
        #expect(trip.destination == centralen.transportStop)
        #expect(trip.scheduledDeparture == departure.scheduled)
        #expect(trip.scheduledArrival == arrival.scheduled)
        #expect(trip.createdAt == now)
        #expect(trip.actualArrival == nil)
        #expect(trip.claimStatus == .notSubmitted)
    }

    @Test("If saving fails, the user sees a message and can try again")
    func saveFailure() async {
        let trips = FakeTripRepository()
        trips.saveError = .saveFailed
        let viewModel = makeViewModel(trips: trips)
        await viewModel.choose(centralen)

        await viewModel.startTrip()

        #expect(viewModel.step == .readyToStart(centralen, arrival))
        #expect(viewModel.saveError == .unexpected)

        trips.saveError = nil
        await viewModel.startTrip()

        #expect(viewModel.step == .saved)
        #expect(viewModel.saveError == nil)
    }

    @Test("Starting does nothing before a stop is chosen")
    func startTooEarly() async {
        let trips = FakeTripRepository()
        let viewModel = makeViewModel(trips: trips)

        await viewModel.startTrip()

        #expect(trips.saved.isEmpty)
        #expect(viewModel.step == .choosingDestination)
    }

    /// Creates a view model with fake repositories and a fixed clock.
    private func makeViewModel(
        arrivalResult: Result<ArrivalEstimate, ArrivalLookupError>? = nil,
        trips: FakeTripRepository = FakeTripRepository()
    ) -> StartTripViewModel {
        let now = now
        return StartTripViewModel(
            departure: departure,
            origin: slussen,
            siteRepository: PreviewSiteRepository(result: .success([slussen, centralen])),
            arrivalRepository: FakeArrivalRepository(result: arrivalResult ?? .success(arrival)),
            tripRepository: trips,
            now: { now }
        )
    }
}
