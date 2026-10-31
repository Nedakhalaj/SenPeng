import Foundation
import Testing
@testable import Senpeng

/// Checks the requests sent to SL's journey planner.
@Suite("Journey planner API")
struct JourneyPlannerAPITests {

    @Test("A trip request asks for direct trips between the two stops, never from the cache")
    func directTripsRequest() throws {
        let date = try Date.ISO8601FormatStyle().parse("2026-10-31T13:58:00Z")

        let request = JourneyPlannerAPI.directTrips(
            from: "9091001000009192",
            to: "9091001000009001",
            departingAt: date
        ).makeRequest()

        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(components.host == "journeyplanner.integration.sl.se")
        #expect(components.path == "/v2/trips")
        #expect(query["name_origin"] == "9091001000009192")
        #expect(query["name_destination"] == "9091001000009001")
        #expect(query["max_changes"] == "0")
        #expect(query["itd_trip_date_time_dep_arr"] == "dep")
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test(
        "Date and time are sent in Stockholm time",
        arguments: [
            // Winter time, UTC+1.
            ("2026-10-31T13:58:00Z", "20261031", "1458"),
            // Summer time, UTC+2.
            ("2026-06-15T06:05:00Z", "20260615", "0805"),
            // Late evening UTC on New Year's Eve is already the next year in Stockholm.
            ("2026-12-31T23:30:00Z", "20270101", "0030")
        ]
    )
    func stockholmDateAndTime(utc: String, expectedDate: String, expectedTime: String) throws {
        let date = try Date.ISO8601FormatStyle().parse(utc)

        let request = JourneyPlannerAPI.directTrips(from: "1", to: "2", departingAt: date).makeRequest()

        let url = try #require(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.first { $0.name == "itd_date" }?.value == expectedDate)
        #expect(items.first { $0.name == "itd_time" }?.value == expectedTime)
    }
}
