#if DEBUG
import Foundation

/// A fake `DepartureRepository` for SwiftUI previews.
struct PreviewDepartureRepository: DepartureRepository {

    /// What the fake returns: departures, or an error to preview the error state.
    var result: Result<[Departure], NetworkError> = .success(Self.sampleDepartures())

    func departures(siteID: String) async throws(NetworkError) -> [Departure] {
        try result.get()
    }

    /// A few departures in the next minutes: on time, late, cancelled and different vehicles.
    static func sampleDepartures(from now: Date = Date()) -> [Departure] {
        func departure(
            _ line: String,
            _ mode: TransportMode,
            to destination: String,
            inMinutes minutes: Double,
            lateBy late: Double = 0,
            cancelled: Bool = false
        ) -> Departure {
            let scheduled = now.addingTimeInterval(minutes * 60)
            return Departure(
                id: "\(line)-\(minutes)",
                journeyID: "\(line)-\(minutes)",
                line: line,
                transportMode: mode,
                destination: destination,
                scheduled: scheduled,
                expected: scheduled.addingTimeInterval(late * 60),
                isCancelled: cancelled
            )
        }

        return [
            departure("14", .metro, to: "Mörby centrum", inMinutes: 2),
            departure("3", .bus, to: "Karolinska sjukhuset", inMinutes: 3, lateBy: 4),
            departure("19", .metro, to: "Hässelby strand", inMinutes: 5),
            departure("82", .ferry, to: "Djurgården", inMinutes: 8, lateBy: 2),
            departure("17", .metro, to: "Åkeshov", inMinutes: 12, cancelled: true),
            departure("25", .tram, to: "Saltsjöbaden", inMinutes: 15)
        ]
    }
}
#endif
