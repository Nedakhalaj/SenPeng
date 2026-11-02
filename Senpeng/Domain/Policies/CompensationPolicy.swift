import Foundation

/// SL's delay compensation rules. This is the only place their values are written.
///
/// Sources, both checked on 2026-11-01:
/// - SL: https://sl.se/kundservice/forseningsersattning
///   ("upp till 1 480 kronor", "mer än 20 minuter", "inom 3 månader efter förseningen")
/// - The law behind them, Lag (2015:953) om kollektivtrafikresenärers rättigheter:
///   https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-2015953-om-kollektivtrafikresenarers_sfs-2015-953/
///   (§14 and §15: "mer än 20 minuter")
///
/// The law sets the cap as 1/40 of the price base amount, which changes every year.
/// So check SL's page every January, and when it changes, add a new rule set
/// below instead of editing an old one: earlier trips keep their earlier rules.
enum CompensationPolicy {

    /// How late a trip must be, in whole minutes, under the rules valid at the given time.
    /// - Parameter date: The time to check. Today by default.
    /// - Returns: The minutes, for telling the user about the rules.
    static func minimumDelayMinutes(at date: Date = Date()) -> Int {
        Int(currentRules(at: date).minimumDelay.components.seconds / 60)
    }

    /// How many months the user can claim, under the rules valid at the given time.
    /// - Parameter date: The time to check. Today by default.
    /// - Returns: The months, for telling the user about the rules.
    static func claimWindowMonths(at date: Date = Date()) -> Int {
        currentRules(at: date).claimWindowMonths
    }

    /// The newest rule set that had started at the given time.
    private static func currentRules(at date: Date) -> CompensationRuleSet {
        ruleSets
            .filter { $0.validFrom <= date }
            .max { $0.validFrom < $1.validFrom } ?? firstRules
    }

    /// The first rule set, which covers every earlier date.
    private static let firstRules = CompensationRuleSet(
        validFrom: .distantPast,
        minimumDelay: .seconds(20 * 60),
        claimWindowMonths: 3,
        alternativeTravelCap: 1_480
    )

    /// All known rule sets.
    static let ruleSets = [firstRules]
}
