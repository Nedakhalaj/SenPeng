import SwiftUI

/// One departure: line badge, destination, time, and a badge when it's late or cancelled.
struct DepartureRow: View {

    /// The departure to show.
    let departure: Departure

    var body: some View {
        HStack(spacing: Spacing.m) {
            LineBadge(line: departure.line, mode: departure.transportMode)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(departure.destination)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                status
            }

            Spacer(minLength: Spacing.s)

            Text(departure.bestKnownTime, format: StockholmTime.clockTime)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .strikethrough(departure.isCancelled)
                .foregroundStyle(departure.isCancelled ? AppColor.textSecondary : AppColor.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
        // VoiceOver reads the row as one item: "Metro, 14, Mörby centrum, 4 min late, 12:33".
        .accessibilityElement(children: .combine)
    }

    /// "Cancelled" or "x min late", or nothing when on time.
    @ViewBuilder
    private var status: some View {
        if departure.isCancelled {
            StatusBadge("Cancelled", style: .danger)
        } else if departure.minutesLate > 0 {
            StatusBadge("\(departure.minutesLate) min late", style: .warning)
        }
    }
}

#Preview {
    List(PreviewDepartureRepository.sampleDepartures()) { departure in
        DepartureRow(departure: departure)
    }
}
