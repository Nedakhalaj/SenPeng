import Foundation

/// Every way reading or writing the on-device database can fail.
///
/// These are technical errors for the code. Before anything is shown to the
/// user, they are turned into a `UserFacingError`.
enum PersistenceError: Error, Equatable {

    /// The database couldn't be read.
    case fetchFailed

    /// A change couldn't be saved.
    case saveFailed

    /// A stored record has a value the app doesn't understand.
    case corruptedRecord

    /// The message to show the user.
    var userFacingError: UserFacingError {
        .unexpected
    }
}
