import Foundation

/// Reads and shows times in Stockholm time, whatever time zone the phone is set to.
///
/// SL sends times without a time zone (for example `2026-10-31T12:30:00`),
/// meaning local Stockholm time. Delays and deadlines must be calculated from
/// the same clock SL uses.
enum StockholmTime {

    /// The Europe/Stockholm time zone, with summer and winter time.
    ///
    /// The identifier is part of the system's time zone database, so the fallback
    /// is never used in practice; it only avoids a force unwrap.
    static let timeZone = TimeZone(identifier: "Europe/Stockholm") ?? .current

    /// A Gregorian calendar in Stockholm time, for date math such as claim deadlines.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    /// Reads SL's date-time format: year-month-day, "T", hours:minutes:seconds, no time zone.
    private static let slFormat = Date.ISO8601FormatStyle(timeZone: timeZone)
        .year()
        .month()
        .day()
        .time(includingFractionalSeconds: false)

    /// Shows a time of day, for example "12:33", in Stockholm time and the user's locale.
    static let clockTime = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone)

    /// Reads a date-time from SL's API.
    /// - Parameter text: The time as SL sends it, for example `2026-10-31T12:30:00`.
    /// - Returns: The moment in time, or `nil` if the text isn't in SL's format.
    static func date(fromSL text: String) -> Date? {
        try? slFormat.parse(text)
    }
}
