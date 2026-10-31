import Foundation
import Testing
@testable import Senpeng

/// Checks that SL's times are read as Stockholm time, in winter and summer.
@Suite("Stockholm time")
struct StockholmTimeTests {

    @Test(
        "SL times are read as Stockholm local time",
        arguments: [
            // Winter time (CET) is UTC+1.
            ("2026-10-31T12:30:00", "2026-10-31T11:30:00Z"),
            // Summer time (CEST) is UTC+2.
            ("2026-07-01T08:15:30", "2026-07-01T06:15:30Z"),
            // Just after midnight in Stockholm is still the previous day in UTC.
            ("2026-01-01T00:10:00", "2025-12-31T23:10:00Z")
        ]
    )
    func readsStockholmTime(slText: String, utc: String) throws {
        let expected = try Date.ISO8601FormatStyle().parse(utc)

        #expect(StockholmTime.date(fromSL: slText) == expected)
    }

    @Test("Text in another format can't be read", arguments: ["", "12:30", "31/10/2026 12:30", "not a date"])
    func rejectsOtherFormats(text: String) {
        #expect(StockholmTime.date(fromSL: text) == nil)
    }
}
