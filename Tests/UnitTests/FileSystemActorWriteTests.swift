import Foundation
import Testing
@testable import MdirX

@Test
func createDirectoryCreatesAndReturnsURL() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let fs = FileSystemActor()
    let result = try await fs.createDirectory(at: tmp, name: "alpha")
    #expect(result.lastPathComponent == "alpha")
    var isDir: ObjCBool = false
    #expect(FileManager.default.fileExists(atPath: result.path, isDirectory: &isDir))
    #expect(isDir.boolValue)
}

@Test
func createDirectoryDuplicateThrows() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let fs = FileSystemActor()
    _ = try await fs.createDirectory(at: tmp, name: "alpha")
    await #expect(throws: (any Error).self) {
        try await fs.createDirectory(at: tmp, name: "alpha")
    }
}

@Test
func createEmptyFileCreatesZeroByteFile() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let fs = FileSystemActor()
    let result = try await fs.createEmptyFile(at: tmp, name: "note.md")
    #expect(result.lastPathComponent == "note.md")
    let attrs = try FileManager.default.attributesOfItem(atPath: result.path)
    let size = attrs[.size] as? Int ?? -1
    #expect(size == 0)
}

@Test
func renameMovesFileAndReturnsNewURL() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let oldURL = tmp.appendingPathComponent("old.txt")
    FileManager.default.createFile(atPath: oldURL.path, contents: nil)

    let fs = FileSystemActor()
    let newURL = try await fs.rename(at: oldURL, to: "new.txt")
    #expect(newURL.lastPathComponent == "new.txt")
    #expect(FileManager.default.fileExists(atPath: newURL.path))
    #expect(!FileManager.default.fileExists(atPath: oldURL.path))
}

@Test
func copyItemsCopiesFileAndDirectoryWithoutRemovingSources() async throws {
    let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: source)
        try? FileManager.default.removeItem(at: destination)
    }

    let file = source.appendingPathComponent("note.txt")
    try "hello".write(to: file, atomically: true, encoding: .utf8)
    let folder = source.appendingPathComponent("docs", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    try "nested".write(to: folder.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)

    let fs = FileSystemActor()
    let copied = try await fs.copyItems([file, folder], to: destination)

    #expect(Set(copied.map(\.lastPathComponent)) == Set(["note.txt", "docs"]))
    #expect(FileManager.default.fileExists(atPath: file.path))
    #expect(FileManager.default.fileExists(atPath: folder.path))
    #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("note.txt").path))
    #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("docs/readme.md").path))
}

@Test
func moveItemsMovesFileAndRemovesSource() async throws {
    let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: source)
        try? FileManager.default.removeItem(at: destination)
    }

    let file = source.appendingPathComponent("move.txt")
    FileManager.default.createFile(atPath: file.path, contents: Data("x".utf8))

    let fs = FileSystemActor()
    let moved = try await fs.moveItems([file], to: destination)

    #expect(moved == [destination.appendingPathComponent("move.txt")])
    #expect(!FileManager.default.fileExists(atPath: file.path))
    #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("move.txt").path))
}

@Test
func copyItemsDoesNotOverwriteExistingDestination() async throws {
    let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: source)
        try? FileManager.default.removeItem(at: destination)
    }

    let file = source.appendingPathComponent("same.txt")
    try "source".write(to: file, atomically: true, encoding: .utf8)
    try "destination".write(to: destination.appendingPathComponent("same.txt"), atomically: true, encoding: .utf8)

    let fs = FileSystemActor()
    await #expect(throws: (any Error).self) {
        try await fs.copyItems([file], to: destination)
    }
    let kept = try String(contentsOf: destination.appendingPathComponent("same.txt"), encoding: .utf8)
    #expect(kept == "destination")
}
