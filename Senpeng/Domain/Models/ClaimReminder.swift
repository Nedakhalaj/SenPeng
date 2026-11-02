import Foundation

/// A planned notification that reminds the user to claim before the last day.
struct ClaimReminder: Equatable, Sendable {

    /// A unique ID, so the system can replace or remove this reminder.
    let id: String

    /// When the notification should show.
    let date: Date

    /// How many days will be left to claim when it shows.
    let daysLeft: Int

    /// The stop where the trip started, shown in the text.
    let originName: String

    /// The stop where the trip ended, shown in the text.
    let destinationName: String
}
