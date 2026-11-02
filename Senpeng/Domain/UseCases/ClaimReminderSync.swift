import Foundation
import os

/// Keeps the planned reminders in line with the saved trips.
///
/// It always works out the whole set of reminders and replaces the old ones. So a trip
/// that was removed or claimed loses its reminders without any special handling.
struct ClaimReminderSync: Sendable {

    /// iOS keeps only the 64 soonest notifications per app. Staying under it makes
    /// sure the system never silently drops one of the planned reminders.
    private static let maximumReminders = 60

    /// Loads the saved trips.
    private let tripRepository: any TripRepository

    /// Shows the reminders.
    private let notifications: any NotificationService

    /// Decides whether a trip may qualify for delay money.
    private let checker = EligibilityChecker()

    /// Plans the reminders for one trip.
    private let planner = ClaimReminderPlanner()

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// Creates the sync.
    /// - Parameters:
    ///   - tripRepository: Loads the saved trips.
    ///   - notifications: Shows the reminders.
    ///   - now: Returns the current time.
    init(
        tripRepository: any TripRepository,
        notifications: any NotificationService,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.tripRepository = tripRepository
        self.notifications = notifications
        self.now = now
    }

    /// Asks for permission to show reminders, after the user saved a trip.
    func requestPermission() async {
        await notifications.requestPermission()
    }

    /// Replaces the planned reminders with the ones the saved trips need right now.
    func sync() async {
        let trips: [Trip]
        do {
            trips = try await tripRepository.allTrips()
        } catch {
            // Reminders that may still be right are better than none, so they stay.
            Logger.notifications.error("Loading trips for reminders failed")
            return
        }

        let date = now()
        let reminders = trips
            .flatMap { trip in
                planner.reminders(for: trip, eligibility: checker.eligibility(for: trip, now: date), now: date)
            }
            .sorted { $0.date < $1.date }
            .prefix(Self.maximumReminders)

        await notifications.replaceReminders(with: Array(reminders))
    }
}
