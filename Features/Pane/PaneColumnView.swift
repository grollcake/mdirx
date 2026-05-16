import SwiftUI

struct PaneColumnView: View {
    @Bindable var state: PaneState
    let isActive: Bool
    let accessibilityPaneId: String
    let onActivate: @MainActor () -> Void
    let onDoubleClick: @MainActor () -> Void
    let onSegmentTap: @MainActor (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PaneHeaderView(
                state: state,
                onActivate: onActivate,
                onSegmentTap: onSegmentTap
            )

            PaneSummaryView(state: state)
                .contentShape(Rectangle())
                .onTapGesture {
                    onActivate()
                }

            FileListView(
                state: state,
                isActive: isActive,
                onActivate: onActivate,
                onRowDoubleClick: onDoubleClick
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            PaneStatusBar(state: state)
                .contentShape(Rectangle())
                .onTapGesture {
                    onActivate()
                }
        }
        .background(FileColorToken.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityIdentifier(accessibilityPaneId)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onActivate()
                onDoubleClick()
            }
        )
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                onActivate()
            }
        )
    }
}
