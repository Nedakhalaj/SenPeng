import SwiftUI

/// A small glass bar above the tabs that shows the current trip.
/// It's always one tap from the trip's details.
struct ActiveTripBar: View {

    /// The trip to show.
    let trip: Trip

    /// The whole minutes late, or `nil` while the delay is unknown.
    let minutesLate: Int?

    /// Runs when the user taps the bar.
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.s) {
                LineBadge(line: trip.line, mode: trip.transportMode)
                Text(verbatim: "→ \(trip.destination.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: Spacing.xs)
                ActiveTripStatusBadge(minutesLate: minutesLate)
            }
            .padding(Spacing.s)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassCard(interactive: true)
        // A compact bar, like the tab bar. It stops growing at this size, so it doesn't
        // cover the screen; the sheet it opens shows everything at the full text size.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityHint(Text("Show your trip"))
    }
}

#if DEBUG
#Preview {
    ActiveTripBar(
        trip: PreviewTripRepository.sampleTrip(),
        minutesLate: 4,
        onTap: {}
    )
    .padding(Spacing.l)
    .appBackground()
}
#endif
