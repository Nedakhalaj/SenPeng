import Foundation
import Observation
import os

/// The logic of the Settings screen.
@MainActor
@Observable
final class SettingsViewModel {

    /// The outcome of "Delete all data".
    enum DeletionState: Equatable {

        /// Nothing has been deleted yet.
        case idle

        /// All trips and reminders are gone.
        case deleted

        /// Deleting failed; the message is shown to the user.
        case failed(UserFacingError)
    }

    /// The outcome of "Delete all data".
    private(set) var deletionState = DeletionState.idle

    /// The app's version, for example "1.0.0".
    let appVersion: String

    /// Saves and deletes the trips.
    private let tripRepository: any TripRepository

    /// Runs after the data was deleted, so the rest of the app can catch up.
    private let onDataDeleted: @MainActor () async -> Void

    /// Creates the view model.
    /// - Parameters:
    ///   - tripRepository: Saves and deletes the trips.
    ///   - appVersion: The app's version. Read from the app by default.
    ///   - onDataDeleted: Runs after the data was deleted.
    init(
        tripRepository: any TripRepository,
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
        onDataDeleted: @escaping @MainActor () async -> Void
    ) {
        self.tripRepository = tripRepository
        self.appVersion = appVersion
        self.onDataDeleted = onDataDeleted
    }

    /// Deletes every saved trip, after the user confirmed. Their reminders go with them.
    func deleteAllData() async {
        do {
            try await tripRepository.deleteAll()
            deletionState = .deleted
            await onDataDeleted()
        } catch {
            Logger.persistence.error("Deleting all data failed")
            deletionState = .failed(error.userFacingError)
        }
    }
}
