import Foundation
import Testing
@testable import MdirX

@Test
func listDirectorySkipsHiddenByDefaultAndSorts() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let subdir = base.appendingPathComponent("dir", isDirectory: true)
    try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
    try Data(repeating: 0, count: 10).write(to: base.appendingPathComponent("b.txt"))
    try Data(repeating: 0, count: 20).write(to: base.appendingPathComponent("a.txt"))
    try Data(repeating: 0, count: 1).write(to: base.appendingPathComponent(".hidden"))

    let fs = FileSystemActor()
    let hiddenOff = try await fs.listDirectory(at: base, includeHidden: false)
    #expect(hiddenOff.count == 4)
    #expect(hiddenOff[0].isParentLink && hiddenOff[0].displayName == "..")
    #expect(hiddenOff[1].isDirectory && hiddenOff[1].displayName == "dir")
    #expect(hiddenOff[2].displayName == "a")
    #expect(hiddenOff[3].displayName == "b")

    let hiddenOn = try await fs.listDirectory(at: base, includeHidden: true)
    #expect(hiddenOn.count == 5)
    #expect(hiddenOn[0].isParentLink)
    let dirs = hiddenOn.filter(\.isDirectory).filter { !$0.isParentLink }
    #expect(dirs.count == 1)
    let names = hiddenOn.filter { !$0.isParentLink }.map(\.displayName)
    #expect(names.contains(".hidden"))
}

@Test
func listDirectoryThrowsForMissingPath() async throws {
    let url = URL(fileURLWithPath: "/no-such-path-\(UUID().uuidString)")
    let fs = FileSystemActor()
    await #expect(throws: (any Error).self) {
        try await fs.listDirectory(at: url, includeHidden: false)
    }
}
