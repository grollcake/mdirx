import Foundation
import Testing
@testable import MdirX

@Test
@MainActor
func paneEnterMovesIntoDirectory() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let inner = base.appendingPathComponent("inner", isDirectory: true)
    try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)
    try Data([1]).write(to: base.appendingPathComponent("z.txt"))

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    #expect(pane.cursorID == pane.entries.first(where: { $0.displayName == "inner" })?.id)

    await pane.enter(via: fs)
    #expect(pane.currentURL.standardizedFileURL.path == inner.standardizedFileURL.path)
}

@Test
@MainActor
func paneAscendGoesToParent() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let inner = base.appendingPathComponent("inner", isDirectory: true)
    try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)

    let pane = PaneState(slot: .left, initialURL: inner)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    await pane.ascend(via: fs)
    #expect(pane.currentURL.standardizedFileURL.path == base.standardizedFileURL.path)
}

@Test
@MainActor
func paneAscendAtRootIsNoOp() async throws {
    let pane = PaneState(slot: .left, initialURL: URL(fileURLWithPath: "/"))
    let fs = FileSystemActor()
    let before = pane.currentURL.path
    await pane.ascend(via: fs)
    #expect(pane.currentURL.path == before)
}

@Test
@MainActor
func paneToggleHiddenReloads() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    try Data([1]).write(to: base.appendingPathComponent("vis.txt"))
    try Data([2]).write(to: base.appendingPathComponent(".hid"))

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    #expect(pane.entries.count == 2)
    #expect(pane.hiddenVisible == false)

    await pane.toggleHidden(via: fs)
    #expect(pane.hiddenVisible == true)
    #expect(pane.entries.count == 3)
}
