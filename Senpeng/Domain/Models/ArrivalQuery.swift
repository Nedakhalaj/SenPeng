import Foundation

/// What's needed to look up when a vehicle arrives at the user's destination.
///
/// It can be created from a departure when starting a trip, or from a saved trip,
/// so a trip can still be followed after the app restarts.
struct ArrivalQuery: Equatable, Sendable {

    /// The line, for example "14".
    let line: String

    /// When the vehicle should leave the origin stop, according to the timetable.
    let scheduledDeparture: Date

    /// SL's global ID of the stop the user gets on at.
    let originGlobalID: String

    /// SL's global ID of the stop the user gets off at.
    let destinationGlobalID: String

    /// Creates a query for a departure the user is about to start a trip on.
    /// - Parameters:
    ///   - departure: The chosen departure.
    ///   - origin: The stop where the user gets on.
    ///   - destination: The stop where the user gets off.
    init(departure: Departure, origin: Site, destination: Site) {
        line = departure.line
        scheduledDeparture = departure.scheduled
        originGlobalID = origin.globalID
        destinationGlobalID = destination.globalID
    }

    /// Creates a query for a saved trip.
    /// - Parameter trip: The saved trip.
    init(trip: Trip) {
        line = trip.line
        scheduledDeparture = trip.scheduledDeparture
        originGlobalID = trip.origin.globalID
        destinationGlobalID = trip.destination.globalID
    }
}
