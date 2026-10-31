import Foundation
import os
import Testing
@testable import Senpeng

/// Checks downloading, saving and reusing SL's stop list, using a fake network.
@Suite("Live site repository")
struct LiveSiteRepositoryTests {

    /// One week, the repository's default cache age.
    private let week: TimeInterval = 7 * 24 * 60 * 60

    @Test("Downloads the stop list and converts it")
    func downloads() async throws {
        let setup = try Setup()

        let sites = try await setup.repository().sites()

        #expect(sites.count == 9)
        #expect(sites.contains(Site(id: "9192", name: "Slussen", area: nil, aliases: [])))
        #expect(sites.contains(Site(id: "408", name: "Höganäs", area: "Tynningö", aliases: ["Höganäs brygga"])))
        #expect(setup.requestCount == 1)
    }

    @Test("A saved list younger than a week is used without downloading")
    func usesFreshCache() async throws {
        let setup = try Setup()
        _ = try await setup.repository().sites()

        // A new repository reads the saved file, like after restarting the app.
        let sites = try await setup.repository(now: TripFactory.referenceDate.addingTimeInterval(week - 60)).sites()

        #expect(sites.count == 9)
        #expect(setup.requestCount == 1)
    }

    @Test("A saved list older than a week is downloaded again")
    func refreshesOldCache() async throws {
        let setup = try Setup()
        _ = try await setup.repository().sites()

        _ = try await setup.repository(now: TripFactory.referenceDate.addingTimeInterval(week + 60)).sites()

        #expect(setup.requestCount == 2)
    }

    @Test("When offline, an old saved list is still used")
    func fallsBackToOldCache() async throws {
        let setup = try Setup()
        _ = try await setup.repository().sites()
        setup.goOffline()

        let sites = try await setup.repository(now: TripFactory.referenceDate.addingTimeInterval(week + 60)).sites()

        #expect(sites.count == 9)
    }

    @Test("When offline without a saved list, the error is passed on")
    func offlineWithoutCache() async throws {
        let setup = try Setup()
        setup.goOffline()

        await #expect(throws: NetworkError.offline) {
            try await setup.repository().sites()
        }
    }

    /// A fake network, a temporary cache file and a request counter for one test.
    private final class Setup: Sendable {

        /// The number of requests and whether the fake network is offline.
        private let network = OSAllocatedUnfairLock(initialState: (requests: 0, offline: false))
        private let host = "test-\(UUID().uuidString).example"
        private let cacheURL = FileManager.default.temporaryDirectory.appending(path: "sites-\(UUID().uuidString).json")
        private let session: URLSession

        init() throws {
            let data = try Fixture.data(named: "sl-sites")
            let network = network
            session = MockURLProtocol.makeSession(host: host) { request in
                let offline = network.withLock { state in
                    state.requests += 1
                    return state.offline
                }
                if offline {
                    throw URLError(.notConnectedToInternet)
                }
                let url = try #require(request.url)
                let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
                return (response, data)
            }
        }

        deinit {
            try? FileManager.default.removeItem(at: cacheURL)
        }

        /// How many requests reached the fake network.
        var requestCount: Int {
            network.withLock { $0.requests }
        }

        /// Makes every following request fail as if there were no internet.
        func goOffline() {
            network.withLock { $0.offline = true }
        }

        /// Creates a repository that downloads from the fake network and saves to the temporary file.
        /// - Parameter now: The current time as the repository sees it.
        func repository(now: Date = TripFactory.referenceDate) -> LiveSiteRepository {
            LiveSiteRepository(
                apiClient: RedirectingAPIClient(host: host, client: LiveAPIClient(session: session)),
                cacheURL: cacheURL,
                now: { now }
            )
        }
    }
}

/// Sends requests to a test host instead of SL's real server, so the fake network can answer them.
private struct RedirectingAPIClient: APIClient {

    let host: String
    let client: LiveAPIClient

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        var components = URLComponents(url: endpoint.baseURL, resolvingAgainstBaseURL: false)
        components?.host = host
        guard let baseURL = components?.url else {
            throw .invalidResponse
        }
        let redirected = Endpoint<Response>(
            baseURL: baseURL,
            path: endpoint.path,
            queryItems: endpoint.queryItems,
            cachePolicy: endpoint.cachePolicy
        )
        return try await client.send(redirected)
    }
}
