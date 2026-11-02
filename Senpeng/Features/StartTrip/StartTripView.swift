import SwiftUI

/// The "I'm on this train" sheet: choose where you get off, check the arrival, confirm.
struct StartTripView: View {

    /// The screen's logic and state.
    @State private var viewModel: StartTripViewModel

    /// Closes the sheet.
    @Environment(\.dismiss) private var dismiss

    /// Runs when the trip has been saved.
    private let onStarted: () -> Void

    /// Creates the sheet.
    /// - Parameters:
    ///   - viewModel: The screen's logic, set up with the chosen departure.
    ///   - onStarted: Runs when the trip has been saved.
    init(viewModel: StartTripViewModel, onStarted: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onStarted = onStarted
    }

    var body: some View {
        NavigationStack {
            content
                .appBackground()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        .task { await viewModel.loadStops() }
        // A short vibration confirms the trip was saved.
        .sensoryFeedback(.success, trigger: viewModel.step == .saved)
        .onChange(of: viewModel.step) { _, step in
            if step == .saved {
                onStarted()
                dismiss()
            }
        }
    }

    /// The sheet's title: the question while choosing, then the trip itself.
    private var title: LocalizedStringKey {
        viewModel.step == .choosingDestination ? "Where do you get off?" : "Your trip"
    }

    /// The main content for the current step.
    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .choosingDestination:
            destinationSearch
        case .checkingArrival:
            ProgressView("Checking arrival time…")
        case .readyToStart(let destination, let arrival):
            confirmation(destination: destination, arrival: arrival)
        case .arrivalFailed(let destination, let error):
            arrivalFailed(destination: destination, error: error)
        case .saved:
            // The sheet closes right away; this is only seen for a moment.
            Color.clear
        }
    }

    /// The search for the stop where the user gets off.
    private var destinationSearch: some View {
        destinationResults
            .searchable(text: $viewModel.query, prompt: Text("Search for your stop"))
    }

    /// The search results for the current state.
    @ViewBuilder
    private var destinationResults: some View {
        switch viewModel.destinations {
        case .idle, .loading:
            ProgressView("Loading stops…")
        case .failed(let error):
            LoadErrorView(title: "Couldn't load stops", error: error) {
                await viewModel.loadStops()
            }
        case .loaded(let sites):
            if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView(
                    "Where do you get off?",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Search for the stop where you get off.").foregroundStyle(AppColor.textSecondary)
                )
            } else if sites.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                List(sites) { site in
                    Button {
                        Task { await viewModel.choose(site) }
                    } label: {
                        SiteRow(site: site)
                    }
                    .listRowBackground(AppColor.surface)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    /// The trip summary with the main button.
    private func confirmation(destination: Site, arrival: ArrivalEstimate) -> some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                TripSummaryCard(
                    departure: viewModel.departure,
                    origin: viewModel.origin,
                    destination: destination,
                    arrival: arrival
                )

                if let error = viewModel.saveError {
                    Text(error.message)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(Spacing.l)
        }
        // The main action stays at the bottom, within thumb reach. The card above
        // scrolls, so nothing is cut off at the largest text sizes.
        .safeAreaInset(edge: .bottom) {
            confirmationButtons
        }
    }

    /// The main button and the way back.
    private var confirmationButtons: some View {
        VStack(spacing: Spacing.m) {
            Button {
                Task { await viewModel.startTrip() }
            } label: {
                Text("I'm on this train")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .primaryButtonStyle()

            Button {
                viewModel.changeDestination()
            } label: {
                Text("Change stop")
                    .frame(maxWidth: .infinity)
            }
            .secondaryButtonStyle()
        }
        .padding(Spacing.l)
    }

    /// The message when the arrival couldn't be found, with a way forward.
    private func arrivalFailed(destination: Site, error: UserFacingError) -> some View {
        ContentUnavailableView {
            Label("Couldn't check the arrival time", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.message)
                .foregroundStyle(AppColor.textSecondary)
        } actions: {
            Button("Change stop") {
                viewModel.changeDestination()
            }
            .primaryButtonStyle()

            // Trying again can't help when the departure simply doesn't stop there.
            if error != .notOnRoute {
                Button("Try again") {
                    Task { await viewModel.choose(destination) }
                }
                .secondaryButtonStyle()
            }
        }
    }
}

#if DEBUG
#Preview("Search") {
    StartTripView(viewModel: StartTripViewModel(
        departure: PreviewDepartureRepository.sampleDepartures()[0],
        origin: PreviewSiteRepository.sampleSites[0],
        siteRepository: PreviewSiteRepository(),
        arrivalRepository: PreviewArrivalRepository(),
        tripRepository: PreviewTripRepository()
    ))
}
#endif
