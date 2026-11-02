import Foundation

/// Shows reminders to the user as local notifications.
///
/// Other code depends on this protocol instead of the system,
/// so tests and previews can use a fake.
protocol NotificationService: Sendable {

    /// Asks the user for permission. The system only shows the question the first time.
    func requestPermission() async

    /// Replaces all planned reminders with the given ones.
    /// - Parameter reminders: The reminders that should exist.
    func replaceReminders(with reminders: [ClaimReminder]) async
}
