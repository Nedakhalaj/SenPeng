#if DEBUG
import Foundation

/// A fake `NotificationService` for SwiftUI previews. Nothing is shown.
struct PreviewNotificationService: NotificationService {

    func requestPermission() async {}

    func replaceReminders(with reminders: [ClaimReminder]) async {}
}
#endif
