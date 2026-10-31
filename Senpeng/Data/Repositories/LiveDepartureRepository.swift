import Foundation

/// The real `DepartureRepository`, which asks SL's Transport API every time.
///
/// Departures are never cached: real-time data is only useful while it's fresh.
struct LiveDepartureRepository: DepartureRepository {

    /// Sends the requests.
    private let apiClient: any APIClient

    /// Creates the repository.
    /// - Parameter apiClient: Sends the requests.
    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func departures(siteID: String) async throws(NetworkError) -> [Departure] {
        let response = try await apiClient.send(SLTransportAPI.departures(siteID: siteID))
        // Departures that aren't SL traffic or can't be read are left out (see `toDeparture()`).
        return response.departures
            .compactMap { $0.toDeparture() }
            .sorted { $0.bestKnownTime < $1.bestKnownTime }
    }
}
