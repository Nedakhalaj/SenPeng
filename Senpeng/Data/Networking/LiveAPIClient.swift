import Foundation
import os

/// The real `APIClient`, which sends requests over the internet with `URLSession`.
///
/// The work runs off the main thread, so the UI stays smooth while
/// waiting for the server and decoding JSON.
struct LiveAPIClient: APIClient {

    /// The session that sends the requests.
    private let session: URLSession

    /// Creates a client.
    /// - Parameter session: The session to use. Tests pass a session with a fake network.
    init(session: URLSession) {
        self.session = session
    }

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        let request = endpoint.makeRequest()

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
        guard (200..<300).contains(httpResponse.statusCode) else {
            Logger.networking.error("Server error: \(httpResponse.statusCode, privacy: .public)")
            throw .server(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            // The full decoding error may contain travel data, so it is only logged privately.
            Logger.networking.error("Decoding failed: \(String(describing: error), privacy: .private)")
            throw .decoding
        }
    }
}
