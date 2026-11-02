import Foundation

/// Plans when to remind the user about a trip they may claim for.
struct ClaimReminderPlanner: Sendable {

    /// How many days before the last day to remind the user.
    private let daysBeforeDeadline = [14, 3]

    /// The hour the reminder shows, in Stockholm time: during the day, never at night.
    private let hour = 10

    /// Plans the reminders for one trip.
    /// - Parameters:
    ///   - trip: The saved trip.
    ///   - eligibility: Whether the trip may qualify. Only eligible trips get reminders.
    ///   - now: The current time. Reminders that would already have passed are left out.
    /// - Returns: The reminders, earliest first.
    func reminders(for trip: Trip, eligibility: EligibilityResult, now: Date) -> [ClaimReminder] {
        guard case .eligible(let deadline, _) = eligibility else {
            return []
        }

        let calendar = StockholmTime.calendar
        return daysBeforeDeadline.compactMap { days -> ClaimReminder? in
            // Calendar math, so a reminder stays at 10:00 across summer and winter time.
            guard
                let day = calendar.date(byAdding: .day, value: -days, to: deadline.lastDay),
                let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                date > now
            else {
                return nil
            }
            return ClaimReminder(
                id: "\(Self.idPrefix)\(trip.id.uuidString)-\(days)",
                date: date,
                daysLeft: days,
                originName: trip.origin.name,
                destinationName: trip.destination.name
            )
        }
    }

    /// The start of every reminder's ID, which tells them apart from other notifications.
    static let idPrefix = "claim-reminder-"
}
