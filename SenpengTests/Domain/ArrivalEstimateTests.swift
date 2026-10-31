import Foundation
import Testing
@testable import Senpeng

/// Checks the expected delay of an arrival.
@Suite("Arrival estimate")
struct ArrivalEstimateTests {

    private let scheduled = TripFactory.referenceDate

    @Test("Without live data, the expected delay is unknown")
    func unknownDelay() {
        #expect(ArrivalEstimate(scheduled: scheduled, expected: nil).expectedDelay == nil)
    }

    @Test(
        "The expected delay is the live arrival minus the timetable arrival",
        arguments: [
            (TimeInterval(21 * 60), Duration.seconds(21 * 60)),
            (0, .zero),
            (-42, .seconds(-42))
        ]
    )
    func expectedDelay(lateBy seconds: TimeInterval, expected: Duration) {
        let estimate = ArrivalEstimate(scheduled: scheduled, expected: scheduled.addingTimeInterval(seconds))

        #expect(estimate.expectedDelay == expected)
    }
}
