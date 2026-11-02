import Foundation
import os
import Testing
@testable import Senpeng

/// Checks how long requests are held back after "too many requests".
@Suite("Rate limit gate")
struct RateLimitGateTests {

    /// A clock that tests can move forward.
    private let clock = OSAllocatedUnfairLock(initialState: TripFactory.referenceDate)

    /// The host used by most tests.
    private let host = "example.test"

    @Test("A host without a limit isn't paused")
    func notPausedAtFirst() async {
        #expect(await makeGate().isPaused(host: host) == false)
    }

    @Test("The pause lasts until exactly its end")
    func pauseEnds() async {
        let gate = makeGate()

        #expect(await gate.recordRateLimited(host: host, retryAfter: nil) == 60)

        advance(by: 59)
        #expect(await gate.isPaused(host: host))
        advance(by: 1)
        #expect(await gate.isPaused(host: host) == false)
    }

    @Test("Without a server value, the pause doubles up to ten minutes")
    func pauseDoubles() async {
        let gate = makeGate()

        for expected in [60, 120, 240, 480, 600, 600] as [TimeInterval] {
            let pause = await gate.recordRateLimited(host: host, retryAfter: nil)
            #expect(pause == expected)
            advance(by: pause)
        }
    }

    @Test(
        "The server's Retry-After is used when it's a positive whole number, up to ten minutes",
        arguments: [
            ("120", 120),
            (" 5 ", 5),
            ("3600", 600),
            ("0", 60),
            ("-5", 60),
            ("soon", 60),
            ("Wed, 21 Oct 2026 07:28:00 GMT", 60)
        ] as [(String, TimeInterval)]
    )
    func usesRetryAfter(header: String, expected: TimeInterval) async {
        #expect(await makeGate().recordRateLimited(host: host, retryAfter: header) == expected)
    }

    @Test("Answers during a pause don't make it longer")
    func answersDuringPause() async {
        let gate = makeGate()
        await gate.recordRateLimited(host: host, retryAfter: nil)

        advance(by: 10)
        #expect(await gate.recordRateLimited(host: host, retryAfter: nil) == 50)

        // The next real attempt is the second in a row, not the third.
        advance(by: 50)
        #expect(await gate.recordRateLimited(host: host, retryAfter: nil) == 120)
    }

    @Test("A success after the pause starts the doubling over")
    func successResets() async {
        let gate = makeGate()
        await gate.recordRateLimited(host: host, retryAfter: nil)

        advance(by: 60)
        await gate.recordSuccess(host: host)

        #expect(await gate.recordRateLimited(host: host, retryAfter: nil) == 60)
    }

    @Test("A late success during a pause doesn't end it")
    func successDuringPause() async {
        let gate = makeGate()
        await gate.recordRateLimited(host: host, retryAfter: nil)

        await gate.recordSuccess(host: host)

        #expect(await gate.isPaused(host: host))
    }

    @Test("A pause only affects its own host")
    func hostsAreSeparate() async {
        let gate = makeGate()

        await gate.recordRateLimited(host: host, retryAfter: nil)

        #expect(await gate.isPaused(host: "other.test") == false)
    }

    /// Creates a gate that uses the test's clock.
    private func makeGate() -> RateLimitGate {
        let clock = clock
        return RateLimitGate(now: { clock.withLock { $0 } })
    }

    /// Moves the clock forward.
    /// - Parameter seconds: How far to move it.
    private func advance(by seconds: TimeInterval) {
        clock.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}
