import Foundation

/// Whether the user has claimed delay money for a trip.
///
/// The raw values are stored on the device, so they must never change.
enum ClaimStatus: String, Sendable {

    /// No claim has been submitted yet.
    case notSubmitted

    /// The user has submitted the claim on sl.se.
    case submitted
}
