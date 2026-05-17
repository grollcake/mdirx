import SwiftUI

struct PaneHeaderView: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    let pathHistory: PathHistoryStore
    let onActivate: @MainActor () -> Void
    let onToggleActivePane: @MainActor () -> Void
    let onSegmentTap: @MainActor (URL) -> Void

    var body: some View {
        HStack(spacing: 8) {
            BreadcrumbView(
                currentURL: state.currentURL,
                mountedVolumes: state.mountedVolumes,
                paneSlot: state.slot,
                onTap: onSegmentTap,
                onPathBarDoubleClick: {
                    openAddressPopover()
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            PathHistoryMenuButton(pane: state.slot, pathHistory: pathHistory) { url in
                Task {
                    await state.navigate(to: url, via: fs)
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
        .popover(
            isPresented: Binding(
                get: { state.addressEditing },
                set: { open in if !open { state.cancelAddressEditing() } }
            ),
            attachmentAnchor: .point(.bottom),
            arrowEdge: .top
        ) {
            AddressPopoverView(
                state: state,
                fs: fs,
                onClose: { state.cancelAddressEditing() },
                onTabToggleActivePane: onToggleActivePane
            )
        }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).header")
    }

    private func openAddressPopover() {
        let items = (try? pathHistory.menuURLs(for: state.slot)) ?? (frequent: [], recent: [])
        state.beginAddressEditing(
            items: AddressListItems(frequent: items.frequent, recent: items.recent)
        )
    }
}
