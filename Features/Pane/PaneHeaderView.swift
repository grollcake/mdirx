import SwiftUI

struct PaneHeaderView: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    let pathHistory: PathHistoryStore
    let onActivate: @MainActor () -> Void
    let onSegmentTap: @MainActor (URL) -> Void

    var body: some View {
        HStack(spacing: 8) {
            if state.addressEditing {
                AddressBarView(
                    state: state,
                    fs: fs,
                    pathHistory: pathHistory,
                    onNavigate: { await state.submitAddressDraft(via: fs) }
                )
            } else {
                BreadcrumbView(
                    currentURL: state.currentURL,
                    mountedVolumes: state.mountedVolumes,
                    paneSlot: state.slot,
                    onTap: onSegmentTap,
                    onPathBarDoubleClick: {
                        state.beginAddressEditing()
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                PathHistoryMenuButton(pane: state.slot, pathHistory: pathHistory) { url in
                    Task {
                        await state.navigate(to: url, via: fs)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(minHeight: 28)
        .background(FileColorToken.neutralBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            onActivate()
        }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).header")
    }
}
