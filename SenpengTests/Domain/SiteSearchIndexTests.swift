import Foundation
import Testing
@testable import Senpeng

/// Checks how stop search matches and ranks stops.
@Suite("Site search index")
struct SiteSearchIndexTests {

    private let index = SiteSearchIndex(sites: [
        Site(id: "9192", name: "Slussen", area: nil, aliases: [], globalID: "9091001000009192"),
        Site(id: "9195", name: "Slussen/Södermalmstorg", area: nil, aliases: [], globalID: "9091001000009195"),
        Site(id: "9194", name: "Slussen/Stadsgården", area: nil, aliases: [], globalID: "9091001000009194"),
        Site(id: "9206", name: "Östermalmstorg", area: nil, aliases: [], globalID: "9091001000009206"),
        Site(id: "9001", name: "T-Centralen", area: nil, aliases: [], globalID: "9091001000009001"),
        Site(id: "408", name: "Höganäs", area: "Tynningö", aliases: ["Höganäs brygga"], globalID: "9091001000000408"),
        Site(id: "9999", name: "Stora Mossen", area: nil, aliases: [], globalID: "9091001000009999")
    ])

    @Test("An empty or blank query finds nothing", arguments: ["", "   "])
    func emptyQuery(query: String) {
        #expect(index.search(query).isEmpty)
    }

    @Test("The exact name comes first, then longer names starting with it")
    func exactMatchFirst() {
        let names = index.search("slussen").map(\.name)

        #expect(names == ["Slussen", "Slussen/Stadsgården", "Slussen/Södermalmstorg"])
    }

    @Test("Upper and lower case don't matter")
    func caseInsensitive() {
        #expect(index.search("SLUSSEN").first?.id == "9192")
    }

    @Test("Å, ä and ö can be typed as a and o", arguments: ["ostermalm", "Östermalm", "hoganas"])
    func ignoresSwedishDots(query: String) {
        #expect(!index.search(query).isEmpty)
    }

    @Test("A word inside the name matches, for example 'centralen'")
    func matchesWordInName() {
        #expect(index.search("centralen").map(\.id) == ["9001"])
    }

    @Test("Another name of the stop matches")
    func matchesAlias() {
        #expect(index.search("höganäs brygga").map(\.id) == ["408"])
    }

    @Test("Text in the middle of a name matches last")
    func containsMatchesLast() {
        // "mossen" starts a word in "Stora Mossen"; "ssen" is only inside names.
        #expect(index.search("ssen").first?.name == "Slussen")
        #expect(index.search("mossen").map(\.id) == ["9999"])
    }

    @Test("The number of results is limited")
    func limit() {
        #expect(index.search("s", limit: 2).count == 2)
    }

    @Test("Text that matches nothing finds nothing")
    func noMatch() {
        #expect(index.search("xyz").isEmpty)
    }
}
