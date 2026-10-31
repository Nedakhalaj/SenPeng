import Foundation

/// A stop or station in SL's network, for example Slussen.
struct TransportStop: Equatable, Hashable, Sendable {

    /// SL's ID for the stop, used when asking the API about it.
    let id: String

    /// The stop's name as shown to the user.
    let name: String

    /// SL's global stop ID, used to ask the journey planner about a saved trip later.
    let globalID: String
}
