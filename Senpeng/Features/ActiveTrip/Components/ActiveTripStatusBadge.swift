import SwiftUI

/// How late the current trip is, with an icon and text: "4 min late", "On time",
/// or "No live data yet" when the delay is unknown.
struct ActiveTripStatusBadge: View {

    /// The whole minutes late, or `nil` while the delay is unknown.
    let minutesLate: Int?

    var body: some View {
        switch minutesLate {
        case nil:
            StatusBadge("No live data yet", style: .neutral, systemImage: "antenna.radiowaves.left.and.right.slash")
        case 0:
            StatusBadge("On time", style: .neutral, systemImage: "checkmark.circle.fill")
        case let minutes?:
            StatusBadge("\(minutes) min late", style: .warning)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.s) {
        ActiveTripStatusBadge(minutesLate: nil)
        ActiveTripStatusBadge(minutesLate: 0)
        ActiveTripStatusBadge(minutesLate: 24)
    }
    .padding(Spacing.l)
    .appBackground()
}
