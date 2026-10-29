import Foundation

/// Describes one request to a server and the type of answer it returns.
///
/// Example: an endpoint for the departures from a stop, which returns a
/// departures DTO. Endpoints only describe the request; `APIClient` sends it.
struct Endpoint<Response: Decodable & Sendable>: Sendable {

    /// The server address, for example `https://transport.integration.sl.se/v1`.
    let baseURL: URL

    /// The path after the base URL, for example `sites/9192/departures`.
    let path: String

    /// Query parameters added after `?` in the URL.
    let queryItems: [URLQueryItem]

    /// How the request may use cached answers.
    let cachePolicy: URLRequest.CachePolicy

    /// Creates an endpoint.
    /// - Parameters:
    ///   - baseURL: The server address.
    ///   - path: The path after the base URL.
    ///   - queryItems: Query parameters. Empty by default.
    ///   - cachePolicy: The cache rule. By default the server's cache headers decide.
    init(
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.cachePolicy = cachePolicy
    }

    /// Builds the `URLRequest` that is sent to the server.
    /// - Returns: A GET request that asks for JSON.
    func makeRequest() -> URLRequest {
        var url = baseURL.appending(path: path)
        if !queryItems.isEmpty {
            url.append(queryItems: queryItems)
        }

        var request = URLRequest(url: url, cachePolicy: cachePolicy)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
