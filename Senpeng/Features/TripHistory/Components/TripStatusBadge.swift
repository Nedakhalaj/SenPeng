import SwiftUI

/// A saved trip's status, always with an icon and text.
struct TripStatusBadge: View {

    /// The status to show.
    let status: TripRowStatus

    var body: some View {
        switch status {
        case .claimable(let daysLeft):
            claimable(daysLeft: daysLeft)
        case .onTheWay:
            StatusBadge("On the way", style: .neutral, systemImage: "location.fill")
        case .arrived(let minutesLate) where minutesLate > 0:
            StatusBadge("\(minutesLate) min late", style: .neutral, systemImage: "clock.fill")
        case .arrived:
            StatusBadge("On time", style: .neutral, systemImage: "checkmark.circle.fill")
        case .delayUnknown:
            StatusBadge("Delay unknown", style: .neutral, systemImage: "questionmark.circle.fill")
        case .expired:
            StatusBadge("Claim time has passed", style: .neutral, systemImage: "calendar.badge.exclamationmark")
        case .submitted:
            StatusBadge("Claim submitted", style: .success, systemImage: "paperplane.fill")
        }
    }

    /// The days left to claim. It turns to a warning in the last week.
    @ViewBuilder
    private func claimable(daysLeft: Int) -> some View {
        let style: StatusStyle = daysLeft <= 7 ? .warning : .success
        switch daysLeft {
        case 0:
            StatusBadge("Last day today", style: style, systemImage: "calendar")
        case 1:
            StatusBadge("1 day left", style: style, systemImage: "calendar")
        default:
            StatusBadge("\(daysLeft) days left", style: style, systemImage: "calendar")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s) {
        TripStatusBadge(status: .claimable(daysLeft: 45))
        TripStatusBadge(status: .claimable(daysLeft: 1))
        TripStatusBadge(status: .claimable(daysLeft: 0))
        TripStatusBadge(status: .onTheWay)
        TripStatusBadge(status: .arrived(minutesLate: 4))
        TripStatusBadge(status: .arrived(minutesLate: 0))
        TripStatusBadge(status: .delayUnknown)
        TripStatusBadge(status: .expired)
        TripStatusBadge(status: .submitted)
    }
    .padding(Spacing.l)
    .appBackground()
}
