import Foundation

extension TransportMode {

    /// The vehicle type's name, for VoiceOver and labels.
    var displayName: LocalizedStringResource {
        switch self {
        case .metro: "Metro"
        case .bus: "Bus"
        case .train: "Commuter train"
        case .tram: "Tram"
        case .ferry: "Ferry"
        }
    }

    /// The SF Symbol for the vehicle type, as defined in the design rules.
    var symbolName: String {
        switch self {
        case .metro, .tram: "tram.fill"
        case .bus: "bus.fill"
        case .train: "train.side.front.car"
        case .ferry: "ferry.fill"
        }
    }
}
