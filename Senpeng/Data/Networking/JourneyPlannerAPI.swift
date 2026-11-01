import Foundation

/// Endpoints of SL's Journey Planner v2. No API key is needed.
///
/// Docs: https://www.trafiklab.se/api/our-apis/sl/journey-planner-2/
/// Request parameters and response format checked against the live API on 2026-10-31.
enum JourneyPlannerAPI {

    /// The API's base address.
    ///
    /// The `!` is safe here: the text is a fixed, valid address that never changes
    /// at runtime, and `JourneyPlannerAPITests` checks it on every CI run.
    static let baseURL = URL(string: "https://journeyplanner.integration.sl.se/v2")!

    /// Direct trips (no transfers) between two stops, leaving at or after a time.
    ///
    /// Each trip has the planned and live expected departure and arrival, also at
    /// the end of a line, where the departures list can't help.
    ///
    /// - Parameters:
    ///   - originGlobalID: SL's global ID of the stop the user gets on at.
    ///   - destinationGlobalID: SL's global ID of the stop the user gets off at.
    ///   - date: The earliest departure time.
    /// - Returns: An endpoint returning up to three trips.
    static func directTrips(
        from originGlobalID: String,
        to destinationGlobalID: String,
        departingAt date: Date
    ) -> Endpoint<TripsResponseDTO> {
        let parts = StockholmTime.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let day = String(format: "%04ld%02ld%02ld", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        let time = String(format: "%02ld%02ld", parts.hour ?? 0, parts.minute ?? 0)

        return Endpoint(
            baseURL: baseURL,
            path: "trips",
            queryItems: [
                URLQueryItem(name: "type_origin", value: "any"),
                URLQueryItem(name: "name_origin", value: originGlobalID),
                URLQueryItem(name: "type_destination", value: "any"),
                URLQueryItem(name: "name_destination", value: destinationGlobalID),
                // The planner reads date and time as Stockholm local time.
                URLQueryItem(name: "itd_date", value: day),
                URLQueryItem(name: "itd_time", value: time),
                URLQueryItem(name: "itd_trip_date_time_dep_arr", value: "dep"),
                URLQueryItem(name: "max_changes", value: "0"),
                URLQueryItem(name: "calc_number_of_trips", value: "3")
            ],
            // Live arrival estimates must always be fresh, so the cache is never used.
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }
}
