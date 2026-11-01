import Foundation

/// Whether a trip may qualify for delay money.
///
/// SL makes the final decision on every claim, so "eligible" only ever means
/// "may qualify". The app must never promise a payout.
enum EligibilityResult: Equatable, Sendable {

    /// The delay isn't known yet, so the app can't tell. The deadline still runs.
    case delayUnknown(ClaimDeadline)

    /// The trip may qualify, and the user can still claim.
    case eligible(ClaimDeadline, alternativeTravelCap: Decimal)

    /// The trip wasn't late enough.
    case delayTooShort

    /// The trip may have qualified, but the last day to claim has passed.
    case expired

    /// The user has already submitted a claim.
    case submitted
}
