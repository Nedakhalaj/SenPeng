import SwiftUI

/// Everything saved about one trip: times, how the delay was measured,
/// whether the user may claim, and the option to remove it.
struct TripDetailView: View {

    /// The trip to show.
    let item: TripHistoryItem

    /// Removes the trip. Returns `true` if it worked, so the screen can close.
    let onRemove: () async -> Bool

    /// Closes the screen.
    @Environment(\.dismiss) private var dismiss

    /// Whether the "Remove trip" confirmation is showing.
    @State private var isConfirmingRemoval = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                card
                ClaimHint(eligibility: item.eligibility)
                if item.status == .delayUnknown {
                    Text("No live data was saved for this trip, so the delay is unknown.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                removeButton
                    .padding(.top, Spacing.xl)
            }
            .padding(Spacing.l)
        }
        .appBackground()
        .navigationTitle("Your trip")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The glass card with the line, stops, times and status.
    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                LineBadge(line: item.trip.line, mode: item.trip.transportMode)
                Text(item.trip.lineDestination)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Text(verbatim: "\(item.trip.origin.name) → \(item.trip.destination.name)")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Departs \(item.trip.scheduledDeparture, format: StockholmTime.dateAndTime)")
                Text("Planned arrival \(item.trip.scheduledArrival, format: StockholmTime.clockTime)")
                if let actualArrival = item.trip.actualArrival {
                    Text("Arrived \(actualArrival, format: StockholmTime.clockTime)")
                }
                if let source = item.trip.delaySource {
                    Text(source.displayName)
                }
            }
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(AppColor.textSecondary)

            TripStatusBadge(status: item.status)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .glassCard()
    }

    /// The button that removes the trip, after a confirmation.
    private var removeButton: some View {
        Button(role: .destructive) {
            isConfirmingRemoval = true
        } label: {
            Text("Remove trip")
                .frame(maxWidth: .infinity)
        }
        .secondaryButtonStyle()
        .confirmationDialog("Remove this trip?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button("Remove trip", role: .destructive) {
                Task {
                    if await onRemove() {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TripDetailView(
            item: TripHistoryItem(
                trip: PreviewTripRepository.sampleTrip(),
                eligibility: .eligible(ClaimDeadline(lastDay: Date()), alternativeTravelCap: 1_480),
                status: .claimable(daysLeft: 45)
            ),
            onRemove: { true }
        )
    }
}
#endif
