import SwiftUI

struct DualPaneView: View {
    @State private var session = BrowserSession()
    @FocusState private var keyHandlingFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            PaneColumnView(
                state: session.left,
                isActive: session.activePane == .left,
                accessibilityPaneId: "pane.left",
                fs: session.fs,
                onActivate: { session.activePane = .left },
                onDoubleClick: {
                    Task { await session.left.handleDoubleClick(via: session.fs) }
                },
                onSegmentTap: { url in
                    session.activePane = .left
                    Task { await session.left.navigate(to: url, via: session.fs) }
                }
            )
            .frame(maxWidth: .infinity)

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(FileColorToken.neutralBackground)
                VStack(spacing: 2) {
                    Button {
                        Task { await session.syncLeftToRight() }
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { await session.syncRightToLeft() }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 5)
            }
            .frame(width: 20)

            PaneColumnView(
                state: session.right,
                isActive: session.activePane == .right,
                accessibilityPaneId: "pane.right",
                fs: session.fs,
                onActivate: { session.activePane = .right },
                onDoubleClick: {
                    Task { await session.right.handleDoubleClick(via: session.fs) }
                },
                onSegmentTap: { url in
                    session.activePane = .right
                    Task { await session.right.navigate(to: url, via: session.fs) }
                }
            )
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(Color.black)
        .navigationTitle("MdirX")
        .toolbarBackground(FileColorToken.neutralBackground, for: .windowToolbar)
        .focusable()
        .focused($keyHandlingFocused)
        .focusEffectDisabled()
        .onAppear { keyHandlingFocused = true }
        .onKeyPress { press in
            // 편집 모달이 열려 있으면 모달이 키를 처리하도록 양보
            guard session.current.editing == nil else { return .ignored }
            if press.key == .tab {
                session.toggleActive()
                return .handled
            }
            if press.key == .return {
                Task { await session.current.handleDoubleClick(via: session.fs) }
                return .handled
            }
            if press.key == .upArrow {
                if press.modifiers.contains(.command) {
                    Task { await session.current.ascend(via: session.fs) }
                } else if press.modifiers.contains(.shift) {
                    session.current.shiftUpPress()
                } else {
                    session.moveSelectionInActivePane(delta: -1)
                }
                return .handled
            }
            if press.key == .downArrow {
                if press.modifiers.contains(.shift) {
                    session.current.shiftDownPress()
                } else {
                    session.moveSelectionInActivePane(delta: 1)
                }
                return .handled
            }
            if press.key == .space {
                session.current.spacePress()
                return .handled
            }
            if press.key == .escape {
                session.current.clearSelection()
                return .handled
            }
            if press.key == KeyEquivalent("u"), press.modifiers.contains(.option) {
                session.current.selectAllToggle()
                return .handled
            }
            if press.key == KeyEquivalent("a"), press.modifiers.contains(.command) {
                session.current.selectAllToggle()
                return .handled
            }
            if press.key == KeyEquivalent(".") && press.modifiers.isEmpty {
                Task { await session.current.ascend(via: session.fs) }
                return .handled
            }
            if press.key == KeyEquivalent("z") {
                if press.modifiers.contains(.command) || press.modifiers.contains(.option) {
                    Task { await session.current.toggleHidden(via: session.fs) }
                    return .handled
                }
            }
            // ⌥K = new folder, ⌃N = new file (F2/F5/F6은 아래 keys: 오버로드에서 처리)
            if press.key == KeyEquivalent("k"), press.modifiers.contains(.option) {
                session.current.requestNewFolder()
                return .handled
            }
            if press.key == KeyEquivalent("n"), press.modifiers.contains(.control) {
                session.current.requestNewFile()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [
            KeyEquivalent(Character(Unicode.Scalar(0xF705)!)), // F2
            KeyEquivalent(Character(Unicode.Scalar(0xF708)!)), // F5
            KeyEquivalent(Character(Unicode.Scalar(0xF709)!)), // F6
        ]) { press in
            guard session.current.editing == nil else { return .ignored }
            switch press.key.character.unicodeScalars.first?.value {
            case 0xF705:
                session.current.requestRename()
                return .handled
            case 0xF708:
                Task { await session.copySelectionToOtherPane() }
                return .handled
            case 0xF709:
                Task { await session.moveSelectionToOtherPane() }
                return .handled
            default:
                return .ignored
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}

#Preview {
    DualPaneView()
}
