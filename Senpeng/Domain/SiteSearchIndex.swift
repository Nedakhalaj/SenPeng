import Foundation

/// Searches SL's stops on the device, instantly, while the user types.
///
/// The searchable text of every stop is prepared once when the index is built,
/// so each search only compares short strings.
struct SiteSearchIndex: Sendable {

    /// A stop with its prepared search text.
    private struct Entry: Sendable {
        let site: Site
        let name: String
        let words: [String]
        let aliases: [String]
    }

    /// All stops, prepared for searching.
    private let entries: [Entry]

    /// Builds the index. Runs off the main thread, because preparing
    /// thousands of names takes a moment.
    /// - Parameter sites: All stops.
    /// - Returns: The index.
    @concurrent
    static func make(from sites: [Site]) async -> SiteSearchIndex {
        SiteSearchIndex(sites: sites)
    }

    /// Builds the index on the current thread. Use `make(from:)` from the UI.
    /// - Parameter sites: All stops.
    init(sites: [Site]) {
        entries = sites.map { site in
            let name = Self.normalize(site.name)
            return Entry(
                site: site,
                name: name,
                words: name.split(whereSeparator: { " /-".contains($0) }).map(String.init),
                aliases: site.aliases.map(Self.normalize)
            )
        }
    }

    /// Finds the stops that match what the user typed, best matches first.
    ///
    /// Ranking: exact name, then names that start with the text, then names with
    /// a word that starts with it, then other names (aliases), then names that
    /// contain it anywhere. Shorter names come first within each group.
    ///
    /// - Parameters:
    ///   - query: What the user typed.
    ///   - limit: The most results to return.
    /// - Returns: The matching stops, or an empty list for an empty query.
    func search(_ query: String, limit: Int = 30) -> [Site] {
        let text = Self.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !text.isEmpty else {
            return []
        }

        return entries
            .compactMap { entry in rank(of: entry, for: text).map { (entry, $0) } }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 < rhs.1
                }
                if lhs.0.name.count != rhs.0.name.count {
                    return lhs.0.name.count < rhs.0.name.count
                }
                return lhs.0.name < rhs.0.name
            }
            .prefix(limit)
            .map(\.0.site)
    }

    /// How well a stop matches the search text: lower is better, `nil` is no match.
    private func rank(of entry: Entry, for text: String) -> Int? {
        if entry.name == text {
            return 0
        }
        if entry.name.hasPrefix(text) {
            return 1
        }
        if entry.words.contains(where: { $0.hasPrefix(text) }) {
            return 2
        }
        if entry.aliases.contains(where: { $0.hasPrefix(text) }) {
            return 3
        }
        if entry.name.contains(text) {
            return 4
        }
        return nil
    }

    /// Makes text comparable: lowercase, and å/ä/ö/é become a/a/o/e.
    ///
    /// Ignoring the dots and rings lets people without a Swedish keyboard
    /// find "Östermalmstorg" by typing "ostermalm".
    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
