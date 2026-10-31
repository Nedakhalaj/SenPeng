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
