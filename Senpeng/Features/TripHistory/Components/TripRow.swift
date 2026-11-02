import SwiftUI

/// One saved trip: line, stops, date and status.
struct TripRow: View {

    /// The trip to show.
    let item: TripHistoryItem

    /// The user's text size.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The badge and date side by side normally, stacked at the largest text sizes.
    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.s))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            headerLayout {
                LineBadge(line: item.trip.line, mode: item.trip.transportMode)
                Text(item.trip.scheduledDeparture, format: StockholmTime.dateAndTime)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textSecondary)
                    // Wraps instead of being cut off at the largest text sizes.
                    .fixedSize(horizontal: false, vertical: true)
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

#if DEBUG
#Preview {
    let trip = PreviewTripRepository.sampleTrip()
    return List {
        TripRow(item: TripHistoryItem(trip: trip, eligibility: .expired, status: .claimable(daysLeft: 45)))
        TripRow(item: TripHistoryItem(trip: trip, eligibility: .delayTooShort, status: .arrived(minutesLate: 4)))
    }
}
#endif
