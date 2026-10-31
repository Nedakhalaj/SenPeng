import Foundation

/// One upcoming departure from a stop, from SL's real-time data.
struct Departure: Identifiable, Equatable, Sendable {

    /// A unique ID within one list of departures.
    let id: String

    /// SL's ID for this exact journey, saved with a trip to look up its real arrival later.
    let journeyID: String

    /// The line, for example "14".
    let line: String

    /// The kind of vehicle.
    let transportMode: TransportMode

    /// Where the vehicle is heading, for example "Mörby centrum".
    let destination: String

    /// When it should leave, according to the timetable.
    let scheduled: Date

    /// When it's expected to leave according to real-time data, if known.
    let expected: Date?

    /// Whether SL has cancelled this departure.
    let isCancelled: Bool

    /// The best known departure time: expected if known, otherwise scheduled.
    var bestKnownTime: Date {
        expected ?? scheduled
    }

    /// How many whole minutes later than the timetable it leaves. Never negative.
    ///
    /// This is only shown as information. Compensation depends on the delay at
    /// the user's destination, not at departure.
    var minutesLate: Int {
        guard let expected else {
            return 0
        }
        return max(0, Int(expected.timeIntervalSince(scheduled) / 60))
    }
}
