import Foundation
import Testing
@testable import Senpeng

/// Checks how lateness and the best known time of a departure are calculated.
@Suite("Departure")
struct DepartureTests {

    @Test(
        "Minutes late are whole minutes, never negative",
        arguments: [
            (nil, 0),
            (0, 0),
            (59, 0),
            (60, 1),
            (4 * 60 + 50, 4),
            (-120, 0)
        ] as [(TimeInterval?, Int)]
    )
    func minutesLate(lateBy seconds: TimeInterval?, expected: Int) {
        #expect(makeDeparture(lateBy: seconds).minutesLate == expected)
    }

    @Test("The best known time is the expected time when known")
    func bestKnownTime() {
        let late = makeDeparture(lateBy: 300)
        let unknown = makeDeparture(lateBy: nil)

        #expect(late.bestKnownTime == late.scheduled.addingTimeInterval(300))
        #expect(unknown.bestKnownTime == unknown.scheduled)
    }

    /// Creates a departure that is late by the given seconds, or without an expected time.
    private func makeDeparture(lateBy seconds: TimeInterval?) -> Departure {
        let scheduled = TripFactory.referenceDate
        return Departure(
            id: "1",
            journeyID: "1",
            line: "14",
            transportMode: .metro,
            destination: "Mörby centrum",
            scheduled: scheduled,
            expected: seconds.map { scheduled.addingTimeInterval($0) },
            isCancelled: false
        )
    }
}
