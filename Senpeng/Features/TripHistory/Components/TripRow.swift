import SwiftUI

/// One saved trip: line, stops, date and status.
struct TripRow: View {

    /// The trip to show.
    let item: TripHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                LineBadge(line: item.trip.line, mode: item.trip.transportMode)
                Text(item.trip.scheduledDeparture, format: StockholmTime.dateAndTime)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text(verbatim: "\(item.trip.origin.name) → \(item.trip.destination.name)")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            TripStatusBadge(status: item.status)
        }
        .padding(.vertical, Spacing.xs)
        // VoiceOver reads the row as one item.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let trip = PreviewTripRepository.sampleTrip()
    return List {
        TripRow(item: TripHistoryItem(trip: trip, eligibility: .expired, status: .claimable(daysLeft: 45)))
        TripRow(item: TripHistoryItem(trip: trip, eligibility: .delayTooShort, status: .arrived(minutesLate: 4)))
    }
}
