import SwiftUI

/// Tells the user they may get money back, what for, and by when to claim.
///
/// Shows nothing unless the trip may qualify. The wording never promises a payout,
/// and it's clear that the user submits the claim on sl.se themselves.
struct ClaimHint: View {

    /// The result for the trip.
    let eligibility: EligibilityResult

    var body: some View {
        if case .eligible(let deadline, let cap) = eligibility {
            VStack(alignment: .leading, spacing: Spacing.s) {
                StatusBadge("You may get money back", style: .success)

                Text("You may get part or all of your ticket price back.")
                Text("Or, for a taxi, your own car or another operator: up to \(cap, format: Self.kronor) with a receipt.")
                Text("You apply yourself on sl.se, by \(deadline.lastDay, format: Self.day).")
            }
            .font(.subheadline)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            // VoiceOver reads the hint as one item.
            .accessibilityElement(children: .combine)
        }
    }

    /// Whole kronor, for example "1 480 kr". SL's amounts have no öre.
    private static let kronor = Decimal.FormatStyle.Currency(code: "SEK").precision(.fractionLength(0))

    /// A date in the user's language, for example "31 January 2027", in Stockholm time.
    private static let day = Date.FormatStyle(date: .long, time: .omitted, timeZone: StockholmTime.timeZone)
}

#Preview {
    ClaimHint(eligibility: .eligible(ClaimDeadline(lastDay: Date()), alternativeTravelCap: 1_480))
        .padding(Spacing.l)
        .appBackground()
}
