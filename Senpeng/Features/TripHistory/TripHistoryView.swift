import SwiftUI

/// The My trips screen: trips the user may claim for at the top, all others below.
struct TripHistoryView: View {

    /// The screen's logic and state.
    @State private var viewModel: TripHistoryViewModel

    /// Changes whenever the current trip changes, so the list reloads.
    private let refreshToken: String

    /// Runs after a trip was removed here.
    private let onTripRemoved: () -> Void

    /// Runs when the user taps "Find a stop" on the empty screen.
    private let onFindStop: () -> Void

    /// Creates the screen.
    /// - Parameters:
    ///   - repository: Saves and loads the trips.
    ///   - refreshToken: Changes whenever the current trip changes, so the list reloads.
    ///   - onTripRemoved: Runs after a trip was removed here.
    ///   - onFindStop: Runs when the user taps "Find a stop" on the empty screen.
    init(
        repository: any TripRepository,
        refreshToken: String,
        onTripRemoved: @escaping () -> Void,
        onFindStop: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: TripHistoryViewModel(repository: repository))
        self.refreshToken = refreshToken
        self.onTripRemoved = onTripRemoved
        self.onFindStop = onFindStop
    }

    var body: some View {
        content
            .appBackground()
            // Tabs stay alive when switching, so this also reloads when the tab reappears.
            .onAppear {
                Task { await viewModel.load() }
            }
            .task(id: refreshToken) {
                await viewModel.load()
            }
    }

    /// The main content for the current state.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            LoadErrorView(title: "Couldn't load your trips", error: error) {
                await viewModel.load()
            }
        case .loaded(let history) where history.isEmpty:
            emptyState
        case .loaded(let history):
            list(history)
        }
    }

    /// What's shown before the first trip.
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No trips yet", systemImage: "tram")
        } description: {
            Text("Trips you save appear here.")
        } actions: {
            Button("Find a stop", action: onFindStop)
                .primaryButtonStyle()
        }
    }

    /// The two sections. Only the short top section uses glass, so long lists stay smooth.
    private func list(_ history: TripHistory) -> some View {
        List {
            if !history.claimSoon.isEmpty {
                Section("Claim soon") {
                    ForEach(history.claimSoon) { item in
                        navigationLink(for: item)
                            .padding(.horizontal, Spacing.l)
                            .padding(.vertical, Spacing.s)
                            .glassCard()
                            // Room around the card, so the row doesn't cut off its soft shadow.
                            .listRowInsets(EdgeInsets(
                                top: Spacing.m,
                                leading: Spacing.xs,
                                bottom: Spacing.m,
                                trailing: Spacing.xs
                            ))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            if !history.otherTrips.isEmpty {
                Section("Other trips") {
                    ForEach(history.otherTrips) { item in
                        navigationLink(for: item)
                            .listRowBackground(AppColor.surface)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    /// A row that opens the trip's details and can be swiped to remove the trip.
    private func navigationLink(for item: TripHistoryItem) -> some View {
        NavigationLink {
            TripDetailView(item: item) {
                await remove(item)
            }
        } label: {
            TripRow(item: item)
        }
        .swipeActions {
            Button("Remove trip", role: .destructive) {
                Task { await remove(item) }
            }
        }
    }

    /// Removes a trip and tells the app, so the glass bar updates if it was the current trip.
    private func remove(_ item: TripHistoryItem) async -> Bool {
        let didRemove = await viewModel.delete(id: item.id)
        if didRemove {
            onTripRemoved()
        }
        return didRemove
    }
}

#Preview("Trips") {
    let trips = [
        PreviewTripRepository.sampleTrip(),
        PreviewTripRepository.sampleTrip(from: Date().addingTimeInterval(-3 * 24 * 60 * 60))
    ]
    return NavigationStack {
        TripHistoryView(
            repository: PreviewTripRepository(trips: trips),
            refreshToken: "",
            onTripRemoved: {},
            onFindStop: {}
        )
        .navigationTitle("My trips")
    }
}

#Preview("Empty") {
    NavigationStack {
        TripHistoryView(
            repository: PreviewTripRepository(),
            refreshToken: "",
            onTripRemoved: {},
            onFindStop: {}
        )
        .navigationTitle("My trips")
    }
    .preferredColorScheme(.dark)
}
