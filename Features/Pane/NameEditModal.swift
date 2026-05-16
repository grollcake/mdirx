import SwiftUI

struct NameEditModal: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    @FocusState private var focused: Bool

    private var title: String {
        switch state.editing {
        case .rename:    return "이름 변경"
        case .newFolder: return "새 폴더"
        case .newFile:   return "빈 파일 만들기"
        case .none:      return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))

            TextField("", text: $state.editingDraft)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .focused($focused)
                .onSubmit { Task { await state.commit(via: fs) } }
                .onChange(of: state.editingDraft) { _, _ in state.validateDraft() }
                .accessibilityIdentifier("pane.\(state.slot.rawValue).edit.field")

            Text(state.editingError ?? " ")
                .foregroundStyle(.red)
                .font(.system(size: 12))

            HStack {
                Spacer()
                Button("취소") { state.cancelEditing() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .accessibilityIdentifier("pane.\(state.slot.rawValue).edit.cancel")
                Button("확인") { Task { await state.commit(via: fs) } }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(state.editingError != nil || state.editingDraft.isEmpty)
                    .accessibilityIdentifier("pane.\(state.slot.rawValue).edit.confirm")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(width: 320)
        .interactiveDismissDisabled(true)
        .task {
            focused = true
        }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).edit.modal")
    }
}
