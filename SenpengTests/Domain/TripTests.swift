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
}
