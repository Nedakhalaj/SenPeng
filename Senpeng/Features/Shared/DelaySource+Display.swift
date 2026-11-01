import Foundation

extension DelaySource {

    /// A short text saying how the delay was measured, so the user can judge how reliable it is.
    var displayName: LocalizedStringResource {
        switch self {
        case .live: "Measured with live data"
        case .historical: "From historical data"
        case .userReported: "Entered by you"
        }
    }
}
