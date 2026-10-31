import Foundation
import Testing
@testable import Senpeng

/// Checks the arrival delay calculation of a trip.
@Suite("Trip")
struct TripTests {

    @Test("Delay is unknown until the real arrival is known")
    func delayUnknown() {
        #expect(TripFactory.make(arrivalDelay: nil).arrivalDelay == nil)
    }

    @Test(
        "Delay is the real arrival minus the scheduled arrival",
        arguments: [
            (TimeInterval(25 * 60), Duration.seconds(25 * 60)),
            (0, .zero),
            (-60, .seconds(-60))
        ]
    )
    func delayCalculation(lateBy seconds: TimeInterval, expected: Duration) {
        #expect(TripFactory.make(arrivalDelay: seconds).arrivalDelay == expected)
    }

    @Test(
        "Minutes late are whole minutes, never negative, and unknown without a real arrival",
        arguments: [
            (nil, nil),
            (0, 0),
            (59, 0),
            (60, 1),
            (25 * 60 + 30, 25),
            (-120, 0)
        ] as [(TimeInterval?, Int?)]
    )
    func minutesLate(lateBy seconds: TimeInterval?, expected: Int?) {
        #expect(TripFactory.make(arrivalDelay: seconds).minutesLate == expected)
    }

    @Test(
        "A trip without a real arrival is active until 2 hours after its planned arrival",
        arguments: [
            (-60, true),
            (2 * 60 * 60, true),
            (2 * 60 * 60 + 1, false)
        ] as [(TimeInterval, Bool)]
    )
    func isActive(secondsAfterPlannedArrival: TimeInterval, expected: Bool) {
        let trip = TripFactory.make()

        let date = trip.scheduledArrival.addingTimeInterval(secondsAfterPlannedArrival)

        #expect(trip.isActive(at: date) == expected)
    }

    @Test("A trip with a known real arrival is no longer active")
    func finishedTripIsNotActive() {
        let trip = TripFactory.make(arrivalDelay: 60)

        #expect(!trip.isActive(at: trip.scheduledArrival))
    }
}
