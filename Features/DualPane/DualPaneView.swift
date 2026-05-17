import SwiftUI
import SwiftData

struct DualPaneView: View {
    @Environment(\.modelContext) private var modelContext
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
            handleKeyPress(press)
        }
        .onKeyPress(keys: [
            KeyEquivalent(Character(Unicode.Scalar(0xF705)!)), // F2
            KeyEquivalent(Character(Unicode.Scalar(0xF708)!)), // F5
            KeyEquivalent(Character(Unicode.Scalar(0xF709)!)), // F6
        ]) { press in
            guard session.current.editing == nil else { return .ignored }
            guard !session.current.addressEditing else { return .ignored }
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
            session.attachPathHistory(modelContext)
            await session.bootstrap()
        }
    }

    @MainActor
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        // 편집 모달 활성 시 모든 키를 TextField에 양보
        guard session.current.editing == nil else { return .ignored }

        // 주소 입력 모드: Esc로 취소, ⌘L 재진입만 처리. 나머지는 TextField로
        if session.current.addressEditing {
            if press.key == .escape {
                session.current.cancelAddressEditing()
                return .handled
            }
            let qwerty = KoreanShortcutNormalizer.qwertyCharacter(for: press)
            if qwerty == "l", press.modifiers.contains(.command) {
                session.current.beginAddressEditing()
                return .handled
            }
            return .ignored
        }

        // 빌트인 KeyEquivalent 분기 (방향키는 modifier에 따라 동작 다름)
        switch press.key {
        case .tab:
            session.toggleActive()
            return .handled
        case .return:
            Task { await session.current.handleDoubleClick(via: session.fs) }
            return .handled
        case .space:
            session.current.spacePress()
            return .handled
        case .escape:
            session.current.clearSelection()
            return .handled
        case .upArrow:
            if press.modifiers.contains(.command) {
                Task { await session.current.ascend(via: session.fs) }
            } else if press.modifiers.contains(.shift) {
                session.current.shiftUpPress()
            } else {
                session.moveSelectionInActivePane(delta: -1)
            }
            return .handled
        case .downArrow:
            if press.modifiers.contains(.shift) {
                session.current.shiftDownPress()
            } else {
                session.moveSelectionInActivePane(delta: 1)
            }
            return .handled
        default:
            break
        }

        // modifier 없는 단일 문자 "." → 부모로 ascend (한글 IME도 ASCII 구두점은 변환 안 함)
        if press.key == KeyEquivalent("."), press.modifiers.isEmpty {
            Task { await session.current.ascend(via: session.fs) }
            return .handled
        }

        // modifier+문자 단축키 테이블 (한글 IME 정규화 후 비교)
        let qwerty = KoreanShortcutNormalizer.qwertyCharacter(for: press)
        for shortcut in DualPaneShortcuts.letterShortcuts where shortcut.matches(qwerty: qwerty, modifiers: press.modifiers) {
            shortcut.action(session)
            return .handled
        }

        return .ignored
    }
}

#Preview {
    DualPaneView()
        .modelContainer(try! PersistenceBootstrap.makeEmptyContainer())
}
