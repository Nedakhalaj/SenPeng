import Foundation
import Testing
@testable import Senpeng

/// Checks who may qualify for delay money, with SL's real rules and with made-up rule changes.
@Suite("Eligibility checker")
struct EligibilityCheckerTests {

    private let checker = EligibilityChecker()

    /// The example trip's planned arrival, and its last day to claim 3 months later.
    private let arrival = stockholmDate(2026, 10, 15)
    private let lastDay = stockholmDate(2027, 1, 15, 0)

    /// A time soon after the example trip, well within the deadline.
    private var soonAfter: Date {
        arrival.addingTimeInterval(60 * 60)
    }

    @Test(
        "A trip must be more than 20 minutes late: exactly 20:00 isn't enough",
        arguments: [
            (-60, false),
            (0, false),
            (19 * 60 + 59, false),
            (20 * 60, false),
            (20 * 60 + 1, true),
            (90 * 60, true)
        ] as [(TimeInterval, Bool)]
    )
    func minimumDelay(lateBy seconds: TimeInterval, qualifies: Bool) {
        let trip = TripFactory.make(arrivalDelay: seconds, scheduledArrival: arrival)

        let result = checker.eligibility(for: trip, now: soonAfter)

        let expected: EligibilityResult = qualifies
            ? .eligible(ClaimDeadline(lastDay: lastDay), alternativeTravelCap: 1_480)
            : .delayTooShort
        #expect(result == expected)
    }

    @Test("An unknown delay isn't judged, and the deadline still shows")
    func unknownDelay() {
        let trip = TripFactory.make(arrivalDelay: nil, scheduledArrival: arrival)

        #expect(checker.eligibility(for: trip, now: soonAfter) == .delayUnknown(ClaimDeadline(lastDay: lastDay)))
    }

    @Test("A late trip can be claimed all through the last day, and not after")
    func deadline() {
        let trip = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: arrival)

        let lastEvening = checker.eligibility(for: trip, now: stockholmDate(2027, 1, 15, 23, 59))
        let nextDay = checker.eligibility(for: trip, now: stockholmDate(2027, 1, 16, 0, 0))

        #expect(lastEvening == .eligible(ClaimDeadline(lastDay: lastDay), alternativeTravelCap: 1_480))
        #expect(nextDay == .expired)
    }

    @Test("After the deadline, an unknown delay can't be claimed either")
    func unknownDelayExpires() {
        let trip = TripFactory.make(arrivalDelay: nil, scheduledArrival: arrival)

        #expect(checker.eligibility(for: trip, now: stockholmDate(2027, 1, 16, 0, 0)) == .expired)
    }

    @Test("A trip that wasn't late enough stays that way after the deadline, not expired")
    func tooShortStaysTooShort() {
        let trip = TripFactory.make(arrivalDelay: 5 * 60, scheduledArrival: arrival)

        #expect(checker.eligibility(for: trip, now: stockholmDate(2028, 1, 1)) == .delayTooShort)
    }

    @Test("A submitted claim stays submitted, whatever the date")
    func submitted() {
        let trip = TripFactory.make(arrivalDelay: 25 * 60, claimStatus: .submitted, scheduledArrival: arrival)

        #expect(checker.eligibility(for: trip, now: soonAfter) == .submitted)
        #expect(checker.eligibility(for: trip, now: stockholmDate(2028, 1, 1)) == .submitted)
    }

    @Test("A trip is judged by the rules valid on its date, in any list order")
    func ruleChange() {
        let changeDate = stockholmDate(2027, 1, 1, 0)
        let older = CompensationRuleSet(
            validFrom: .distantPast,
            minimumDelay: .seconds(20 * 60),
            claimWindowMonths: 3,
            alternativeTravelCap: 1_480
        )
        let newer = CompensationRuleSet(
            validFrom: changeDate,
            minimumDelay: .seconds(30 * 60),
            claimWindowMonths: 1,
            alternativeTravelCap: 1_600
        )
        let checker = EligibilityChecker(ruleSets: [newer, older])

        let before = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: changeDate.addingTimeInterval(-60))
        let after = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: changeDate)
        let afterVeryLate = TripFactory.make(arrivalDelay: 31 * 60, scheduledArrival: changeDate)

        // The trip just before the change keeps the old 20 minutes, 3 months and cap.
        #expect(checker.eligibility(for: before, now: changeDate) == .eligible(
            ClaimDeadline(lastDay: stockholmDate(2027, 3, 31, 0)),
            alternativeTravelCap: 1_480
        ))
        // The same delay on the day of the change isn't enough under the new rules.
        #expect(checker.eligibility(for: after, now: changeDate) == .delayTooShort)
        #expect(checker.eligibility(for: afterVeryLate, now: changeDate) == .eligible(
            ClaimDeadline(lastDay: stockholmDate(2027, 2, 1, 0)),
            alternativeTravelCap: 1_600
        ))
    }

    @Test("SL's current rules are 20 minutes, 3 months and 1 480 kr")
    func currentRules() throws {
        let rules = try #require(CompensationPolicy.ruleSets.first)

        #expect(CompensationPolicy.ruleSets.count == 1)
        #expect(CompensationPolicy.minimumDelayMinutes() == 20)
        #expect(CompensationPolicy.claimWindowMonths() == 3)
        #expect(rules.minimumDelay == .seconds(20 * 60))
        #expect(rules.claimWindowMonths == 3)
        #expect(rules.alternativeTravelCap == 1_480)
    }
}
