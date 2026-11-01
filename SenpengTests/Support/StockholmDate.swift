import Foundation
@testable import Senpeng

/// Creates a moment in Stockholm time, so date tests read like a calendar.
/// - Parameters:
///   - year: The year.
///   - month: The month, 1–12.
///   - day: The day of the month.
///   - hour: The hour, 0–23.
///   - minute: The minute.
/// - Returns: The moment, or the distant past if the date doesn't exist, which fails the test.
func stockholmDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return StockholmTime.calendar.date(from: components) ?? .distantPast
}
