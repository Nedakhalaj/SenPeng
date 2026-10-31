import Foundation
import Testing
@testable import Senpeng

/// Checks how a departure is matched to the journey planner's trips.
///
/// Uses `sl-trips.json`: real answers for Slussen → T-Centralen on 2026-10-31 (UTC):
/// - line 14 at 12:02:54, no live data: its "estimated" arrival only copies the timetable
/// - line 17 at 12:29:48, live: planned arrival 12:33:00, expected 12:33:18
/// - line 14 at 12:32:54, live: planned arrival 12:36:06, expected 12:35:36
/// - line 19 at 12:33:18, live: planned arrival 12:36:30, expected 12:36:54
@Suite("Live arrival repository")
struct LiveArrivalRepositoryTests {

    @Test("The departure on the same line at the same time gives its live arrival")
    func matchesDeparture() async throws {
        let arrival = try await lookUp(line: "19", scheduledUTC: "2026-10-31T12:33:18Z")

        #expect(arrival.scheduled == (try utc("2026-10-31T12:36:30Z")))
        #expect(arrival.expected == (try utc("2026-10-31T12:36:54Z")))
    }

    @Test("Without the live marker, the expected arrival is unknown, not the timetable's copy")
    func noLiveDataMeansUnknown() async throws {
        let arrival = try await lookUp(line: "14", scheduledUTC: "2026-10-31T12:02:54Z")

        #expect(arrival.scheduled == (try utc("2026-10-31T12:06:06Z")))
        #expect(arrival.expected == nil)
    }

    @Test("Another departure on the same line isn't mixed up with the chosen one")
    func picksTheRightTrip() async throws {
        let arrival = try await lookUp(line: "14", scheduledUTC: "2026-10-31T12:32:54Z")

        #expect(arrival.scheduled == (try utc("2026-10-31T12:36:06Z")))
        #expect(arrival.expected == (try utc("2026-10-31T12:35:36Z")))
    }

    @Test("A small difference in the timetable time still matches")
    func toleratesSmallDifference() async throws {
        let arrival = try await lookUp(line: "17", scheduledUTC: "2026-10-31T12:30:30Z")

        #expect(arrival.scheduled == (try utc("2026-10-31T12:33:00Z")))
    }

    @Test(
        "A departure that doesn't match any trip isn't on the route",
        arguments: [
            ("18", "2026-10-31T12:32:54Z"),
            ("14", "2026-10-31T13:30:00Z")
        ]
    )
    func notOnRoute(line: String, scheduledUTC: String) async throws {
        await #expect(throws: ArrivalLookupError.notOnRoute) {
            try await lookUp(line: line, scheduledUTC: scheduledUTC)
        }
    }

    @Test("A network error is passed on")
    func networkError() async throws {
        let repository = LiveArrivalRepository(apiClient: StubAPIClient(result: .failure(.offline)))
        let query = try makeQuery(line: "14", scheduledUTC: "2026-10-31T12:32:54Z")

        await #expect(throws: ArrivalLookupError.network(.offline)) {
            try await repository.arrival(for: query)
        }
    }

    @Test("Each error shows the right message to the user")
    func userFacingMessages() {
        #expect(ArrivalLookupError.notOnRoute.userFacingError == .notOnRoute)
        #expect(ArrivalLookupError.network(.offline).userFacingError == .offline)
        #expect(ArrivalLookupError.network(.cancelled).userFacingError == nil)
    }

    @Test("A query from a saved trip asks about that trip's line, time and stops")
    func queryFromTrip() {
        let trip = TripFactory.make()

        let query = ArrivalQuery(trip: trip)

        #expect(query.line == "14")
        #expect(query.scheduledDeparture == trip.scheduledDeparture)
        #expect(query.originGlobalID == "9091001000009192")
        #expect(query.destinationGlobalID == "9091001000009001")
    }

    /// Looks up a departure in the real answer in `sl-trips.json`.
    private func lookUp(line: String, scheduledUTC: String) async throws -> ArrivalEstimate {
        let data = try Fixture.data(named: "sl-trips")
        let response = try JSONDecoder().decode(TripsResponseDTO.self, from: data)
        let repository = LiveArrivalRepository(apiClient: StubAPIClient(result: .success(response)))
        return try await repository.arrival(for: try makeQuery(line: line, scheduledUTC: scheduledUTC))
    }

    /// A query for a departure from Slussen to T-Centralen, at a timetable time in UTC.
    private func makeQuery(line: String, scheduledUTC: String) throws -> ArrivalQuery {
        let departure = Departure(
            id: "test",
            journeyID: "test",
            line: line,
            transportMode: .metro,
            destination: "Mörby centrum",
            scheduled: try utc(scheduledUTC),
            expected: nil,
            isCancelled: false
        )
        return ArrivalQuery(
            departure: departure,
            origin: Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192"),
            destination: Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001")
        )
    }

    /// Reads a UTC time, for example `2026-10-31T13:59:24Z`.
    private func utc(_ text: String) throws -> Date {
        try Date.ISO8601FormatStyle().parse(text)
    }
}

/// An `APIClient` that always gives the same journey planner answer or error.
private struct StubAPIClient: APIClient {

    let result: Result<TripsResponseDTO, NetworkError>

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        guard let response = try result.get() as? Response else {
            throw .decoding
        }
        return response
    }
}
