import Foundation
import Testing
@testable import Senpeng

/// Checks the stop search screen's logic with a fake stop list.
@MainActor
@Suite("Stop search view model")
struct StopSearchViewModelTests {

    private let slussen = Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192")
    private let centralen = Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001")

    @Test("Starts idle, before the screen appears")
    func startsIdle() {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .success([])))

        #expect(viewModel.state == .idle)
    }

    @Test("After loading, an empty search shows no stops")
    func loadedWithEmptyQuery() async {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .success([slussen, centralen])))

        await viewModel.load()

        #expect(viewModel.state == .loaded([]))
    }

    @Test("Typing shows the matching stops")
    func typingFilters() async {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .success([slussen, centralen])))
        await viewModel.load()

        viewModel.query = "sluss"

        #expect(viewModel.state == .loaded([slussen]))
    }

    @Test("Text typed before loading finished is searched once loaded")
    func queryBeforeLoad() async {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .success([slussen, centralen])))
        viewModel.query = "centralen"

        await viewModel.load()

        #expect(viewModel.state == .loaded([centralen]))
    }

    @Test("A network error shows a friendly message")
    func failure() async {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .failure(.offline)))

        await viewModel.load()

        #expect(viewModel.state == .failed(.offline))
    }

    @Test("A cancelled load goes back to idle instead of showing an error")
    func cancelled() async {
        let viewModel = StopSearchViewModel(repository: MockSiteRepository(result: .failure(.cancelled)))

        await viewModel.load()

        #expect(viewModel.state == .idle)
    }

    @Test("Try again after an error loads the stops")
    func retryAfterFailure() async {
        let repository = MockSiteRepository(result: .failure(.offline))
        let viewModel = StopSearchViewModel(repository: repository)
        await viewModel.load()

        repository.result = .success([slussen])
        viewModel.query = "slussen"
        await viewModel.load()

        #expect(viewModel.state == .loaded([slussen]))
    }
}

/// A fake `SiteRepository` whose answer each test decides.
@MainActor
private final class MockSiteRepository: SiteRepository {

    /// What `sites()` returns next.
    var result: Result<[Site], NetworkError>

    init(result: Result<[Site], NetworkError>) {
        self.result = result
    }

    func sites() async throws(NetworkError) -> [Site] {
        try result.get()
    }
}
