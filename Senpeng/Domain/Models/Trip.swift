import Foundation

/// One trip the user saved with "I'm on this train".
///
/// Holds everything needed later to check the delay and fill in the SL claim form.
struct Trip: Identifiable, Equatable, Sendable {

    /// A unique ID for the trip on this device.
    let id: UUID

    /// The line, for example "14" or "43".
    let line: String

    /// The kind of vehicle.
    let transportMode: TransportMode

    /// Where the vehicle is heading, for example "Mörby centrum".
    let lineDestination: String

    /// SL's ID for this exact journey, used to look up its real arrival time later.
    let journeyID: String?

    /// The stop where the user got on.
    let origin: TransportStop

    /// The stop where the user gets off.
    let destination: TransportStop

    /// When the vehicle should leave the origin stop, according to the timetable.
    let scheduledDeparture: Date

    /// When the vehicle should arrive at the user's destination, according to the timetable.
    let scheduledArrival: Date

    /// When the vehicle really arrived at the user's destination, once known.
    var actualArrival: Date?

    /// How `actualArrival` was found out, once known.
    var delaySource: DelaySource?

    /// Whether the user has claimed delay money for this trip.
    var claimStatus: ClaimStatus

    /// When the user saved the trip.
    let createdAt: Date

    /// Creates a trip.
    /// - Parameters:
    ///   - id: A unique ID. A new one is created by default.
    ///   - line: The line, for example "14".
    ///   - transportMode: The kind of vehicle.
    ///   - lineDestination: Where the vehicle is heading.
    ///   - journeyID: SL's ID for this journey, if known.
    ///   - origin: The stop where the user got on.
    ///   - destination: The stop where the user gets off.
    ///   - scheduledDeparture: Timetable departure from the origin.
    ///   - scheduledArrival: Timetable arrival at the destination.
    ///   - actualArrival: Real arrival at the destination, if known.
    ///   - delaySource: How the real arrival was found out, if known.
    ///   - claimStatus: Whether a claim has been submitted.
    ///   - createdAt: When the trip was saved.
    init(
        id: UUID = UUID(),
        line: String,
        transportMode: TransportMode,
        lineDestination: String,
        journeyID: String?,
        origin: TransportStop,
        destination: TransportStop,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        actualArrival: Date? = nil,
        delaySource: DelaySource? = nil,
        claimStatus: ClaimStatus = .notSubmitted,
        createdAt: Date
    ) {
        self.id = id
        self.line = line
        self.transportMode = transportMode
        self.lineDestination = lineDestination
        self.journeyID = journeyID
        self.origin = origin
        self.destination = destination
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.actualArrival = actualArrival
        self.delaySource = delaySource
        self.claimStatus = claimStatus
        self.createdAt = createdAt
    }

    /// How late the vehicle arrived at the user's destination, or `nil` while unknown.
    ///
    /// SL judges delay at the destination, not at departure. An early arrival
    /// gives a negative value.
    var arrivalDelay: Duration? {
        guard let actualArrival else {
            return nil
        }
        return .seconds(actualArrival.timeIntervalSince(scheduledArrival))
    }

    /// How many whole minutes late the vehicle arrived, or `nil` while unknown. Never negative.
    var minutesLate: Int? {
        guard let actualArrival else {
            return nil
        }
        return max(0, Int(actualArrival.timeIntervalSince(scheduledArrival) / 60))
    }

    /// Whether the user is still on this trip, so the app should follow it.
    ///
    /// A trip stops being followed once its real arrival is known, or 2 hours after
    /// its planned arrival. Longer delays are rare, and live data is gone by then.
    ///
    /// - Parameter date: The current time.
    /// - Returns: `true` while the trip should be followed.
    func isActive(at date: Date) -> Bool {
        let followingEnds = scheduledArrival.addingTimeInterval(2 * 60 * 60)
        return actualArrival == nil && date <= followingEnds
    }
}
