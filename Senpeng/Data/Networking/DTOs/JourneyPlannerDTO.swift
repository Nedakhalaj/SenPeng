import Foundation

/// The answer of SL's journey planner for trips between two stops (`GET /trips`).
/// Only the fields the app uses are decoded.
struct TripsResponseDTO: Decodable, Sendable {

    /// The suggested trips. Missing when the planner finds none.
    let journeys: [PlannerJourneyDTO]?
}

/// One suggested trip, made of one or more legs.
struct PlannerJourneyDTO: Decodable, Sendable {
    let legs: [PlannerLegDTO]
}

/// One part of a trip, on one vehicle or on foot.
struct PlannerLegDTO: Decodable, Sendable {
    let origin: PlannerStopDTO
    let destination: PlannerStopDTO

    /// The vehicle. Missing or without a line for walking legs.
    let transportation: PlannerTransportationDTO?

    /// `true` when the leg's estimated times come from live data.
    ///
    /// Without it, the planner still sends estimated times, but they are only copies of
    /// the timetable (checked against the live API on 2026-10-31), so they must not be
    /// trusted: a late vehicle would look on time. SL leaves the field out when it's not
    /// live, so it has to be optional here.
    let isRealtimeControlled: Bool? // swiftlint:disable:this discouraged_optional_boolean
}

/// Where a leg starts or ends, with times in UTC, for example `2026-10-31T13:59:24Z`.
struct PlannerStopDTO: Decodable, Sendable {
    let departureTimePlanned: String?
    let departureTimeEstimated: String?
    let arrivalTimePlanned: String?
    let arrivalTimeEstimated: String?
}

/// The vehicle of a leg.
struct PlannerTransportationDTO: Decodable, Sendable {

    /// The line, for example "14".
    let disassembledName: String?
}
