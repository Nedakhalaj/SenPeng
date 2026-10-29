import Foundation
import Testing
@testable import Senpeng

/// Checks how the real API client handles answers and failures, using a fake network.
@Suite("Live API client")
struct LiveAPIClientTests {

    /// The answer type decoded from `sample-stop.json`.
    private struct Stop: Decodable, Equatable, Sendable {
        let id: Int
        let name: String
    }

    @Test("Decodes a successful answer")
    func decodesSuccess() async throws {
        let data = try Fixture.data(named: "sample-stop")
        let (client, endpoint) = try makeClient { request in
            (try Self.response(for: request, statusCode: 200), data)
        }

        let stop = try await client.send(endpoint)

        #expect(stop == Stop(id: 9192, name: "Slussen"))
    }

    @Test("Server error status becomes a server error", arguments: [404, 500, 503])
    func serverError(statusCode: Int) async throws {
        let (client, endpoint) = try makeClient { request in
            (try Self.response(for: request, statusCode: statusCode), Data())
        }

        await #expect(throws: NetworkError.server(statusCode: statusCode)) {
            try await client.send(endpoint)
        }
    }

    @Test("Unexpected JSON becomes a decoding error")
    func decodingError() async throws {
        let (client, endpoint) = try makeClient { request in
            (try Self.response(for: request, statusCode: 200), Data(#"{"unexpected": true}"#.utf8))
        }

        await #expect(throws: NetworkError.decoding) {
            try await client.send(endpoint)
        }
    }

    @Test("No internet becomes an offline error")
    func offlineError() async throws {
        let (client, endpoint) = try makeClient { _ in
            throw URLError(.notConnectedToInternet)
        }

        await #expect(throws: NetworkError.offline) {
            try await client.send(endpoint)
        }
    }

    @Test("A slow server becomes a timeout error")
    func timeoutError() async throws {
        let (client, endpoint) = try makeClient { _ in
            throw URLError(.timedOut)
        }

        await #expect(throws: NetworkError.timeout) {
            try await client.send(endpoint)
        }
    }

    /// Creates a client on a fake network with its own unique host.
    /// - Parameter handler: Builds the fake answer for each request.
    /// - Returns: The client and an endpoint that points at the fake host.
    private func makeClient(
        handler: @escaping MockURLProtocol.Handler
    ) throws -> (LiveAPIClient, Endpoint<Stop>) {
        let host = "test-\(UUID().uuidString).example"
        let session = MockURLProtocol.makeSession(host: host, handler: handler)
        let endpoint = Endpoint<Stop>(baseURL: try #require(URL(string: "https://\(host)")), path: "stop")
        return (LiveAPIClient(session: session), endpoint)
    }

    /// Creates an HTTP response for a request.
    /// - Parameters:
    ///   - request: The request being answered.
    ///   - statusCode: The HTTP status code.
    /// - Returns: The response.
    private static func response(for request: URLRequest, statusCode: Int) throws -> HTTPURLResponse {
        let url = try #require(request.url)
        return try #require(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil))
    }
}
