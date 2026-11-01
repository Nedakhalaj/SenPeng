import Foundation
import Testing
@testable import Senpeng

/// Checks how trips are sorted into sections and which status each one shows.
@Suite("Trip history")
struct TripHistoryTests {

    /// All example trips arrive on this date, unless a test says otherwise.
    private let arrival = stockholmDate(2026, 10, 15)

    /// The day after the example trips, when they're no longer followed.
    private let dayAfter = stockholmDate(2026, 10, 16)

    @Test("No trips gives an empty history")
    func empty() async {
        let history = await makeHistory([], now: dayAfter)

        #expect(history.isEmpty)
    }

    @Test("Trips that may qualify go in Claim soon; all others in Other trips")
    func sections() async {
        let late = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: arrival)
        let onTime = TripFactory.make(arrivalDelay: 0, scheduledArrival: arrival)

        let history = await makeHistory([late, onTime], now: dayAfter)

        #expect(history.claimSoon.map(\.trip) == [late])
        #expect(history.otherTrips.map(\.trip) == [onTime])
    }

    @Test("Claim soon shows the nearest deadline first")
    func nearestDeadlineFirst() async {
        let newer = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: stockholmDate(2026, 10, 14))
        let older = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: stockholmDate(2026, 9, 20))

        let history = await makeHistory([newer, older], now: dayAfter)

        #expect(history.claimSoon.map(\.trip) == [older, newer])
    }

    @Test("Other trips keep their order, newest first")
    func otherTripsKeepOrder() async {
        let newer = TripFactory.make(arrivalDelay: 0, scheduledArrival: stockholmDate(2026, 10, 14))
        let older = TripFactory.make(arrivalDelay: 0, scheduledArrival: stockholmDate(2026, 9, 20))

        let history = await makeHistory([newer, older], now: dayAfter)

        #expect(history.otherTrips.map(\.trip) == [newer, older])
    }

    @Test("A claimable trip shows the days left")
    func claimable() async throws {
        let trip = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: arrival)

        // The last day is 15 January 2027, 91 days after 16 October 2026.
        #expect(try await status(of: trip, now: dayAfter) == .claimable(daysLeft: 91))
        #expect(try await status(of: trip, now: stockholmDate(2027, 1, 15, 23, 59)) == .claimable(daysLeft: 0))
    }

    @Test("A trip not late enough shows its delay")
    func tooShort() async throws {
        let trip = TripFactory.make(arrivalDelay: 4 * 60, scheduledArrival: arrival)

        #expect(try await status(of: trip, now: dayAfter) == .arrived(minutesLate: 4))
    }

    @Test("A trip arriving early shows as zero minutes late, not negative")
    func early() async throws {
        let trip = TripFactory.make(arrivalDelay: -60, scheduledArrival: arrival)

        #expect(try await status(of: trip, now: dayAfter) == .arrived(minutesLate: 0))
    }

    @Test("An unknown delay is On the way while followed, then Delay unknown; never On time")
    func unknownDelay() async throws {
        let trip = TripFactory.make(arrivalDelay: nil, scheduledArrival: arrival)

        #expect(try await status(of: trip, now: arrival) == .onTheWay)
        #expect(try await status(of: trip, now: dayAfter) == .delayUnknown)
    }

    @Test("A late trip after its deadline shows that the time has passed")
    func expired() async throws {
        let trip = TripFactory.make(arrivalDelay: 25 * 60, scheduledArrival: arrival)

        #expect(try await status(of: trip, now: stockholmDate(2027, 1, 16, 0, 0)) == .expired)
    }

    @Test("A submitted claim shows as submitted")
    func submitted() async throws {
        let trip = TripFactory.make(arrivalDelay: 25 * 60, claimStatus: .submitted, scheduledArrival: arrival)

        #expect(try await status(of: trip, now: dayAfter) == .submitted)
    }

    /// Sorts trips into a history with SL's real rules.
    private func makeHistory(_ trips: [Trip], now: Date) async -> TripHistory {
        await TripHistory.make(trips: trips, now: now, checker: EligibilityChecker())
    }

    /// The status of one trip, in whichever section it ends up.
    private func status(of trip: Trip, now: Date) async throws -> TripRowStatus {
        let history = await makeHistory([trip], now: now)
        return try #require((history.claimSoon + history.otherTrips).first).status
    }
}
