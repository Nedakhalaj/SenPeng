import Foundation
import Testing
@testable import Senpeng

/// Checks that the planned reminders follow the saved trips.
@MainActor
@Suite("Claim reminder sync")
struct ClaimReminderSyncTests {

    /// Soon after the example trips, so all their reminders are still ahead.
    private let now = TripFactory.referenceDate.addingTimeInterval(60 * 60)

    @Test("A late trip gets its reminders")
    func lateTrip() async {
        let notifications = FakeNotificationService()

        await makeSync(trips: [TripFactory.make(arrivalDelay: 25 * 60)], notifications: notifications).sync()

        #expect(notifications.reminders.map(\.daysLeft) == [14, 3])
    }

    @Test("Trips that can't be claimed for get none, and old reminders are removed")
    func removesOldReminders() async throws {
        let notifications = FakeNotificationService()
        let trips = FakeTripRepository(trips: [TripFactory.make(arrivalDelay: 25 * 60)])
        let sync = makeSync(repository: trips, notifications: notifications)
        await sync.sync()
        #expect(!notifications.reminders.isEmpty)

        try await trips.deleteAll()
        await sync.sync()

        #expect(notifications.reminders.isEmpty)
    }

    @Test("A submitted claim loses its reminders")
    func submittedLosesReminders() async {
        let notifications = FakeNotificationService()
        let trip = TripFactory.make(arrivalDelay: 25 * 60, claimStatus: .submitted)

        await makeSync(trips: [trip], notifications: notifications).sync()

        #expect(notifications.reminders.isEmpty)
    }

    @Test("If the trips can't be read, the existing reminders are left alone")
    func readFailureKeepsReminders() async {
        let notifications = FakeNotificationService()
        let sync = ClaimReminderSync(
            tripRepository: UnavailableTripRepository(),
            notifications: notifications,
            now: { [now] in now }
        )

        await sync.sync()

        #expect(notifications.replaceCount == 0)
    }

    @Test("Reminders stay under the system's limit, keeping the soonest")
    func limit() async throws {
        let notifications = FakeNotificationService()
        let trips = (0..<40).map { day in
            TripFactory.make(departureOffset: TimeInterval(day) * 24 * 60 * 60, arrivalDelay: 25 * 60)
        }

        await makeSync(trips: trips, notifications: notifications).sync()

        let dates = notifications.reminders.map(\.date)
        #expect(dates.count == 60)
        #expect(dates == dates.sorted())
    }

    @Test("Asking for permission goes to the notification service")
    func permission() async {
        let notifications = FakeNotificationService()

        await makeSync(trips: [], notifications: notifications).requestPermission()

        #expect(notifications.permissionRequests == 1)
    }

    /// Creates a sync over fixed trips.
    private func makeSync(trips: [Trip], notifications: FakeNotificationService) -> ClaimReminderSync {
        makeSync(repository: FakeTripRepository(trips: trips), notifications: notifications)
    }

    /// Creates a sync over a repository the test can change.
    private func makeSync(repository: FakeTripRepository, notifications: FakeNotificationService) -> ClaimReminderSync {
        ClaimReminderSync(tripRepository: repository, notifications: notifications, now: { [now] in now })
    }
}

/// A `NotificationService` that remembers what it was asked to do.
@MainActor
private final class FakeNotificationService: NotificationService {

    /// The reminders currently planned.
    private(set) var reminders: [ClaimReminder] = []

    /// How many times the reminders were replaced.
    private(set) var replaceCount = 0

    /// How many times permission was asked for.
    private(set) var permissionRequests = 0

    func requestPermission() async {
        permissionRequests += 1
    }

    func replaceReminders(with reminders: [ClaimReminder]) async {
        self.reminders = reminders
        replaceCount += 1
    }
}
