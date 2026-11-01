import SwiftUI

/// The details of the current trip, opened from the glass bar above the tabs.
struct ActiveTripView: View {

    /// The screen's logic and state, shared with the bar.
    let viewModel: ActiveTripViewModel

    /// Closes the sheet.
    @Environment(\.dismiss) private var dismiss

    /// Whether the "Remove trip" confirmation is showing.
    @State private var isConfirmingRemoval = false

    var body: some View {
        NavigationStack {
            content
                .padding(Spacing.l)
                .frame(maxHeight: .infinity, alignment: .top)
                .appBackground()
                .navigationTitle("Your trip")
                .navigationBarTitleDisplayMode(.inline)
        }
        // Closes by itself when there's no longer a trip, for example after removing it.
        .onChange(of: viewModel.status) { _, status in
            if status == .none {
                dismiss()
            }
        }
    }

    /// The main content for the current status.
    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .none:
            EmptyView()
        case .following(let trip, let estimate):
            following(trip: trip, estimate: estimate)
        case .arrived(let trip):
            arrived(trip: trip)
        }
    }

    /// The trip on the way, with its times and the option to remove it.
    private func following(trip: Trip, estimate: ArrivalEstimate?) -> some View {
        VStack(spacing: Spacing.m) {
            card(trip: trip) {
                Text("Arrives \(trip.scheduledArrival, format: StockholmTime.clockTime)")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textPrimary)
                if let expected = estimate?.expected {
                    Text("Expected \(expected, format: StockholmTime.clockTime)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(AppColor.textSecondary)
                }
                ActiveTripStatusBadge(minutesLate: estimate?.expectedMinutesLate)
            }

            // iOS doesn't let the app measure the arrival in the background.
            Text("Open Senpeng when you arrive, so the real arrival time can be saved.")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(role: .destructive) {
                isConfirmingRemoval = true
            } label: {
                Text("Remove trip")
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
            .confirmationDialog("Remove this trip?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
                Button("Remove trip", role: .destructive) {
                    Task { await viewModel.removeTrip() }
                }
            }
        }
    }

    /// The trip after arrival, with the measured arrival time.
    private func arrived(trip: Trip) -> some View {
        VStack(spacing: Spacing.m) {
            card(trip: trip) {
                if let actualArrival = trip.actualArrival {
                    Text("Arrived \(actualArrival, format: StockholmTime.clockTime)")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(AppColor.textPrimary)
                }
                ActiveTripStatusBadge(minutesLate: trip.minutesLate)
            }

            ClaimHint(eligibility: viewModel.eligibility(for: trip))

            Spacer()

            Button {
                viewModel.dismissArrived()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .primaryButtonStyle()
        }
    }

    /// The glass card with the line and stops, and the given times below them.
    private func card<Times: View>(trip: Trip, @ViewBuilder times: () -> Times) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                LineBadge(line: trip.line, mode: trip.transportMode)
                Text(trip.lineDestination)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text(verbatim: "\(trip.origin.name) → \(trip.destination.name)")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            VStack(alignment: .leading, spacing: Spacing.s) {
                times()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .glassCard()
    }
}
