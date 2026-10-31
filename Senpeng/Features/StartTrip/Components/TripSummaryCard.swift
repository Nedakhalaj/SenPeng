import SwiftUI

/// A glass card that sums up the trip before the user confirms it:
/// the line, where they get on and off, and when it arrives.
struct TripSummaryCard: View {

    /// The departure the user is on.
    let departure: Departure

    /// The stop where the user gets on.
    let origin: Site

    /// The stop where the user gets off.
    let destination: Site

    /// When the departure arrives at the destination.
    let arrival: ArrivalEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                LineBadge(line: departure.line, mode: departure.transportMode)
                Text(departure.destination)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Text(verbatim: "\(origin.name) → \(destination.name)")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Arrives \(arrival.scheduled, format: StockholmTime.clockTime)")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textPrimary)

                // Only shown when the live time says something the timetable doesn't.
                if let expected = arrival.expected, expected != arrival.scheduled {
                    Text("Expected \(expected, format: StockholmTime.clockTime)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .glassCard()
        // VoiceOver reads the card as one item.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let scheduled = Date().addingTimeInterval(12 * 60)
    return TripSummaryCard(
        departure: PreviewDepartureRepository.sampleDepartures()[0],
        origin: PreviewSiteRepository.sampleSites[0],
        destination: PreviewSiteRepository.sampleSites[2],
        arrival: ArrivalEstimate(scheduled: scheduled, expected: scheduled.addingTimeInterval(180))
    )
    .padding(Spacing.l)
    .appBackground()
}
