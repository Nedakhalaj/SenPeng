import XCTest

/// Checks the app's main flow from start to end, with fake data.
final class CoreFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        // Stop at the first failure; later steps depend on earlier ones.
        continueAfterFailure = false
    }

    /// Search a stop, pick a departure, choose a destination, save the trip, and find it again.
    @MainActor
    func testSavingATripShowsItEverywhere() throws {
        let robot = AppRobot()
        robot.launch()

        robot.openDepartures()
        robot.openTripSummary()
        robot.waitForButton("I'm on this train").tap()

        // The glass bar shows the trip, on every tab.
        let bar = robot.app.buttons.matching(NSPredicate(format: "label CONTAINS 'T-Centralen'")).firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10))
        robot.openTab(1)
        XCTAssertTrue(robot.app.staticTexts["Claim soon"].waitForExistence(timeout: 10))
        XCTAssertTrue(bar.exists)

        // Its details open from the bar.
        robot.app.buttons.matching(NSPredicate(format: "label ENDSWITH 'On time' OR label CONTAINS 'min late'"))
            .firstMatch.tap()
        XCTAssertTrue(robot.app.buttons["Remove trip"].waitForExistence(timeout: 10))
    }

    /// A departure that's cancelled can't be used to start a trip.
    @MainActor
    func testCancelledDepartureCannotBeTapped() throws {
        let robot = AppRobot()
        robot.launch()

        robot.openDepartures()

        let cancelled = robot.app.buttons.matching(NSPredicate(format: "label CONTAINS 'Cancelled'")).firstMatch
        XCTAssertTrue(cancelled.waitForExistence(timeout: 10))
        XCTAssertFalse(cancelled.isEnabled)
    }

    /// Onboarding shows on a fresh start, and can be read through to the end.
    @MainActor
    func testOnboardingLeadsToTheApp() throws {
        let robot = AppRobot()
        robot.launch(hasSeenOnboarding: false)

        robot.waitForButton("Next").tap()
        robot.waitForButton("Next").tap()
        XCTAssertTrue(robot.waitForButton("Get started").isEnabled)
    }

    /// Settings links to the privacy policy, as Apple requires.
    @MainActor
    func testSettingsLinksToThePrivacyPolicy() throws {
        let robot = AppRobot()
        robot.launch()

        robot.openTab(2)
        // Found by label only: iOS versions report a link as different element types.
        XCTAssertTrue(robot.app.descendants(matching: .any)["Privacy policy"].waitForExistence(timeout: 15))
    }
}
