import SwiftUI

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
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(white: 0.65))
                .frame(width: 22, height: 22)
        }
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

    @FocusState private var fieldFocused: Bool

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
                .onAppear { fieldFocused = (state.addressListFocusIndex == nil) }
                .onChange(of: state.addressListFocusIndex) { _, new in
                    fieldFocused = (new == nil)
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !state.addressListItems.frequent.isEmpty {
                            sectionHeader("자주 방문")
                            ForEach(Array(state.addressListItems.frequent.enumerated()), id: \.element.path) { offset, url in
                                row(url: url, index: offset)
                            }
                        }
                        if !state.addressListItems.recent.isEmpty {
                            sectionHeader("최근 방문")
                            ForEach(Array(state.addressListItems.recent.enumerated()), id: \.element.path) { offset, url in
                                let globalIndex = state.addressListItems.frequent.count + offset
                                row(url: url, index: globalIndex)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(8)
        .frame(width: 360)
        .background(FileColorToken.panelBackground)
        .onKeyPress(.escape) {
            onClose()
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
                .foregroundStyle(Color(white: 0.92))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(highlighted ? Color.accentColor.opacity(0.35) : Color.clear)
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
}
