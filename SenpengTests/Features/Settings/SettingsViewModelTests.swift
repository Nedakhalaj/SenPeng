import Foundation
import Testing
@testable import Senpeng

/// Checks the Settings screen's logic.
@MainActor
@Suite("Settings view model")
struct SettingsViewModelTests {

    @Test("Deleting all data removes every trip and tells the app")
    func deleteAll() async {
        let trips = FakeTripRepository(trips: [TripFactory.make(), TripFactory.make()])
        var notifiedCount = 0
        let viewModel = SettingsViewModel(tripRepository: trips, appVersion: "1.0.0") {
            notifiedCount += 1
        }

        await viewModel.deleteAllData()

        #expect(trips.saved.isEmpty)
        #expect(viewModel.deletionState == .deleted)
        #expect(notifiedCount == 1)
    }

    @Test("If deleting fails, the user is told and the app isn't told it worked")
    func deleteFails() async {
        var notifiedCount = 0
        let viewModel = SettingsViewModel(tripRepository: UnavailableTripRepository(), appVersion: "1.0.0") {
            notifiedCount += 1
        }

        await viewModel.deleteAllData()

        #expect(viewModel.deletionState == .failed(.unexpected))
        #expect(notifiedCount == 0)
    }

    @Test("Starts with nothing deleted, and reads the app's real version")
    func startState() {
        let viewModel = SettingsViewModel(tripRepository: FakeTripRepository(), onDataDeleted: {})

        #expect(viewModel.deletionState == .idle)
        #expect(viewModel.appVersion == "1.0.0")
    }
}
