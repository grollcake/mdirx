import Foundation
import Testing
@testable import MdirX

@Test
@MainActor
func paneLoadSelectsFirstSelectableNotParentLink() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    try FileManager.default.createDirectory(at: base.appendingPathComponent("inner", isDirectory: true), withIntermediateDirectories: true)

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    #expect(pane.entries.first?.isParentLink == true)
    #expect(pane.cursorID != pane.entries.first?.id)
    let inner = pane.entries.first(where: { $0.displayName == "inner" })
    #expect(pane.cursorID == inner?.id)
}

@Test
@MainActor
func paneLoadSelectsParentWhenOnlyDotDot() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)

    #expect(pane.entries.count == 1)
    #expect(pane.entries.first?.isParentLink == true)
    #expect(pane.cursorID == pane.entries.first?.id)
}
