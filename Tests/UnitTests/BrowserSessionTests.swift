import Foundation
import Testing
@testable import MdirX

@Test
@MainActor
func browserSessionStartsWithLeftActive() {
    let session = BrowserSession()
    #expect(session.activePane == .left)
}

@Test
@MainActor
func browserSessionToggleAlternatesActivePane() {
    let session = BrowserSession()
    session.toggleActive()
    #expect(session.activePane == .right)
    session.toggleActive()
    #expect(session.activePane == .left)
}

@Test
@MainActor
func browserSessionCopiesCursorItemToOtherPane() async throws {
    let root = try makeTwoPaneRoot()
    defer { try? FileManager.default.removeItem(at: root.base) }

    let session = BrowserSession()
    await session.left.navigate(to: root.left, via: session.fs)
    await session.right.navigate(to: root.right, via: session.fs)
    session.activePane = .left
    let sourceEntry = try #require(session.left.entries.first { $0.url.lastPathComponent == "copy-me.txt" })
    session.left.cursorID = sourceEntry.id

    await session.copySelectionToOtherPane()

    #expect(FileManager.default.fileExists(atPath: root.left.appendingPathComponent("copy-me.txt").path))
    #expect(FileManager.default.fileExists(atPath: root.right.appendingPathComponent("copy-me.txt").path))
    #expect(session.right.entries.contains { $0.url.lastPathComponent == "copy-me.txt" })
}

@Test
@MainActor
func browserSessionMovesSelectedItemsToOtherPane() async throws {
    let root = try makeTwoPaneRoot()
    defer { try? FileManager.default.removeItem(at: root.base) }
    let secondFile = root.left.appendingPathComponent("second.txt")
    FileManager.default.createFile(atPath: secondFile.path, contents: Data("2".utf8))

    let session = BrowserSession()
    await session.left.navigate(to: root.left, via: session.fs)
    await session.right.navigate(to: root.right, via: session.fs)
    session.activePane = .left
    let sourceEntries = session.left.entries.filter {
        $0.url.lastPathComponent == "copy-me.txt" || $0.url.lastPathComponent == "second.txt"
    }
    #expect(sourceEntries.count == 2)
    session.left.selection = Set(sourceEntries.map(\.id))

    await session.moveSelectionToOtherPane()

    #expect(!FileManager.default.fileExists(atPath: root.sourceFile.path))
    #expect(!FileManager.default.fileExists(atPath: secondFile.path))
    #expect(FileManager.default.fileExists(atPath: root.right.appendingPathComponent("copy-me.txt").path))
    #expect(FileManager.default.fileExists(atPath: root.right.appendingPathComponent("second.txt").path))
    #expect(session.left.selection.isEmpty)
}

private func makeTwoPaneRoot() throws -> (base: URL, left: URL, right: URL, sourceFile: URL) {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let left = base.appendingPathComponent("left", isDirectory: true)
    let right = base.appendingPathComponent("right", isDirectory: true)
    try FileManager.default.createDirectory(at: left, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: right, withIntermediateDirectories: true)
    let sourceFile = left.appendingPathComponent("copy-me.txt")
    FileManager.default.createFile(atPath: sourceFile.path, contents: Data("1".utf8))
    return (base, left, right, sourceFile)
}
