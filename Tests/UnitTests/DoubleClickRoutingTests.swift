import Foundation
import Testing
@testable import MdirX

@Test
@MainActor
func inspectPrimaryDoubleClickNoSelectionWhenNothingSelected() {
    #expect(
        PaneState.inspectPrimaryMouseDoubleClick(cursorID: nil, entries: []) == .noSelection
    )
}

@Test
@MainActor
func inspectPrimaryDoubleClickAscendsOnParentLink() {
    let base = URL(fileURLWithPath: "/tmp/parent/sub", isDirectory: true).standardizedFileURL
    let parentURL = base.deletingLastPathComponent().standardizedFileURL
    let parentEntry = DirectoryEntry(
        id: parentURL,
        url: parentURL,
        displayName: "..",
        ext: "",
        isDirectory: true,
        isSymlink: false,
        size: 0,
        modificationDate: .distantPast,
        isWritable: true,
        isSystemImmutable: false,
        isHiddenFlag: false,
        kindDescription: "Parent directory",
        isParentLink: true,
        isMountedVolume: false
    )

    let fileURL = base.appendingPathComponent("doc.txt").standardizedFileURL
    let fileEntry = DirectoryEntry(
        id: fileURL,
        url: fileURL,
        displayName: "doc",
        ext: "txt",
        isDirectory: false,
        isSymlink: false,
        size: 1,
        modificationDate: .distantPast,
        isWritable: true,
        isSystemImmutable: false,
        isHiddenFlag: false,
        kindDescription: "Text",
        isParentLink: false,
        isMountedVolume: false
    )

    let entries = [parentEntry, fileEntry]

    let action = PaneState.inspectPrimaryMouseDoubleClick(cursorID: parentEntry.id, entries: entries)
    #expect(action == .ascend)
}

@Test
@MainActor
func inspectPrimaryDoubleClickNavigatesMountedVolume() {
    let volumeURL = URL(fileURLWithPath: "/Volumes/Example", isDirectory: true).standardizedFileURL
    let volume = DirectoryEntry(
        id: volumeURL,
        url: volumeURL,
        displayName: "Example",
        ext: "",
        isDirectory: true,
        isSymlink: false,
        size: 0,
        modificationDate: .distantPast,
        isWritable: false,
        isSystemImmutable: false,
        isHiddenFlag: false,
        kindDescription: "Volume",
        isParentLink: false,
        isMountedVolume: true
    )
    let action = PaneState.inspectPrimaryMouseDoubleClick(cursorID: volume.id, entries: [volume])
    #expect(action == .navigateMountedVolume(volumeURL))
}

@Test
@MainActor
func inspectPrimaryDoubleClickEntersOrdinaryFolder() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

    let inner = base.appendingPathComponent("inner", isDirectory: true)
    try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)

    let fs = FileSystemActor()
    let list = try await fs.listDirectory(at: base, includeHidden: false)
    let folder = try #require(list.first(where: { $0.displayName == "inner" && !$0.isParentLink }))

    let action = PaneState.inspectPrimaryMouseDoubleClick(cursorID: folder.id, entries: list)
    #expect(action == .enterDirectory)

    try? FileManager.default.removeItem(at: base)
}

@Test
@MainActor
func inspectPrimaryDoubleClickOpensPlainFile() {
    let url = URL(fileURLWithPath: "/tmp/readme.pdf")
    let fileEntry = DirectoryEntry(
        id: url,
        url: url,
        displayName: "readme",
        ext: "pdf",
        isDirectory: false,
        isSymlink: false,
        size: 12,
        modificationDate: .distantPast,
        isWritable: true,
        isSystemImmutable: false,
        isHiddenFlag: false,
        kindDescription: "PDF",
        isParentLink: false,
        isMountedVolume: false
    )
    let action = PaneState.inspectPrimaryMouseDoubleClick(cursorID: url, entries: [fileEntry])
    #expect(action == .openFile(url))
}

@Test
@MainActor
func handleDoubleClickInvokesInjectedOpenerForFile() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    let fileURL = base.appendingPathComponent("opened.txt").standardizedFileURL
    try Data([1]).write(to: fileURL)

    let pane = PaneState(slot: .left, initialURL: base.standardizedFileURL)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    let target = pane.entries.first(where: { !$0.isParentLink && !$0.isDirectory })
    guard let target else {
        Issue.record("missing file row after load")
        return
    }
    pane.cursorID = target.id

    var captured: URL?
    await pane.handleDoubleClick(via: fs, openFile: {
        captured = $0.standardizedFileURL
        return true
    })

    try #require(captured != nil)
    #expect(captured!.standardizedFileURL == target.url.standardizedFileURL)

    try? FileManager.default.removeItem(at: base)
}