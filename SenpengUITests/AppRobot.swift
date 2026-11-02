import XCTest

/// Drives the app through its main screens in UI tests, so each test reads as a list of steps.
///
/// The app runs with fake data (`-useFakeData`), so tests never depend on SL's servers.
@MainActor
struct AppRobot {

    /// The app being tested.
    let app = XCUIApplication()

    /// How long to wait for a screen to appear, in seconds.
    private let timeout: TimeInterval = 15

    /// Starts the app with fake data.
    /// - Parameters:
    ///   - hasSeenOnboarding: Whether to skip onboarding.
    ///   - extraArguments: More launch arguments, for example a text size.
    func launch(hasSeenOnboarding: Bool = true, extraArguments: [String] = []) {
        app.launchArguments = ["-useFakeData", "-hasSeenOnboarding", hasSeenOnboarding ? "YES" : "NO"] + extraArguments
        app.launch()
    }

    /// Opens a tab.
    /// - Parameter index: 0 for Now, 1 for My trips, 2 for Settings.
    func openTab(_ index: Int) {
        app.tabBars.buttons.element(boundBy: index).tap()
    }

    /// Searches for a stop in the search field on screen.
    /// - Parameter name: What to type.
    func search(for name: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText(name)
    }

    /// Taps the first button whose label starts with some text.
    /// - Parameter text: The start of the label.
    func tapButton(startingWith text: String) {
        let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "No button starts with \(text)")
        button.tap()
    }

    /// Taps the first button whose label contains some text.
    /// - Parameter text: A part of the label.
    func tapButton(containing text: String) {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "No button contains \(text)")
        button.tap()
    }

    /// Waits for a button to appear.
    /// - Parameter label: The button's exact label.
    /// - Returns: The button.
    @discardableResult
    func waitForButton(_ label: String) -> XCUIElement {
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "No button \(label)")
        return button
    }

    /// Goes from the Now tab to the departures of Slussen.
    func openDepartures() {
        search(for: "Slussen")
        tapButton(startingWith: "Slussen")
    }

    /// Waits until Slussen's departures are showing.
    func waitForDepartures() {
        let departure = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Mörby centrum'")).firstMatch
        XCTAssertTrue(departure.waitForExistence(timeout: timeout), "No departures showing")
    }

    /// Goes from Slussen's departures to the summary card, ready to start a trip on line 14.
    func openTripSummary() {
        tapButton(containing: "Mörby centrum")
        search(for: "T-Centralen")
        tapButton(startingWith: "T-Centralen")
        waitForButton("I'm on this train")
    }
}
