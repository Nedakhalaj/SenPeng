import Foundation

/// Decides whether a trip may qualify for delay money.
///
/// The rules are passed in instead of being hard-coded, so every trip is
/// judged by the rules that were valid on the day it happened.
struct EligibilityChecker: Sendable {

    /// All known rule sets, in any order.
    private let ruleSets: [CompensationRuleSet]

    /// Creates a checker.
    /// - Parameter ruleSets: The rule sets to use. SL's current rules by default.
    init(ruleSets: [CompensationRuleSet] = CompensationPolicy.ruleSets) {
        self.ruleSets = ruleSets
    }

    /// Judges a trip.
    /// - Parameters:
    ///   - trip: The saved trip.
    ///   - now: The current time. Injected so tests can control time.
    /// - Returns: Whether the trip may qualify.
    func eligibility(for trip: Trip, now: Date) -> EligibilityResult {
        if trip.claimStatus == .submitted {
            return .submitted
        }

        guard
            let rules = ruleSet(validOn: trip.scheduledArrival),
            let deadline = ClaimDeadline.make(tripDate: trip.scheduledArrival, months: rules.claimWindowMonths)
        else {
            // Can't happen with the real rules: the first rule set covers every date.
            // Promising nothing is the safe answer if it ever did.
            return .delayTooShort
        }

        // SL counts the delay at the user's destination, not at departure.
        guard let delay = trip.arrivalDelay else {
            return deadline.hasPassed(at: now) ? .expired : .delayUnknown(deadline)
        }
        // "More than" is strict in both SL's text and the law: exactly 20:00 isn't enough.
        guard delay > rules.minimumDelay else {
            return .delayTooShort
        }
        return deadline.hasPassed(at: now)
            ? .expired
            : .eligible(deadline, alternativeTravelCap: rules.alternativeTravelCap)
    }

    /// Finds the newest rule set that had started on the given date.
    private func ruleSet(validOn date: Date) -> CompensationRuleSet? {
        ruleSets
            .filter { $0.validFrom <= date }
            .max { $0.validFrom < $1.validFrom }
    }
}
