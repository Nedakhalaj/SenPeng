import Foundation
import Testing

/// Checks that the app bundle ships with the files every release needs.
///
/// These tests run inside the app, so `Bundle.main` is the Senpeng app bundle.
@Suite("Project setup")
struct ProjectSetupTests {


    /// The App Store requires a privacy manifest in the app bundle.
    @Test("Privacy manifest is included in the app")
    func privacyManifestIsBundled() {
        let url = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        #expect(url != nil)
    }

    /// Swedish is the main language of the app, so it must always be shipped.
    @Test("App is localized in Swedish and English", arguments: ["sv", "en"])
    func appIsLocalized(in language: String) {
        #expect(Bundle.main.localizations.contains(language))
    }
}
