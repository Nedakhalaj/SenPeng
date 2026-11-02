import SwiftUI

/// The Settings screen: notifications and language, deleting data, and about the app.
struct SettingsView: View {

    /// The screen's logic and state.
    @State private var viewModel: SettingsViewModel

    /// Whether the "Delete all data" confirmation is showing.
    @State private var isConfirmingDeletion = false

    /// Trafiklab's website, credited as the data source as their terms require.
    private let trafiklabURL = URL(string: "https://www.trafiklab.se")

    /// This app's page in iOS Settings, where notifications and language are chosen.
    private let systemSettingsURL = URL(string: UIApplication.openSettingsURLString)

    /// Creates the screen.
    /// - Parameter viewModel: The screen's logic.
    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            systemSettingsSection
            dataSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .sensoryFeedback(.success, trigger: viewModel.deletionState == .deleted)
    }

    /// The link to iOS Settings.
    private var systemSettingsSection: some View {
        Section {
            if let systemSettingsURL {
                Link("Open iOS Settings", destination: systemSettingsURL)
                    .listRowBackground(AppColor.surface)
            }
        } footer: {
            Text("Choose notifications and language for Senpeng in iOS Settings.")
        }
    }

    /// Deleting all data, after a confirmation.
    private var dataSection: some View {
        Section {
            Button("Delete all data", role: .destructive) {
                isConfirmingDeletion = true
            }
            .listRowBackground(AppColor.surface)
            .confirmationDialog(
                "Delete all trips and reminders?",
                isPresented: $isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete all data", role: .destructive) {
                    Task { await viewModel.deleteAllData() }
                }
            } message: {
                Text("This can't be undone.")
            }
        } footer: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your trips are saved only on this phone.")
                switch viewModel.deletionState {
                case .idle:
                    EmptyView()
                case .deleted:
                    Text("All data is deleted.")
                case .failed(let error):
                    Text(error.message)
                }
            }
        }
    }

    /// The disclaimer, the data source credit and the version.
    private var aboutSection: some View {
        Section("About") {
            Text("Not affiliated with SL / Region Stockholm. Claims are submitted by you on sl.se.")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .listRowBackground(AppColor.surface)

            if let trafiklabURL {
                Link("Travel data from Trafiklab", destination: trafiklabURL)
                    .listRowBackground(AppColor.surface)
            }

            LabeledContent("Version", value: viewModel.appVersion)
                .listRowBackground(AppColor.surface)
        }
    }
}

#Preview("Light") {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(tripRepository: PreviewTripRepository(), onDataDeleted: {}))
            .navigationTitle("Settings")
    }
}

#Preview("Dark") {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(tripRepository: PreviewTripRepository(), onDataDeleted: {}))
            .navigationTitle("Settings")
    }
    .preferredColorScheme(.dark)
}
