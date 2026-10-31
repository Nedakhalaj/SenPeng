import Foundation

/// The kind of vehicle a trip is made with.
///
/// The raw values are stored on the device, so they must never change.
enum TransportMode: String, CaseIterable, Sendable {

    /// Tunnelbana (metro).
    case metro

    /// Bus.
    case bus

    /// Pendeltåg (commuter train).
    case train

    /// Tram and light rail (spårväg, Tvärbanan, Roslagsbanan, Saltsjöbanan).
    case tram

    /// Ferry (pendelbåt).
    case ferry
}
