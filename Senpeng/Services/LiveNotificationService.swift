import Foundation
import os
import UserNotifications

/// The real `NotificationService`, using Apple's local notifications.
///
/// Everything is planned and shown on the device; no server is involved. If the user
/// said no to notifications, the system simply doesn't show them, and the app works as usual.
struct LiveNotificationService: NotificationService {

    func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            Logger.notifications.error("Asking for permission failed")
        }
    }

    func replaceReminders(with reminders: [ClaimReminder]) async {
        let center = UNUserNotificationCenter.current()

        // Only this app's claim reminders are removed, never other notifications.
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(ClaimReminderPlanner.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        for reminder in reminders {
            do {
                try await center.add(Self.makeRequest(for: reminder))
            } catch {
                Logger.notifications.error("Planning a reminder failed")
            }
        }
    }

    /// Creates the system's notification for a reminder.
    /// - Parameter reminder: The planned reminder.
    /// - Returns: The notification request, set to show at the reminder's time in Stockholm.
    static func makeRequest(for reminder: ClaimReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "You may get money back")
        content.body = String(
            localized: "\(reminder.daysLeft) days left to apply on sl.se: \(reminder.originName) → \(reminder.destinationName)"
        )
        content.sound = .default

        var components = StockholmTime.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date
        )
        components.calendar = StockholmTime.calendar
        components.timeZone = StockholmTime.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }
}
