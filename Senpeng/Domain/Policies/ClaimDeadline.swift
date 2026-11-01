import Foundation

/// The last day a user can claim delay money for a trip, in Stockholm time.
struct ClaimDeadline: Equatable, Sendable {

    /// The start of the last day to claim, in Stockholm time.
    /// The whole day counts, so a claim that evening is still in time.
    let lastDay: Date

    /// Calculates the deadline for a trip.
    /// - Parameters:
    ///   - tripDate: When the trip was due to arrive.
    ///   - months: How many calendar months the user can claim.
    /// - Returns: The deadline, or `nil` if the date can't be calculated.
    static func make(tripDate: Date, months: Int) -> ClaimDeadline? {
        let calendar = StockholmTime.calendar
        // Calendar math handles short months: 3 months after 30 November is 28 February.
        guard let date = calendar.date(byAdding: .month, value: months, to: tripDate) else {
            return nil
        }
        return ClaimDeadline(lastDay: calendar.startOfDay(for: date))
    }

    /// Whole calendar days until the last day: 0 on the last day itself, negative after it.
    /// - Parameter date: The current time.
    /// - Returns: The number of days left.
    func daysLeft(at date: Date) -> Int {
        let calendar = StockholmTime.calendar
        let today = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: lastDay).day ?? 0
    }

    /// Whether the last day is over.
    /// - Parameter date: The current time.
    /// - Returns: `true` from the day after the last day.
    func hasPassed(at date: Date) -> Bool {
        daysLeft(at: date) < 0
    }
}
