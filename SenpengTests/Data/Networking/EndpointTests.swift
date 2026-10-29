import Foundation
import Testing
@testable import Senpeng

/// Checks that endpoints build the right requests.
@Suite("Endpoint")
struct EndpointTests {

    /// A placeholder answer type; these tests only build requests.
    private struct Empty: Decodable, Sendable {}

    private let baseURL = URL(string: "https://example.com/v1")

    @Test("Path and query items are added to the URL")
    func buildsURL() throws {
        let endpoint = Endpoint<Empty>(
            baseURL: try #require(baseURL),
            path: "sites/9192/departures",
            queryItems: [URLQueryItem(name: "forecast", value: "60")]
        )

        let request = endpoint.makeRequest()

        #expect(request.url?.absoluteString == "https://example.com/v1/sites/9192/departures?forecast=60")
    }

    @Test("No question mark is added without query items")
    func buildsURLWithoutQuery() throws {
        let endpoint = Endpoint<Empty>(baseURL: try #require(baseURL), path: "sites")

        let request = endpoint.makeRequest()

        #expect(request.url?.absoluteString == "https://example.com/v1/sites")
    }

    @Test("Request is a GET that asks for JSON")
    func usesGETAndJSON() throws {
        let endpoint = Endpoint<Empty>(baseURL: try #require(baseURL), path: "sites")

        let request = endpoint.makeRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
