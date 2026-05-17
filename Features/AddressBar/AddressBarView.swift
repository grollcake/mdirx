import AppKit
import SwiftUI

// MARK: - ⌘L 주소 popover 리스트 스크롤 뷰포트 (파일 리스트와 동일: 가시하면 스크롤 안 함·클립 시만 top/bottom)

private enum AddressPopoverViewportGlobalPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 1, next.height > 1 { value = next }
    }
}

private enum AddressPopoverRowGlobalFramesPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] { [:] }
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, n in n })
    }
}

/// SwiftUI `TextField`가 단독으로는 focus 시 전체 선택을 보장하지 않는다.
/// NSText의 `selectAll(_:)`을 first responder에게 보내 전체 선택을 강제한다.
@MainActor
private func selectAllInFocusedField() {
    // SwiftUI focus 적용 직후 한 틱 양보 — TextField가 first responder가 된 뒤 호출돼야 한다.
    DispatchQueue.main.async {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSText.selectAll(_:)), with: nil
        )
    }
}

struct PathHistoryMenuButton: View {
    let pane: PaneSlot
    let pathHistory: PathHistoryStore
    let onPick: @MainActor (URL) -> Void

    var body: some View {
        let sections: (frequent: [URL], recent: [URL]) =
            (try? pathHistory.menuURLs(for: pane)) ?? (frequent: [], recent: [])
        Menu {
            if !sections.frequent.isEmpty {
                Section("자주 방문") {
                    ForEach(sections.frequent, id: \.path) { url in
                        Button(url.path) { onPick(url) }
                    }
                }
            }
            if !sections.recent.isEmpty {
                Section("최근 방문") {
                    ForEach(sections.recent, id: \.path) { url in
                        Button(url.path) { onPick(url) }
                    }
                }
            }
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(FileColorToken.mutedChromeForeground)
                .frame(width: 22, height: 22)
        }
        .tint(FileColorToken.mutedChromeForeground)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .accessibilityIdentifier("pane.\(pane.rawValue).path.history")
    }
}

/// `⌘L` 또는 path bar 더블클릭으로 열리는 popover.
/// 상단 TextField(직접 경로 입력) + 하단 자주/최근 방문 리스트(↑↓로 탐색, Enter로 선택).
struct AddressPopoverView: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    let onClose: @MainActor () -> Void
    let onTabToggleActivePane: @MainActor () -> Void

    @FocusState private var fieldFocused: Bool
    @FocusState private var listFocused: Bool

    @State private var addressPopoverViewportGlobal: CGRect = .zero
    @State private var addressPopoverRowFramesGlobalByIndex: [Int: CGRect] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("절대 경로 또는 ~", text: $state.addressDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                )
                .focused($fieldFocused)
                .onAppear {
                    syncKeyboardFocus(to: state.addressListFocusIndex)
                }
                .onChange(of: state.addressListFocusIndex) { _, new in
                    syncKeyboardFocus(to: new)
                }
                // ⌘L 재누름 (address-bar-history.md R5) → TextField로 복귀 + 전체 선택
                .onChange(of: state.addressFocusToken) { _, _ in
                    syncKeyboardFocus(to: nil)
                }
                .onSubmit {
                    Task { await state.submitAddressDraft(via: fs) }
                }
                .onKeyPress(.downArrow) {
                    state.focusListFirst() ? .handled : .ignored
                }
                .accessibilityIdentifier("pane.\(state.slot.rawValue).address.field")

            if let err = state.addressError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .lineLimit(2)
            }

            if !state.addressListFlat.isEmpty {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if !state.addressListItems.frequent.isEmpty {
                                sectionHeader("자주 방문")
                                ForEach(Array(state.addressListItems.frequent.enumerated()), id: \.element.path) { offset, url in
                                    row(url: url, index: offset)
                                        .id(offset)
                                }
                            }
                            if !state.addressListItems.recent.isEmpty {
                                sectionHeader("최근 방문")
                                ForEach(Array(state.addressListItems.recent.enumerated()), id: \.element.path) { offset, url in
                                    let globalIndex = state.addressListItems.frequent.count + offset
                                    row(url: url, index: globalIndex)
                                        .id(globalIndex)
                                }
                            }
                        }
                    }
                    .background(
                        GeometryReader { viewportGeo in
                            Color.clear.preference(
                                key: AddressPopoverViewportGlobalPreferenceKey.self,
                                value: viewportGeo.frame(in: .global)
                            )
                        }
                    )
                    .onPreferenceChange(AddressPopoverViewportGlobalPreferenceKey.self) { addressPopoverViewportGlobal = $0 }
                    .onPreferenceChange(AddressPopoverRowGlobalFramesPreferenceKey.self) {
                        addressPopoverRowFramesGlobalByIndex = $0
                    }
                    .onChange(of: state.addressListFocusIndex) { oldIdx, newIdx in
                        scrollAddressListFocusedRowIfNeeded(proxy: proxy, oldIndex: oldIdx, newIndex: newIdx)
                    }
                }
                .frame(maxHeight: 220)
                .focusable()
                .focused($listFocused)
                .focusEffectDisabled()
            }
        }
        .padding(8)
        .frame(width: 360)
        .background(FileColorToken.panelBackground)
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .onKeyPress(.tab) {
            // Tab → popover close + 활성 패널 toggle
            onClose()
            onTabToggleActivePane()
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard state.addressListFocusIndex != nil else { return .ignored }
            state.focusListPrevious()
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard state.addressListFocusIndex != nil else { return .ignored }
            state.focusListNext()
            return .handled
        }
        .onKeyPress(.return) {
            guard let url = state.addressListFocusedURL else { return .ignored }
            Task {
                await state.navigate(to: url, via: fs)
                onClose()
            }
            return .handled
        }
        // ⌘L 재누름 → TextField로 복귀 + 전체 선택 (한글 IME 정규화 포함)
        .onKeyPress { press in
            let qwerty = KoreanShortcutNormalizer.qwertyCharacter(for: press)
            if qwerty == "l", press.modifiers.contains(.command) {
                state.focusTextField()
                state.addressFocusToken &+= 1
                return .handled
            }
            return .ignored
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color(white: 0.55))
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func row(url: URL, index: Int) -> some View {
        let highlighted = state.addressListFocusIndex == index
        return HStack(spacing: 0) {
            Text(url.path)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Group {
                if highlighted {
                    RoundedRectangle(cornerRadius: ListAccentHighlight.cornerRadius, style: .continuous)
                        .fill(ListAccentHighlight.fill)
                } else {
                    Color.clear
                }
            }
        )
        .foregroundStyle(highlighted ? Color.white.opacity(0.94) : Color(white: 0.92))
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: AddressPopoverRowGlobalFramesPreferenceKey.self,
                    value: [index: geo.frame(in: .global)]
                )
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering { state.addressListFocusIndex = index }
        }
        .onTapGesture {
            Task {
                await state.navigate(to: url, via: fs)
                onClose()
            }
        }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).address.row.\(index)")
    }

    private func syncKeyboardFocus(to listIndex: Int?) {
        let shouldFocusList = listIndex != nil
        fieldFocused = !shouldFocusList
        listFocused = shouldFocusList
        if !shouldFocusList { selectAllInFocusedField() }
    }

    private func scrollAddressListFocusedRowIfNeeded(proxy: ScrollViewProxy, oldIndex: Int?, newIndex: Int?) {
        guard let idx = newIndex, state.addressListFlat.indices.contains(idx) else { return }
        Task { @MainActor in
            await Task.yield()
            revealAddressListRowIfVerticallyClipped(
                proxy: proxy,
                focusedIndex: idx,
                oldFocusIndex: oldIndex
            )
        }
    }

    private func revealAddressListRowIfVerticallyClipped(
        proxy: ScrollViewProxy,
        focusedIndex: Int,
        oldFocusIndex: Int?
    ) {
        let slack: CGFloat = 1
        let viewport = addressPopoverViewportGlobal
        let rowRects = addressPopoverRowFramesGlobalByIndex

        guard viewport.width > 10, viewport.height > 10 else {
            let down = prefersAddressListScrollDownReveal(oldIndex: oldFocusIndex, newIndex: focusedIndex)
            proxy.scrollTo(focusedIndex, anchor: down ? .bottom : .top)
            return
        }

        if let rowRect = rowRects[focusedIndex], rowRect.height >= 8 {
            if rowRect.minY >= viewport.minY - slack, rowRect.maxY <= viewport.maxY + slack {
                return
            }
            if rowRect.minY < viewport.minY - slack {
                proxy.scrollTo(focusedIndex, anchor: .top)
                return
            }
            if rowRect.maxY > viewport.maxY + slack {
                proxy.scrollTo(focusedIndex, anchor: .bottom)
                return
            }
            return
        }

        let down = prefersAddressListScrollDownReveal(oldIndex: oldFocusIndex, newIndex: focusedIndex)
        proxy.scrollTo(focusedIndex, anchor: down ? .bottom : .top)
    }

    private func prefersAddressListScrollDownReveal(oldIndex: Int?, newIndex: Int) -> Bool {
        guard let old = oldIndex, old != newIndex else { return true }
        return newIndex > old
    }
}
