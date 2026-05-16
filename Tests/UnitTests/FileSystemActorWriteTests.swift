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
