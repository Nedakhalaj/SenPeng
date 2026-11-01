import Foundation

/// The delay compensation rules that apply from a certain date.
///
/// Rules change over time, so a trip is always judged by the rule set
/// that was valid on the day of the trip.
struct CompensationRuleSet: Equatable, Sendable {

    /// The first moment these rules apply.
    let validFrom: Date

    /// A trip must be late by more than this at the destination. Exactly this delay isn't enough.
    let minimumDelay: Duration

    /// How many calendar months after the trip the user can claim.
    let claimWindowMonths: Int

    /// The most SL pays for a taxi, own car or another operator, in kronor.
    let alternativeTravelCap: Decimal
}
