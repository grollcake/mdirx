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

struct AddressBarView: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    let pathHistory: PathHistoryStore
    let onNavigate: @MainActor () async -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                TextField("", text: $state.addressDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.92))
                    .focused($fieldFocused)
                    .onSubmit { Task { await onNavigate() } }
                    .onAppear { fieldFocused = true }
                    .onChange(of: state.addressFocusToken) { _, _ in
                        fieldFocused = true
                    }

                PathHistoryMenuButton(pane: state.slot, pathHistory: pathHistory) { url in
                    Task {
                        await state.navigate(to: url, via: fs)
                        state.cancelAddressEditing()
                    }
                }
            }
            if let err = state.addressError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
