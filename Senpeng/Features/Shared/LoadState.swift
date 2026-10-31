import Foundation

/// The state of a screen that loads data: one value instead of several booleans,
/// so a screen can never be "loading" and "failed" at the same time.
enum LoadState<Value> {

    /// Nothing has started yet.
    case idle

    /// Waiting for the data.
    case loading

    /// The data is ready.
    case loaded(Value)

    /// Loading failed; the message is shown to the user.
    case failed(UserFacingError)
}

extension LoadState: Equatable where Value: Equatable {}
