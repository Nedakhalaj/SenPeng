#if DEBUG
import Foundation

/// A fake `SiteRepository` for SwiftUI previews, with a few real SL stops.
struct PreviewSiteRepository: SiteRepository {

    /// What the fake returns: a list of stops, or an error to preview the error state.
    var result: Result<[Site], NetworkError> = .success(Self.sampleSites)

    func sites() async throws(NetworkError) -> [Site] {
        try result.get()
    }

    /// A few real stops for previews.
    static let sampleSites: [Site] = [
        Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192"),
        Site(id: "9194", name: "Slussen/Stadsgården", area: nil, aliases: [], globalID: "9091001000009194"),
        Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001"),
        Site(id: "9206", name: "Östermalmstorg", area: nil, aliases: [], globalID: "9091001000009206"),
        Site(id: "9710", name: "Bålsta", area: nil, aliases: [], globalID: "9091001000009710"),
        Site(id: "5299", name: "Bålsta", area: "Gottröra", aliases: [], globalID: "9091001000005299")
    ]
}
#endif
