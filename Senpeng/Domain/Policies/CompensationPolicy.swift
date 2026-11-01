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

    /// All known rule sets.
    static let ruleSets = [
        CompensationRuleSet(
            // The first rule set covers every earlier date, so a rule always exists.
            validFrom: .distantPast,
            minimumDelay: .seconds(20 * 60),
            claimWindowMonths: 3,
            alternativeTravelCap: 1_480
        )
    ]
}
