import Foundation

/// When a vehicle arrives at the user's destination: by the timetable, and live.
struct ArrivalEstimate: Equatable, Sendable {

    /// The arrival time in the timetable. SL's delay compensation is measured from this.
    let scheduled: Date

    /// The live expected arrival time, if SL has one.
    let expected: Date?

    /// How late the vehicle is expected to arrive, or `nil` without live data.
    /// An early arrival gives a negative value.
    var expectedDelay: Duration? {
        guard let expected else {
            return nil
        }
        return .seconds(expected.timeIntervalSince(scheduled))
    }
}
