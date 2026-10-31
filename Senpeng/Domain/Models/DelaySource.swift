import Foundation

/// How the real arrival time of a trip was found out.
///
/// Shown in the trip details, so the user knows how reliable the delay is.
/// The raw values are stored on the device, so they must never change.
enum DelaySource: String, Sendable {

    /// Measured from real-time data while the app was open.
    case live

    /// Looked up afterwards from realised or historical data.
    case historical

    /// Entered by the user because no data could be found.
    case userReported
}
