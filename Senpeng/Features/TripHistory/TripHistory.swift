import Foundation

/// The status shown for a saved trip in My trips.
enum TripRowStatus: Equatable, Sendable {

    /// The user may claim, with this many days left. 0 means today is the last day.
    case claimable(daysLeft: Int)

    /// The trip is still being followed.
    case onTheWay

    /// The trip arrived, not late enough to claim, this many whole minutes late.
    case arrived(minutesLate: Int)

    /// No live data was captured, so the delay isn't known.
    case delayUnknown

    /// The last day to claim has passed.
    case expired

    /// The user has submitted a claim.
    case submitted
}

/// One saved trip with everything My trips shows about it.
struct TripHistoryItem: Identifiable, Equatable, Sendable {

    /// The saved trip.
    let trip: Trip

    /// Whether the trip may qualify for delay money.
    let eligibility: EligibilityResult

    /// The status shown on the row.
    let status: TripRowStatus

    /// The trip's ID.
    var id: UUID {
        trip.id
    }
}

/// The saved trips, sorted into the sections of My trips.
struct TripHistory: Equatable, Sendable {

    /// Trips the user may claim for, with the nearest deadline first.
    let claimSoon: [TripHistoryItem]

    /// All other trips, newest first.
    let otherTrips: [TripHistoryItem]

    /// Whether there are no trips at all.
    var isEmpty: Bool {
        claimSoon.isEmpty && otherTrips.isEmpty
    }

    /// Sorts trips into sections. Runs off the main thread, because judging
    /// hundreds of trips means a lot of calendar math.
    /// - Parameters:
    ///   - trips: The saved trips, newest first.
    ///   - now: The current time.
    ///   - checker: Decides whether a trip may qualify.
    /// - Returns: The sorted trips.
    @concurrent
    static func make(trips: [Trip], now: Date, checker: EligibilityChecker) async -> TripHistory {
        var claimSoon: [(item: TripHistoryItem, lastDay: Date)] = []
        var otherTrips: [TripHistoryItem] = []

        for trip in trips {
            let eligibility = checker.eligibility(for: trip, now: now)
            let item = TripHistoryItem(
                trip: trip,
                eligibility: eligibility,
                status: status(of: trip, eligibility: eligibility, now: now)
            )
            if case .eligible(let deadline, _) = eligibility {
                claimSoon.append((item, deadline.lastDay))
            } else {
                otherTrips.append(item)
            }
        }

        return TripHistory(
            claimSoon: claimSoon.sorted { $0.lastDay < $1.lastDay }.map(\.item),
            otherTrips: otherTrips
        )
    }

    /// Works out the status shown for a trip.
    private static func status(of trip: Trip, eligibility: EligibilityResult, now: Date) -> TripRowStatus {
        switch eligibility {
        case .eligible(let deadline, _):
            .claimable(daysLeft: deadline.daysLeft(at: now))
        case .delayUnknown:
            trip.isActive(at: now) ? .onTheWay : .delayUnknown
        case .delayTooShort:
            .arrived(minutesLate: trip.minutesLate ?? 0)
        case .expired:
            .expired
        case .submitted:
            .submitted
        }
    }
}
