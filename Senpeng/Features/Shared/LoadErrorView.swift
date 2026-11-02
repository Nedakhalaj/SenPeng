import SwiftUI

/// A calm full-screen error message with a "Try again" button.
///
/// Used by every screen that loads data, so errors always look and work the same.
struct LoadErrorView: View {

    /// What failed, for example "Couldn't load stops".
    let title: LocalizedStringKey

    /// The friendly explanation shown below the title.
    let error: UserFacingError

    /// Runs when the user taps "Try again".
    let retry: @MainActor () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.message)
                .foregroundStyle(AppColor.textSecondary)
        } actions: {
            Button("Try again") {
                Task { await retry() }
            }
            .primaryButtonStyle()
        }
    }
}

#Preview {
    LoadErrorView(title: "Couldn't load stops", error: .offline) {}
        .appBackground()
}
