import XCTest

/// Runs Apple's accessibility audit on the app's main screens, with fake data.
///
/// Colors and labels are checked at the normal text size, in light and dark mode.
/// Text size problems are checked at the largest size. At that size, contrast isn't checked:
/// rows sliding behind the tab bar look like low contrast to the audit, without being a problem.
final class AccessibilityUITests: XCTestCase {

    /// Labels of the system's own search fields, which can't be changed: at the largest
    /// sizes the system shortens a search field's placeholder text.
    private let systemSearchPrompts = ["Search for a stop", "Search for your stop"]

    /// Text the audit wrongly reports as low contrast. It measures text on translucent glass
    /// poorly; these were checked by eye in light and dark mode on 2026-11-02 and are clear.
    /// Their colors are also covered by the contrast tests in `AppColorTests`.
    private let readableTextOnGlass = ["Change stop", "You may get money back"]

    /// What's checked at the normal text size.
    private let colorAndLabelChecks: XCUIAccessibilityAuditType = [
        .contrast, .elementDetection, .hitRegion, .sufficientElementDescription, .trait
    ]

    /// What's checked at the largest text size.
    private let textSizeChecks: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]

    override func setUpWithError() throws {
        // Report every problem on a screen, not just the first.
        continueAfterFailure = true
    }

    @MainActor
    func testLightMode() throws {
        XCUIDevice.shared.appearance = .light
        try auditAllScreens(arguments: [], checks: colorAndLabelChecks)
    }

    @MainActor
    func testDarkMode() throws {
        XCUIDevice.shared.appearance = .dark
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = .light
        }
        try auditAllScreens(arguments: [], checks: colorAndLabelChecks)
    }

    @MainActor
    func testLargestText() throws {
        XCUIDevice.shared.appearance = .light
        try auditAllScreens(
            arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"],
            checks: textSizeChecks
        )
    }

    /// Walks through the main screens and audits each one.
    /// - Parameters:
    ///   - arguments: Extra launch arguments.
    ///   - checks: What the audit checks.
    @MainActor
    private func auditAllScreens(arguments: [String], checks: XCUIAccessibilityAuditType) throws {
        let robot = AppRobot()

        robot.launch(hasSeenOnboarding: false, extraArguments: arguments)
        robot.waitForButton("Next")
        try audit(robot, screen: "Onboarding", checks: checks)

        robot.launch(extraArguments: arguments)
        XCTAssertTrue(robot.app.searchFields.firstMatch.waitForExistence(timeout: 15))
        try audit(robot, screen: "Stop search", checks: checks)

        robot.openDepartures()
        robot.waitForDepartures()
        try audit(robot, screen: "Departures", checks: checks)

        robot.openTripSummary()
        try audit(robot, screen: "Trip summary", checks: checks)

        robot.launch(extraArguments: arguments)
        robot.openTab(1)
        XCTAssertTrue(robot.app.staticTexts["Claim soon"].waitForExistence(timeout: 15))
        try audit(robot, screen: "My trips", checks: checks)

        robot.tapButton(containing: "days left")
        robot.waitForButton("Remove trip")
        try audit(robot, screen: "Trip details", checks: checks)

        robot.launch(extraArguments: arguments)
        robot.openTab(2)
        robot.waitForButton("Delete all data")
        try audit(robot, screen: "Settings", checks: checks)
    }

    /// Runs the audit on the current screen. Each problem it finds fails the test,
    /// except problems in the system's own controls, which the app can't change.
    @MainActor
    private func audit(_ robot: AppRobot, screen: String, checks: XCUIAccessibilityAuditType) throws {
        let searchPrompts = systemSearchPrompts
        let textOnGlass = readableTextOnGlass
        try robot.app.performAccessibilityAudit(for: checks) { issue in
            let label = issue.element?.label ?? ""
            let isSystemControl = searchPrompts.contains(label) || label == "Cancel"
            let isKnownFalseAlarm = issue.auditType == .contrast && textOnGlass.contains(label)
            let isIgnored = isSystemControl || isKnownFalseAlarm
            if !isIgnored {
                NSLog("AUDIT-ISSUE %@ | %@ | %@", screen, issue.compactDescription, label)
            }
            return isIgnored
        }
    }
}
