import Foundation

/// Remembers when a server has answered "too many requests", and for how long
/// no more requests should be sent to it.
///
/// Trafiklab asks apps not to make excessive requests, and may block those that do:
/// https://www.trafiklab.se/api/other-apis/sl/licence/ (checked 2026-11-02).
///
/// Each host is tracked on its own, so a limit on the journey planner doesn't stop departures.
/// The state is only kept in memory: starting the app again sends one request, which is harmless.
actor RateLimitGate {

    /// The current pause of one host.
    private struct Pause {

        /// When requests may be sent again.
        var until: Date

        /// How many "too many requests" answers came in a row.
        var count: Int
    }

    /// The first pause when the server doesn't say how long to wait, in seconds.
    /// It doubles with each answer in a row.
    private static let firstPause: TimeInterval = 60

    /// The longest pause, in seconds, also when the server asks for more. A trip's live
    /// arrival can't be measured during a pause, so the app must not stay quiet for long.
    private static let maxPause: TimeInterval = 10 * 60

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// The latest pause of each host.
    private var pauses: [String: Pause] = [:]

    /// Creates a gate.
    /// - Parameter now: Returns the current time.
    init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    /// Whether requests to a host should wait.
    /// - Parameter host: The server's host name.
    /// - Returns: `true` while the host's pause is running.
    func isPaused(host: String) -> Bool {
        guard let pause = pauses[host] else {
            return false
        }
        return now() < pause.until
    }

    /// Starts a pause after a "too many requests" answer.
    ///
    /// Requests that were already on their way may get the same answer. They don't make
    /// the pause longer, because they aren't new attempts.
    ///
    /// - Parameters:
    ///   - host: The server's host name.
    ///   - retryAfter: The answer's `Retry-After` header, if any. Only the number of seconds
    ///     is read; the header's date form gets the normal doubling pause instead.
    /// - Returns: How long the pause lasts from now, in seconds.
    @discardableResult
    func recordRateLimited(host: String, retryAfter: String?) -> TimeInterval {
        if let pause = pauses[host], now() < pause.until {
            return pause.until.timeIntervalSince(now())
        }

        let count = (pauses[host]?.count ?? 0) + 1
        let seconds = min(requestedPause(retryAfter) ?? Self.firstPause * pow(2, Double(count - 1)), Self.maxPause)
        pauses[host] = Pause(until: now().addingTimeInterval(seconds), count: count)
        return seconds
    }

    /// Forgets a host's earlier pauses after a successful answer.
    ///
    /// During a pause this does nothing: the answer belongs to a request sent before it started.
    /// - Parameter host: The server's host name.
    func recordSuccess(host: String) {
        if !isPaused(host: host) {
            pauses[host] = nil
        }
    }

    /// Reads the number of seconds in a `Retry-After` header.
    /// - Parameter retryAfter: The header's value.
    /// - Returns: The seconds, or `nil` if the value isn't a positive whole number.
    private func requestedPause(_ retryAfter: String?) -> TimeInterval? {
        guard
            let text = retryAfter?.trimmingCharacters(in: .whitespaces),
            let seconds = Int(text),
            seconds > 0
        else {
            return nil
        }
        return TimeInterval(seconds)
    }
}
