import Foundation
import os

/// The real `APIClient`, which sends requests over the internet with `URLSession`.
///
/// The work runs off the main thread, so the UI stays smooth while
/// waiting for the server and decoding JSON.
struct LiveAPIClient: APIClient {

    /// The session that sends the requests.
    private let session: URLSession

    /// Holds back requests to a server that has answered "too many requests".
    private let rateLimitGate: RateLimitGate

    /// The HTTP status code for "too many requests".
    private static let tooManyRequests = 429

    /// Creates a client.
    /// - Parameters:
    ///   - session: The session to use. Tests pass a session with a fake network.
    ///   - rateLimitGate: Holds back requests after "too many requests".
    init(session: URLSession, rateLimitGate: RateLimitGate = RateLimitGate()) {
        self.session = session
        self.rateLimitGate = rateLimitGate
    }

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        let request = endpoint.makeRequest()
        let host = request.url?.host() ?? ""

        // Checked here so that every caller is covered: refreshes, "Try again" and pull-to-refresh.
        guard await !rateLimitGate.isPaused(host: host) else {
            throw .rateLimited
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let networkError = NetworkError(error)
            Logger.networking.error("Request failed: \(String(describing: networkError), privacy: .public)")
            throw networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }
        if httpResponse.statusCode == Self.tooManyRequests {
            let pause = await rateLimitGate.recordRateLimited(
                host: host,
                retryAfter: httpResponse.value(forHTTPHeaderField: "Retry-After")
            )
            Logger.networking.notice("Too many requests; pausing for \(pause, privacy: .public) s")
            throw .rateLimited
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            Logger.networking.error("Server error: \(httpResponse.statusCode, privacy: .public)")
            throw .server(statusCode: httpResponse.statusCode)
        }
        await rateLimitGate.recordSuccess(host: host)

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            // The full decoding error may contain travel data, so it is only logged privately.
            Logger.networking.error("Decoding failed: \(String(describing: error), privacy: .private)")
            throw .decoding
        }
    }
}
