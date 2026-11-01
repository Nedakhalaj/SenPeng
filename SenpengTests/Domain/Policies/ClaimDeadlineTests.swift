import Foundation
import Testing
@testable import Senpeng

/// Checks the last day to claim, in calendar months and Stockholm time.
@Suite("Claim deadline")
struct ClaimDeadlineTests {

    @Test(
        "The last day is 3 calendar months after the trip",
        arguments: [
            (stockholmDate(2026, 10, 15), stockholmDate(2027, 1, 15, 0)),
            // Short months: there's no 30 or 31 February.
            (stockholmDate(2026, 11, 30), stockholmDate(2027, 2, 28, 0)),
            (stockholmDate(2026, 11, 29), stockholmDate(2027, 2, 28, 0)),
            // A leap year has a 29 February.
            (stockholmDate(2027, 11, 30), stockholmDate(2028, 2, 29, 0)),
            // Late evening in Stockholm is still that day, even though it's another day in UTC.
            (stockholmDate(2026, 12, 31, 23, 30), stockholmDate(2027, 3, 31, 0)),
            (stockholmDate(2026, 7, 1, 0, 30), stockholmDate(2026, 10, 1, 0))
        ]
    )
    func lastDay(trip: Date, expected: Date) throws {
        let deadline = try #require(ClaimDeadline.make(tripDate: trip, months: 3))

        #expect(deadline.lastDay == expected)
    }

    @Test(
        "Days left count calendar days, also across the change to summer time",
        arguments: [
            (stockholmDate(2027, 3, 27, 23, 59), 1),
            (stockholmDate(2027, 3, 28, 0, 0), 0),
            (stockholmDate(2027, 3, 28, 23, 59), 0),
            (stockholmDate(2027, 3, 29, 0, 0), -1),
            (stockholmDate(2027, 3, 1, 12, 0), 27)
        ]
    )
    func daysLeft(now: Date, expected: Int) {
        // Summer time starts on 28 March 2027, so that day has only 23 hours.
        let deadline = ClaimDeadline(lastDay: stockholmDate(2027, 3, 28, 0))

        #expect(deadline.daysLeft(at: now) == expected)
    }

    @Test(
        "The whole last day counts; the deadline has passed from the next day",
        arguments: [
            (stockholmDate(2027, 1, 31, 23, 59), false),
            (stockholmDate(2027, 2, 1, 0, 0), true)
        ]
    )
    func hasPassed(now: Date, expected: Bool) {
        let deadline = ClaimDeadline(lastDay: stockholmDate(2027, 1, 31, 0))

        #expect(deadline.hasPassed(at: now) == expected)
    }
}
