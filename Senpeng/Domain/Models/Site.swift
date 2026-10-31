import Foundation

/// A stop in SL's list of all stops, as shown in stop search.
///
/// SL calls these "sites". One site can have several platforms or bus stops,
/// for example Slussen has the metro, buses and the Saltsjöbanan.
struct Site: Identifiable, Equatable, Hashable, Sendable {

    /// SL's site ID, used to ask for departures, for example "9192" for Slussen.
    let id: String

    /// The stop's name, for example "Slussen".
    let name: String

    /// The area, when the name alone isn't clear, for example "Gottröra" for one of two "Bålsta".
    let area: String?

    /// Other names the stop is known by, for example "Höganäs brygga".
    let aliases: [String]

    /// The stop as saved in a trip.
    var transportStop: TransportStop {
        TransportStop(id: id, name: name)
    }
}
