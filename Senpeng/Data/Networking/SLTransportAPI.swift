import Foundation

/// Endpoints of SL's Transport API (stops and real-time departures). No API key is needed.
///
/// Docs: https://www.trafiklab.se/api/our-apis/sl/transport/
/// Response format checked against the live API on 2026-10-31.
enum SLTransportAPI {

    /// The API's base address.
    ///
    /// The `!` is safe here: the text is a fixed, valid address that never changes
    /// at runtime, and `SLTransportAPITests` checks it on every CI run.
    static let baseURL = URL(string: "https://transport.integration.sl.se/v1")!

    /// All of SL's stops (about 6 500, about 330 KB compressed).
    ///
    /// The list rarely changes, so the app downloads it once and keeps it for a week.
    static func sites() -> Endpoint<[SiteDTO]> {
        Endpoint(
            baseURL: baseURL,
            path: "sites",
            // "expand=false" leaves out the platform details, which keeps the answer small.
            queryItems: [URLQueryItem(name: "expand", value: "false")]
        )
    }

    /// The departures from a stop in the next hour, with real-time expected times.
    /// - Parameter siteID: SL's site ID, for example "9192" for Slussen.
    static func departures(siteID: String) -> Endpoint<DeparturesResponseDTO> {
        Endpoint(
            baseURL: baseURL,
            path: "sites/\(siteID)/departures",
            queryItems: [URLQueryItem(name: "forecast", value: "60")],
            // Real-time data must always be fresh, so the cache is never used.
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }
}
