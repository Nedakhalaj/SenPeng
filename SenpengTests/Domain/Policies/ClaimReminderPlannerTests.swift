import Foundation
import Testing
@testable import Senpeng

/// Checks when reminders are planned before the last day to claim.
@Suite("Claim reminder planner")
struct ClaimReminderPlannerTests {

    private let planner = ClaimReminderPlanner()
    private let trip = TripFactory.make(arrivalDelay: 25 * 60)

    /// A deadline with its last day on the given date.
    private func eligible(_ year: Int, _ month: Int, _ day: Int) -> EligibilityResult {
        .eligible(ClaimDeadline(lastDay: stockholmDate(year, month, day, 0)), alternativeTravelCap: 1_480)
    }

    @Test("A trip gets reminders 14 and 3 days before the last day, at 10:00 in Stockholm")
    func twoReminders() {
        let reminders = planner.reminders(for: trip, eligibility: eligible(2027, 1, 31), now: stockholmDate(2026, 11, 2))

        #expect(reminders.map(\.date) == [stockholmDate(2027, 1, 17, 10), stockholmDate(2027, 1, 28, 10)])
        #expect(reminders.map(\.daysLeft) == [14, 3])
    }

    @Test("A reminder stays at 10:00 across the change to summer time")
    func summerTime() {
        // Summer time starts on 28 March 2027, between the first reminder and the last day.
        let reminders = planner.reminders(for: trip, eligibility: eligible(2027, 4, 5), now: stockholmDate(2027, 1, 1))

        #expect(reminders.map(\.date) == [stockholmDate(2027, 3, 22, 10), stockholmDate(2027, 4, 2, 10)])
    }

    @Test("Reminders that would already have passed are left out")
    func passedReminders() {
        let deadline = eligible(2027, 1, 31)

        let afterFirst = planner.reminders(for: trip, eligibility: deadline, now: stockholmDate(2027, 1, 17, 10))
        let afterBoth = planner.reminders(for: trip, eligibility: deadline, now: stockholmDate(2027, 1, 28, 10))

        #expect(afterFirst.map(\.daysLeft) == [3])
        #expect(afterBoth.isEmpty)
    }

    @Test(
        "Only trips the user may claim for get reminders",
        arguments: [
            EligibilityResult.delayTooShort,
            .expired,
            .submitted,
            .delayUnknown(ClaimDeadline(lastDay: stockholmDate(2027, 1, 31, 0)))
        ]
    )
    func onlyEligibleTrips(result: EligibilityResult) {
        #expect(planner.reminders(for: trip, eligibility: result, now: stockholmDate(2026, 11, 2)).isEmpty)
    }

    @Test("A reminder names the trip, and has an ID the system can replace it by")
    func reminderContent() throws {
        let reminder = try #require(
            planner.reminders(for: trip, eligibility: eligible(2027, 1, 31), now: stockholmDate(2026, 11, 2)).first
        )

        #expect(reminder.originName == "Slussen")
        #expect(reminder.destinationName == "T-Centralen")
        #expect(reminder.id == "\(ClaimReminderPlanner.idPrefix)\(trip.id.uuidString)-14")
    }
}
