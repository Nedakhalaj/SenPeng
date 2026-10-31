import Foundation
import Testing
@testable import Senpeng

/// Checks how real SL departure data is converted, filtered and sorted.
///
/// Uses `sl-departures.json`: four real departures from Slussen plus two made-up
/// ones that must be left out (not SL traffic, and an unknown vehicle type).
@Suite("Live departure repository")
struct LiveDepartureRepositoryTests {

    @Test("Only SL departures with a known vehicle type are kept")
    func filtersDepartures() async throws {
        let departures = try await loadFixture()

        #expect(departures.count == 4)
        #expect(!departures.contains { $0.destination == "Not SL" })
        #expect(!departures.contains { $0.destination == "Unknown mode" })
    }

    @Test("Departures are sorted by their best known time")
    func sortedByTime() async throws {
        let departures = try await loadFixture()

        #expect(departures.map(\.bestKnownTime) == departures.map(\.bestKnownTime).sorted())
    }

    @Test("A late bus keeps its scheduled and expected times")
    func lateBus() async throws {
        let bus = try #require(try await loadFixture().first { $0.line == "3" })

        #expect(bus.transportMode == .bus)
        #expect(bus.destination == "Karolinska sjukhuset")
        #expect(bus.journeyID == "2026103105866")
        #expect(bus.scheduled == StockholmTime.date(fromSL: "2026-10-31T12:29:00"))
        #expect(bus.minutesLate == 4)
        #expect(!bus.isCancelled)
    }

    @Test("A cancelled departure is marked as cancelled")
    func cancelled() async throws {
        let metro = try #require(try await loadFixture().first { $0.line == "17" })

        #expect(metro.isCancelled)
    }

    @Test("SL's ship type becomes a ferry")
    func ship() async throws {
        let ferry = try #require(try await loadFixture().first { $0.line == "82" })

        #expect(ferry.transportMode == .ferry)
    }

    /// Loads the departures in the fixture through the repository.
    private func loadFixture() async throws -> [Departure] {
        let data = try Fixture.data(named: "sl-departures")
        let response = try JSONDecoder().decode(DeparturesResponseDTO.self, from: data)
        let repository = LiveDepartureRepository(apiClient: FixedAPIClient(response: response))
        return try await repository.departures(siteID: "9192")
    }
}

/// An `APIClient` that always answers with the same departures response.
private struct FixedAPIClient: APIClient {

    let response: DeparturesResponseDTO

    func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        guard let response = response as? Response else {
            throw .decoding
        }
        return response
    }
}
