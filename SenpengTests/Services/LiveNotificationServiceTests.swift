import Foundation
import Testing
import UserNotifications
@testable import Senpeng

/// Checks the system notification built for a reminder. Nothing is really scheduled here.
@Suite("Live notification service")
struct LiveNotificationServiceTests {

    private let reminder = ClaimReminder(
        id: "claim-reminder-test",
        date: stockholmDate(2027, 1, 17, 10),
        daysLeft: 14,
        originName: "Slussen",
        destinationName: "T-Centralen"
    )

    @Test("The notification has the reminder's ID and names the trip")
    func content() {
        let request = LiveNotificationService.makeRequest(for: reminder)

        #expect(request.identifier == "claim-reminder-test")
        #expect(request.content.body.contains("Slussen"))
        #expect(request.content.body.contains("T-Centralen"))
        #expect(request.content.body.contains("14"))
    }

    @Test("The notification shows once, at the planned time")
    func trigger() throws {
        let request = LiveNotificationService.makeRequest(for: reminder)

        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.nextTriggerDate() == reminder.date)
    }
}
