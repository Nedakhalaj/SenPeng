import Foundation

/// When a vehicle arrives at the user's destination: by the timetable, and live.
struct ArrivalEstimate: Equatable, Sendable {

    /// The arrival time in the timetable. SL's delay compensation is measured from this.
    let scheduled: Date

    /// The expected arrival time from live data, or `nil` when SL has no live data for the
    /// vehicle. Without live data the delay is unknown; it must never be assumed to be zero.
    let expected: Date?

    /// How many whole minutes late the vehicle is expected, or `nil` without live data.
    /// Never negative.
    var expectedMinutesLate: Int? {
        guard let expected else {
            return nil
        }
        return max(0, Int(expected.timeIntervalSince(scheduled) / 60))
    }

    /// How late the vehicle is expected to arrive, or `nil` without live data.
    /// An early arrival gives a negative value.
    var expectedDelay: Duration? {
        guard let expected else {
            return nil
        }
        return .seconds(expected.timeIntervalSince(scheduled))
    }
}
