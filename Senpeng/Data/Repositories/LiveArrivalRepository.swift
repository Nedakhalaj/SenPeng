import Foundation

/// The real `ArrivalRepository`, which asks SL's journey planner.
///
/// It asks for direct trips from the origin to the destination around the departure
/// time, then picks the trip on the same line that leaves at the same time.
/// The direction doesn't need checking: a trip in the other direction never
/// reaches the destination without a transfer, so the planner doesn't return it.
struct LiveArrivalRepository: ArrivalRepository {

    /// How far apart the planner's and the departure list's timetable times may be
    /// and still mean the same departure. Both come from the same timetable, so they
    /// normally match to the second; 90 seconds allows for rounding.
    private static let matchTolerance: TimeInterval = 90

    /// Sends the requests.
    private let apiClient: any APIClient

    /// Creates the repository.
    /// - Parameter apiClient: Sends the requests.
    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func arrival(for query: ArrivalQuery) async throws(ArrivalLookupError) -> ArrivalEstimate {
        // Ask from one minute before, so the chosen departure is among the first results.
        let endpoint = JourneyPlannerAPI.directTrips(
            from: query.originGlobalID,
            to: query.destinationGlobalID,
            departingAt: query.scheduledDeparture.addingTimeInterval(-60)
        )

        let response: TripsResponseDTO
        do {
            response = try await apiClient.send(endpoint)
        } catch {
            throw .network(error)
        }

        guard let estimate = Self.match(query, in: response) else {
            throw .notOnRoute
        }
        return estimate
    }

    /// Finds the leg that is the queried departure, and returns its arrival times.
    /// - Parameters:
    ///   - query: The departure the user is on.
    ///   - response: The journey planner's answer.
    /// - Returns: The arrival at the destination, or `nil` if no leg matches.
    private static func match(_ query: ArrivalQuery, in response: TripsResponseDTO) -> ArrivalEstimate? {
        let legs = (response.journeys ?? []).flatMap(\.legs)
        for leg in legs {
            guard
                leg.transportation?.disassembledName == query.line,
                let plannedDeparture = date(from: leg.origin.departureTimePlanned),
                abs(plannedDeparture.timeIntervalSince(query.scheduledDeparture)) <= matchTolerance,
                let plannedArrival = date(from: leg.destination.arrivalTimePlanned)
            else {
                continue
            }
            // Estimated times without the live marker are copies of the timetable.
            let isLive = leg.isRealtimeControlled == true
            return ArrivalEstimate(
                scheduled: plannedArrival,
                expected: isLive ? date(from: leg.destination.arrivalTimeEstimated) : nil
            )
        }
        return nil
    }

    /// Reads one of the planner's UTC times, for example `2026-10-31T13:59:24Z`.
    private static func date(from text: String?) -> Date? {
        text.flatMap { try? Date.ISO8601FormatStyle().parse($0) }
    }
}
