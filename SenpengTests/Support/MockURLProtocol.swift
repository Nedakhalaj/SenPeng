import Foundation
import os

/// A fake network for tests: answers requests with prepared responses
/// instead of going to the internet.
///
/// Each test registers a handler for its own unique host, so tests can run
/// in parallel without seeing each other's responses.
final class MockURLProtocol: URLProtocol {

    /// Builds the fake answer for a request, or throws to simulate a network failure.
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    /// Registered handlers, keyed by host. Locked because tests run in parallel.
    private static let handlers = OSAllocatedUnfairLock<[String: Handler]>(initialState: [:])

    /// Registers a handler for one host and returns a session that uses the fake network.
    /// - Parameters:
    ///   - host: A host name unique to the test, for example `test-<UUID>.example`.
    ///   - handler: Builds the answer for each request to that host.
    /// - Returns: A URL session whose requests go to `MockURLProtocol`.
    static func makeSession(host: String, handler: @escaping Handler) -> URLSession {
        handlers.withLock { $0[host] = handler }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let host = request.url?.host() ?? ""
        guard let handler = Self.handlers.withLock({ $0[host] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
