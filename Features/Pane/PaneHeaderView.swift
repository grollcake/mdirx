import SwiftUI

struct PaneHeaderView: View {
    @Bindable var state: PaneState
    let onActivate: @MainActor () -> Void
    let onSegmentTap: @MainActor (URL) -> Void

    var body: some View {
        HStack(spacing: 8) {
            BreadcrumbView(
                currentURL: state.currentURL,
                mountedVolumes: state.mountedVolumes,
                paneSlot: state.slot,
                onTap: onSegmentTap
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(FileColorToken.neutralBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            onActivate()
        }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).header")
    }
}
