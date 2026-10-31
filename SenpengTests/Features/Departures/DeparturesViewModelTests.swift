import Foundation
import Testing
@testable import Senpeng

/// Checks the departures screen's logic with fake departures.
@MainActor
@Suite("Departures view model")
struct DeparturesViewModelTests {

    private let site = Site(id: "9192", name: "Slussen", area: nil, aliases: [])
    private let departures = PreviewDepartureRepository.sampleDepartures(from: TripFactory.referenceDate)

    @Test("Loading shows the departures")
    func loads() async {
        let viewModel = DeparturesViewModel(site: site, repository: MockDepartureRepository(result: .success(departures)))

        await viewModel.refresh()

        #expect(viewModel.state == .loaded(departures))
    }

    @Test("The stop's site ID is used for the request")
    func usesSiteID() async {
        let repository = MockDepartureRepository(result: .success([]))
        let viewModel = DeparturesViewModel(site: site, repository: repository)

        await viewModel.refresh()

        #expect(repository.requestedSiteIDs == ["9192"])
    }

    @Test("A first load that fails shows an error")
    func firstLoadFails() async {
        let viewModel = DeparturesViewModel(site: site, repository: MockDepartureRepository(result: .failure(.offline)))

        await viewModel.refresh()

        #expect(viewModel.state == .failed(.offline))
    }

    @Test("A failed refresh keeps showing the last departures")
    func refreshFailureKeepsData() async {
        let repository = MockDepartureRepository(result: .success(departures))
        let viewModel = DeparturesViewModel(site: site, repository: repository)
        await viewModel.refresh()

        repository.result = .failure(.timeout)
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(departures))
    }

    @Test("Try again after an error loads the departures")
    func retryAfterError() async {
        let repository = MockDepartureRepository(result: .failure(.offline))
        let viewModel = DeparturesViewModel(site: site, repository: repository)
        await viewModel.refresh()

        repository.result = .success(departures)
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(departures))
    }

    @Test("A cancelled first load goes back to idle")
    func cancelled() async {
        let viewModel = DeparturesViewModel(site: site, repository: MockDepartureRepository(result: .failure(.cancelled)))

        await viewModel.refresh()

        #expect(viewModel.state == .idle)
    }

    @Test("Automatic updates refresh again after the interval and stop when cancelled")
    func keepsUpdating() async {
        let repository = MockDepartureRepository(result: .success(departures))
        let viewModel = DeparturesViewModel(site: site, repository: repository, refreshInterval: .milliseconds(10))

        let updates = Task { await viewModel.keepUpdated() }
        try? await Task.sleep(for: .milliseconds(200))
        updates.cancel()
        await updates.value
        let countAfterStop = repository.requestedSiteIDs.count
        try? await Task.sleep(for: .milliseconds(50))

        #expect(countAfterStop >= 2)
        #expect(repository.requestedSiteIDs.count == countAfterStop)
    }
}

/// A fake `DepartureRepository` whose answer each test decides.
@MainActor
private final class MockDepartureRepository: DepartureRepository {

    /// What `departures(siteID:)` returns next.
    var result: Result<[Departure], NetworkError>

    /// Every site ID that was asked for, in order.
    private(set) var requestedSiteIDs: [String] = []

    init(result: Result<[Departure], NetworkError>) {
        self.result = result
    }

    func departures(siteID: String) async throws(NetworkError) -> [Departure] {
        requestedSiteIDs.append(siteID)
        return try result.get()
    }
}
