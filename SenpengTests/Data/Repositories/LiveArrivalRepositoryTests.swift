import Foundation
import Testing
@testable import Senpeng

/// Checks how a departure is matched to the journey planner's trips.
///
/// Uses `sl-trips.json`: a real answer for Slussen → T-Centralen with three direct
/// trips: line 14 at 13:59:24, line 18 at 14:01:48 and line 14 at 14:02:54 (UTC).
@Suite("Live arrival repository")
struct LiveArrivalRepositoryTests {

    private let slussen = Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192")
    private let centralen = Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001")

    @Test("The departure on the same line at the same time gives its arrival times")
    func matchesDeparture() async throws {
        let departure = try makeDeparture(line: "14", scheduledUTC: "2026-10-31T13:59:24Z")

        let arrival = try await repository().arrival(of: departure, from: slussen, to: centralen)

        #expect(arrival.scheduled == (try utc("2026-10-31T14:02:36Z")))
        #expect(arrival.expected == (try utc("2026-10-31T14:02:36Z")))
    }

    @Test("The next departure on the same line isn't mixed up with the chosen one")
    func picksTheRightTrip() async throws {
        let departure = try makeDeparture(line: "14", scheduledUTC: "2026-10-31T14:02:54Z")

        let arrival = try await repository().arrival(of: departure, from: slussen, to: centralen)

        #expect(arrival.scheduled == (try utc("2026-10-31T14:06:06Z")))
    }

    @Test("A small difference in the timetable time still matches")
    func toleratesSmallDifference() async throws {
        let departure = try makeDeparture(line: "18", scheduledUTC: "2026-10-31T14:02:30Z")

        let arrival = try await repository().arrival(of: departure, from: slussen, to: centralen)

        #expect(arrival.scheduled == (try utc("2026-10-31T14:05:00Z")))
    }

    @Test(
        "A departure that doesn't match any trip isn't on the route",
        arguments: [
            ("19", "2026-10-31T13:59:24Z"),
            ("14", "2026-10-31T14:30:00Z")
        ]
    )
    func notOnRoute(line: String, scheduledUTC: String) async throws {
        let departure = try makeDeparture(line: line, scheduledUTC: scheduledUTC)

        await #expect(throws: ArrivalLookupError.notOnRoute) {
            try await repository().arrival(of: departure, from: slussen, to: centralen)
        }
    }

    @Test("A network error is passed on")
    func networkError() async throws {
        let departure = try makeDeparture(line: "14", scheduledUTC: "2026-10-31T13:59:24Z")
        let repository = LiveArrivalRepository(apiClient: StubAPIClient(result: .failure(.offline)))

        await #expect(throws: ArrivalLookupError.network(.offline)) {
            try await repository.arrival(of: departure, from: slussen, to: centralen)
        }
    }

    @Test("Each error shows the right message to the user")
    func userFacingMessages() {
        #expect(ArrivalLookupError.notOnRoute.userFacingError == .notOnRoute)
        #expect(ArrivalLookupError.network(.offline).userFacingError == .offline)
        #expect(ArrivalLookupError.network(.cancelled).userFacingError == nil)
    }

    /// A repository that gets the real answer in `sl-trips.json`.
    private func repository() throws -> LiveArrivalRepository {
        let data = try Fixture.data(named: "sl-trips")
        let response = try JSONDecoder().decode(TripsResponseDTO.self, from: data)
        return LiveArrivalRepository(apiClient: StubAPIClient(result: .success(response)))
    }

    /// A departure from Slussen on a line at a timetable time given in UTC.
    private func makeDeparture(line: String, scheduledUTC: String) throws -> Departure {
        Departure(
            id: "test",
            journeyID: "test",
            line: line,
            transportMode: .metro,
            destination: "Mörby centrum",
            scheduled: try utc(scheduledUTC),
            expected: nil,
            isCancelled: false
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
