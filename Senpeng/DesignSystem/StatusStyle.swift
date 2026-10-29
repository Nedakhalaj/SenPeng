import SwiftUI

/// The visual style of a status: its color and default icon.
///
/// A status is always shown with an icon and text, never with color alone,
/// so it stays clear for people who can't tell the colors apart.
enum StatusStyle: CaseIterable {

    /// Something good, for example "You may get money back".
    case success

    /// Needs attention, for example a delay or a deadline coming soon.
    case warning

    /// Something went wrong or a deadline has passed.
    case danger

    /// Neutral information, for example "On time" or "Not eligible".
    case neutral

    /// The status color, used for the icon and a light background tint.
    var color: Color {
        switch self {
        case .success: AppColor.success
        case .warning: AppColor.warning
        case .danger: AppColor.danger
        case .neutral: AppColor.neutralStatus
        }
    }

    /// The SF Symbol shown when no other icon is given.
    var defaultSymbol: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .warning: "clock.badge.exclamationmark.fill"
        case .danger: "exclamationmark.triangle.fill"
        case .neutral: "minus.circle.fill"
        }
    }
}
