import XCTest

/// Checks that the app starts and shows its main navigation.
final class LaunchUITests: XCTestCase {


    override func setUpWithError() throws {
        // Stop at the first failure; later steps depend on earlier ones.
        continueAfterFailure = false
    }


    /// The app launches and shows the three main tabs.
    @MainActor
    func testLaunchShowsThreeTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertEqual(tabBar.buttons.count, 3)
    }
}
