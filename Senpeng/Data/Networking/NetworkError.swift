import Foundation

/// Every way a network request can fail.
///
/// These are technical errors for the code. Before anything is shown to the
/// user, they are turned into a `UserFacingError` with a friendly message.
enum NetworkError: Error, Equatable {

    /// The device has no internet connection.
    case offline

    /// The server took too long to answer.
    case timeout

    /// The server answered with an error status, for example 404 or 500.
    case server(statusCode: Int)

    /// The server answered "too many requests", or the app is still waiting after such an answer.
    case rateLimited

    /// The answer wasn't valid HTTP.
    case invalidResponse

    /// The answer didn't match the expected JSON format.
    case decoding

    /// The request was cancelled, for example because the user left the screen.
    case cancelled

    /// Any other transport error.
    case transport(code: Int)

    /// Creates a network error from an error thrown by `URLSession`.
    /// - Parameter error: The error from `URLSession`.
    init(_ error: any Error) {
        if error is CancellationError {
            self = .cancelled
            return
        }
        guard let urlError = error as? URLError else {
            self = .transport(code: 0)
            return
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            self = .offline
        case .timedOut:
            self = .timeout
        case .cancelled:
            self = .cancelled
        default:
            self = .transport(code: urlError.errorCode)
        }
    }

    /// The message to show the user, or `nil` when nothing should be shown.
    ///
    /// A cancelled request is not an error from the user's point of view,
    /// so it has no message.
    var userFacingError: UserFacingError? {
        switch self {
        case .offline:
            .offline
        case .timeout, .server, .rateLimited:
            .serviceUnavailable
        case .invalidResponse, .decoding, .transport:
            .unexpected
        case .cancelled:
            nil
        }
    }
}
