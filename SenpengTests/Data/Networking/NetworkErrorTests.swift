import Foundation
import Testing
@testable import Senpeng

/// Checks how system errors become network errors, and which message the user sees.
@Suite("Network error")
struct NetworkErrorTests {

    @Test(
        "URL errors map to the right network error",
        arguments: [
            (URLError.Code.notConnectedToInternet, NetworkError.offline),
            (.networkConnectionLost, .offline),
            (.timedOut, .timeout),
            (.cancelled, .cancelled),
            (.badServerResponse, .transport(code: URLError.Code.badServerResponse.rawValue))
        ]
    )
    func mapsURLError(code: URLError.Code, expected: NetworkError) {
        #expect(NetworkError(URLError(code)) == expected)
    }

    @Test("Swift task cancellation maps to cancelled")
    func mapsCancellation() {
        #expect(NetworkError(CancellationError()) == .cancelled)
    }

    @Test(
        "Each error shows the right message to the user",
        arguments: [
            (NetworkError.offline, UserFacingError.offline),
            (.timeout, .serviceUnavailable),
            (.server(statusCode: 500), .serviceUnavailable),
            (.rateLimited, .serviceUnavailable),
            (.invalidResponse, .unexpected),
            (.decoding, .unexpected),
            (.transport(code: 0), .unexpected)
        ]
    )
    func mapsToUserFacingError(error: NetworkError, expected: UserFacingError) {
        #expect(error.userFacingError == expected)
    }

    @Test("A cancelled request shows no message")
    func cancelledShowsNothing() {
        #expect(NetworkError.cancelled.userFacingError == nil)
    }
}
