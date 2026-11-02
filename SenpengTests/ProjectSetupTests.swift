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

    /// The app uses `UserDefaults`, and Apple rejects apps that don't declare why.
    @Test("Privacy manifest declares UserDefaults, and says no tracking or collected data")
    func privacyManifestContent() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let manifest = try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        let apis = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = apis.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        }

        #expect(userDefaults?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
    }

    /// Swedish is the main language of the app, so it must always be shipped.
    @Test("App is localized in Swedish and English", arguments: ["sv", "en"])
    func appIsLocalized(in language: String) {
        #expect(Bundle.main.localizations.contains(language))
    }
}
