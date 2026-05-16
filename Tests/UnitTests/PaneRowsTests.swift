import Foundation
import Testing
@testable import MdirX

@Test
@MainActor
func paneRowsAppendMountedVolumesAfterFiles() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    try Data([1]).write(to: base.appendingPathComponent("b.txt"))
    try Data([2]).write(to: base.appendingPathComponent("a.txt"))

    let pane = PaneState(slot: .left, initialURL: base)
    await pane.load(via: FileSystemActor())

    #expect(pane.paneRows.count == pane.entries.count + pane.mountedVolumes.count)
    #expect(pane.paneRows.map(\.rowNumber) == Array(1...pane.paneRows.count))
    #expect(pane.paneRows.prefix(pane.entries.count).map(\.id) == pane.entries.map(\.id))
}
