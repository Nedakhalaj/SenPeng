import Foundation

/// An error shown to the user, with a short, friendly message.
///
/// Technical errors (network, storage) are turned into one of these cases,
/// so the user never sees raw error text.
enum UserFacingError: Error, Equatable, Sendable {

    /// The device is offline.
    case offline

    /// The travel information service isn't answering right now.
    case serviceUnavailable

    /// Something unexpected went wrong.
    case unexpected

    /// The message shown to the user, from the String Catalog.
    var message: LocalizedStringResource {
        switch self {
        case .offline:
            "You're offline. Check your connection and try again."
        case .serviceUnavailable:
            "Travel information isn't available right now. Try again in a moment."
        case .unexpected:
            "Something went wrong. Try again."
        }
    }
}
