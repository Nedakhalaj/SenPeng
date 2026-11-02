import SwiftUI

/// Three short screens explaining the app, shown once, and skippable.
///
/// The rule values come from `CompensationPolicy`, so this text can't go out of date.
struct OnboardingView: View {

    /// Runs when the user finishes or skips onboarding.
    let onFinish: () -> Void

    /// The screen being shown, from 0 to `lastPage`.
    @State private var page = 0

    /// The index of the last screen.
    private let lastPage = 2

    var body: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .opacity(page == lastPage ? 0 : 1)
                    .disabled(page == lastPage)
            }

            TabView(selection: $page) {
                ruleScreen.tag(0)
                followScreen.tag(1)
                reminderScreen.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Button {
                if page == lastPage {
                    onFinish()
                } else {
                    page += 1
                }
            } label: {
                Text(page == lastPage ? "Get started" : "Next")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .primaryButtonStyle()
        }
        .padding(Spacing.l)
        .appBackground()
    }

    /// Explains the rule.
    private var ruleScreen: some View {
        screen(systemImage: "banknote", title: "Late? You may get money back") {
            let minutes = CompensationPolicy.minimumDelayMinutes()
            Text("If your SL trip is more than \(minutes) minutes late, you may get part or all of your ticket price back.")
            Text("Many people never claim, because they forget or don't know the rules.")
        }
    }

    /// Explains what the app does on a trip.
    private var followScreen: some View {
        screen(systemImage: "tram.fill", title: "Tap \"I'm on this train\"") {
            Text("Pick your departure and where you get off. Senpeng saves the trip and follows the delay.")
            Text("Open Senpeng when you arrive, so the real arrival time can be saved.")
        }
    }

    /// Explains the reminders and who submits the claim.
    private var reminderScreen: some View {
        screen(systemImage: "bell.fill", title: "We remind you, you apply") {
            Text("You have \(CompensationPolicy.claimWindowMonths()) months to apply. Senpeng reminds you before the time runs out.")
            Text("Not affiliated with SL / Region Stockholm. Claims are submitted by you on sl.se.")
        }
    }

    /// One screen with an icon, a title and some text. It scrolls at large text sizes.
    private func screen<Content: View>(
        systemImage: String,
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColor.accent)
                    .accessibilityHidden(true)
                    .padding(.top, Spacing.xxl)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: Spacing.m) {
                    content()
                }
                .font(.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Light") {
    OnboardingView(onFinish: {})
}

#Preview("Dark") {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.dark)
}
