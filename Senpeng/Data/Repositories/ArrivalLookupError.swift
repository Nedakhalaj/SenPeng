import Foundation

/// Every way looking up the arrival time at the user's destination can fail.
enum ArrivalLookupError: Error, Equatable {

    /// The request failed.
    case network(NetworkError)

    /// The chosen departure doesn't stop at the chosen destination,
    /// for example a stop on another line or in the other direction.
    case notOnRoute

    /// The message to show the user, or `nil` when nothing should be shown.
    var userFacingError: UserFacingError? {
        switch self {
        case .network(let error):
            error.userFacingError
        case .notOnRoute:
            .notOnRoute
        }
    }
}
