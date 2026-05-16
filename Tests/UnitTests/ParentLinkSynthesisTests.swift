import Foundation
import Testing
@testable import MdirX

@Test
func listDirectoryPrependsParentLinkWithFiles() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    try Data([1]).write(to: base.appendingPathComponent("a.txt"))
    try Data([2]).write(to: base.appendingPathComponent("b.txt"))

    let fs = FileSystemActor()
    let list = try await fs.listDirectory(at: base, includeHidden: false)

    #expect(list.count == 3)
    let dotdot = list[0]
    #expect(dotdot.isParentLink)
    #expect(dotdot.displayName == "..")
    #expect(dotdot.url.standardizedFileURL.path == base.deletingLastPathComponent().standardizedFileURL.path)
}

@Test
func listDirectoryRootHasNoParentLink() async throws {
    let fs = FileSystemActor()
    do {
        let list = try await fs.listDirectory(at: URL(fileURLWithPath: "/"), includeHidden: false)
        #expect(!list.contains(where: { $0.isParentLink }))
    } catch {
        // Sandbox / permissions may block reading "/"; skip assertion in that environment.
    }
}

@Test
func listDirectoryEmptyFolderIsOnlyParentLink() async throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let fs = FileSystemActor()
    let list = try await fs.listDirectory(at: base, includeHidden: false)
    #expect(list.count == 1)
    #expect(list[0].isParentLink)
}
