import Foundation

extension URLSession {

    /// Creates the URL session the app uses for all requests.
    ///
    /// Create it once (in the app's dependency container) and reuse it,
    /// so connections and the cache are shared.
    ///
    /// - Returns: A session with short timeouts and a small cache.
    static func makeSenpengSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        // Travel data is only useful while it's fresh; fail fast and let the user retry.
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        // Small cache for stop data and repeated requests; the server's headers decide what is kept.
        configuration.urlCache = URLCache(
            memoryCapacity: 5 * 1_024 * 1_024,
            diskCapacity: 20 * 1_024 * 1_024
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }
}
