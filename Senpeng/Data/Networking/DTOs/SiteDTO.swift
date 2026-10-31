import Foundation

/// One stop as SL's Transport API sends it (`GET /sites`).
///
/// Only the fields the app uses are decoded. The type is also used to save
/// the downloaded list on the device, so it's `Encodable` too.
struct SiteDTO: Codable, Equatable, Sendable {

    /// SL's site ID, for example 9192 for Slussen.
    let id: Int

    /// The stop's name.
    let name: String

    /// A clarifying area name, when the stop name isn't unique.
    let note: String?

    /// Other names the stop is known by.
    let alias: [String]?

    /// Latitude, kept for "nearby stops" later.
    let lat: Double?

    /// Longitude, kept for "nearby stops" later.
    let lon: Double?

    /// Converts the DTO to the app's own model.
    /// - Returns: The stop.
    func toSite() -> Site {
        Site(id: String(id), name: name, area: note, aliases: alias ?? [])
    }
}
