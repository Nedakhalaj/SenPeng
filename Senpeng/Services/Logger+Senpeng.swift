import Foundation
import os

extension Logger {

    /// The subsystem shared by all of the app's logs, so they're easy to filter in Console.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.nedakhalaj.senpeng"

    /// Logs from network requests.
    static let networking = Logger(subsystem: subsystem, category: "Networking")

    /// Logs from the on-device database.
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// Logs from planning reminders.
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
