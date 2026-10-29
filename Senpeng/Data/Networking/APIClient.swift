import Foundation

/// Sends requests to a server and decodes the answers.
///
/// Repositories depend on this protocol instead of the real network,
/// so tests and previews can use a fake client.
protocol APIClient: Sendable {

    /// Sends the request described by an endpoint and decodes the answer.
    /// - Parameter endpoint: The request to send and the expected answer type.
    /// - Returns: The decoded answer.
    /// - Throws: A `NetworkError` that says what went wrong.
    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response
}
