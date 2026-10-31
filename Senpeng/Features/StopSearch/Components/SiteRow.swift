import SwiftUI

/// One stop in the search results: its name, and the area when the name isn't unique.
struct SiteRow: View {

    /// The stop to show.
    let site: Site

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(site.name)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
                if let area = site.area {
                    Text(area)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        // VoiceOver reads the row as one item: "Bålsta, Gottröra".
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        SiteRow(site: PreviewSiteRepository.sampleSites[0])
        SiteRow(site: PreviewSiteRepository.sampleSites[5])
    }
}
