import Foundation

/// The answer of SL's Transport API for a stop's departures (`GET /sites/{id}/departures`).
struct DeparturesResponseDTO: Decodable, Sendable {

    /// The upcoming departures.
    let departures: [DepartureDTO]
}

/// The journey a departure belongs to, as SL's Transport API sends it.
struct JourneyDTO: Decodable, Sendable {
    let id: Int
}

/// The line of a departure and who runs it, as SL's Transport API sends it.
struct LineDTO: Decodable, Sendable {
    let designation: String
    let transportAuthorityID: Int
    let transportMode: String

    private enum CodingKeys: String, CodingKey {
        case designation
        case transportAuthorityID = "transport_authority_id"
        case transportMode = "transport_mode"
    }
}

/// One departure as SL's Transport API sends it. Only the fields the app uses are decoded.
struct DepartureDTO: Decodable, Sendable {

    /// SL's transport authority ID. Only SL's own traffic is covered by SL's delay compensation.
    private static let slAuthorityID = 1

    let destination: String
    let scheduled: String
    let expected: String?
    let state: String?
    let journey: JourneyDTO
    let line: LineDTO

    /// Converts the DTO to the app's own model.
    /// - Returns: The departure, or `nil` if it isn't SL traffic, the vehicle type is
    ///   unknown, or the scheduled time can't be read.
    func toDeparture() -> Departure? {
        guard
            line.transportAuthorityID == Self.slAuthorityID,
            let mode = Self.transportMode(from: line.transportMode),
            let scheduledDate = StockholmTime.date(fromSL: scheduled)
        else {
            return nil
        }

        let journeyID = String(journey.id)
        return Departure(
            id: "\(journeyID)-\(scheduled)",
            journeyID: journeyID,
            line: line.designation,
            transportMode: mode,
            destination: destination,
            scheduled: scheduledDate,
            expected: expected.flatMap(StockholmTime.date(fromSL:)),
            isCancelled: state == "CANCELLED"
        )
    }

    /// Converts SL's vehicle type to the app's `TransportMode`.
    /// - Parameter code: SL's value, for example "METRO".
    /// - Returns: The mode, or `nil` for a type the app doesn't know.
    private static func transportMode(from code: String) -> TransportMode? {
        switch code {
        case "METRO": .metro
        case "BUS": .bus
        case "TRAIN": .train
        case "TRAM": .tram
        case "SHIP", "FERRY": .ferry
        default: nil
        }
    }
}
