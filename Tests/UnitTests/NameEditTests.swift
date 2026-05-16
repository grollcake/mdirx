import Foundation
import Testing
@testable import MdirX

// MARK: - requestNewFolder

@Test
@MainActor
func requestNewFolderSetsStateAndDraftEmpty() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.requestNewFolder()
    #expect(pane.editing == .newFolder)
    #expect(pane.editingDraft == "")
    #expect(pane.editingError == nil)

    pane.validateDraft()
    #expect(pane.editingError == nil)  // 빈 이름은 에러 없이 버튼만 비활성
}

// MARK: - validateDraft: invalid characters

@Test
@MainActor
func validateDraftSlashReturnsError() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.requestNewFolder()
    pane.editingDraft = "foo/bar"
    pane.validateDraft()
    #expect(pane.editingError == "사용할 수 없는 문자: / 또는 NUL")
}

@Test
@MainActor
func validateDraftDotDotReturnsError() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.requestNewFolder()
    pane.editingDraft = ".."
    pane.validateDraft()
    #expect(pane.editingError == "이 이름은 사용할 수 없습니다")
}

// MARK: - validateDraft: duplicate

@Test
@MainActor
func validateDraftDuplicateNameReturnsError() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    try FileManager.default.createDirectory(at: base.appendingPathComponent("alpha", isDirectory: true), withIntermediateDirectories: false)

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.requestNewFolder()
    pane.editingDraft = "alpha"
    pane.validateDraft()
    #expect(pane.editingError == "같은 이름의 항목이 이미 있습니다")
}

// MARK: - cancelEditing

@Test
@MainActor
func cancelEditingClearsAllFields() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.requestNewFile()
    pane.editingDraft = "test"
    pane.cancelEditing()

    #expect(pane.editing == nil)
    #expect(pane.editingDraft == "")
    #expect(pane.editingError == nil)
}

// MARK: - requestRename on parent link is no-op

@Test
@MainActor
func requestRenameOnParentLinkIsNoOp() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    let inner = base.appendingPathComponent("inner", isDirectory: true)
    try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: inner)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    // cursor on ".." (first entry)
    pane.cursorID = pane.entries.first(where: { $0.isParentLink })?.id
    pane.requestRename()
    #expect(pane.editing == nil)
}

// MARK: - rename self-name is not duplicate

@Test
@MainActor
func renameSelfNameIsNotDuplicate() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    FileManager.default.createFile(atPath: base.appendingPathComponent("note.md").path, contents: nil)

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    pane.cursorID = pane.entries.first(where: { $0.displayName == "note" })?.id
    pane.requestRename()
    // draft is pre-filled with "note.md"
    pane.validateDraft()
    // self-exclusion: no duplicate error
    #expect(pane.editingError == nil)
}
