import Foundation
import Testing
@testable import MdirX

@MainActor
private func makePopulatedPane() async throws -> (PaneState, URL, [DirectoryEntry]) {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    for name in ["alpha", "bravo", "charlie", "delta"] {
        try FileManager.default.createDirectory(at: base.appendingPathComponent(name, isDirectory: true), withIntermediateDirectories: true)
    }
    for name in ["file1.txt", "file2.txt"] {
        FileManager.default.createFile(atPath: base.appendingPathComponent(name).path, contents: nil)
    }
    let pane = PaneState(slot: .left, initialURL: base)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    return (pane, base, pane.selectableEntries)
}

@Test
@MainActor
func selectionStartsEmptyAndCursorOnFirstSelectable() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    #expect(pane.selection.isEmpty)
    #expect(pane.cursorID == selectable.first?.id)
}

@Test
@MainActor
func spacePressTogglesAndAdvances() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let first = try #require(selectable.first)
    pane.spacePress()
    #expect(pane.selection.contains(first.id))
    #expect(pane.cursorID == selectable[1].id)
}

@Test
@MainActor
func spacePressTwiceOnSameItemRemovesIt() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let first = try #require(selectable.first)
    pane.spacePress() // toggles 1st on, cursor → 2nd
    pane.cursorID = first.id
    pane.spacePress() // toggles 1st off, cursor → 2nd
    #expect(!pane.selection.contains(first.id))
}

@Test
@MainActor
func shiftUpPressTogglesAndMovesUp() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    pane.cursorID = selectable[2].id
    pane.shiftUpPress()
    #expect(pane.selection.contains(selectable[2].id))
    #expect(pane.cursorID == selectable[1].id)
}

@Test
@MainActor
func selectAllToggle3Stages() async throws {
    let (pane, base, _) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }

    // Stage 1: files only (no folders)
    pane.selectAllToggle()
    #expect(pane.selection == Set(pane.fileOnlyIDs))
    #expect(!pane.selection.isEmpty)
    for id in pane.selection {
        let entry = pane.entries.first { $0.id == id }
        #expect(entry?.isDirectory == false)
    }

    // Stage 2: files + folders
    pane.selectAllToggle()
    #expect(pane.selection == Set(pane.selectableIDs))
    #expect(pane.selection.count > pane.fileOnlyIDs.count)

    // Stage 3: clear
    pane.selectAllToggle()
    #expect(pane.selection.isEmpty)

    // Cycle back to Stage 1
    pane.selectAllToggle()
    #expect(pane.selection == Set(pane.fileOnlyIDs))
}

@Test
@MainActor
func clearSelectionKeepsCursor() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let saved = try #require(selectable.first?.id)
    pane.cursorID = saved
    pane.selection.insert(saved)
    pane.clearSelection()
    #expect(pane.selection.isEmpty)
    #expect(pane.cursorID == saved)
}

@Test
@MainActor
func extendRangeAddsInclusiveSegment() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    pane.cursorID = selectable[0].id
    pane.extendRange(to: selectable[2].id)
    #expect(pane.selection.contains(selectable[0].id))
    #expect(pane.selection.contains(selectable[1].id))
    #expect(pane.selection.contains(selectable[2].id))
    #expect(pane.cursorID == selectable[2].id)
}

@Test
@MainActor
func toggleSingleMovesCursorAndToggles() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let target = selectable[1].id
    pane.toggleSingle(at: target)
    #expect(pane.selection.contains(target))
    #expect(pane.cursorID == target)
    pane.toggleSingle(at: target)
    #expect(!pane.selection.contains(target))
}

@Test
@MainActor
func parentLinkSpacePressDoesNotToggle() async throws {
    let (pane, base, _) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let parent = try #require(pane.entries.first(where: { $0.isParentLink }))
    pane.cursorID = parent.id
    pane.spacePress()
    #expect(!pane.selection.contains(parent.id))
}

@Test
@MainActor
func ascendClearsSelection() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    pane.selection.insert(selectable[0].id)
    let fs = FileSystemActor()
    await pane.ascend(via: fs)
    #expect(pane.selection.isEmpty)
}

@Test
@MainActor
func reloadDropsMissingSelections() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let victim = try #require(selectable.last)
    pane.selection = Set(selectable.map(\.id))
    try FileManager.default.removeItem(at: victim.url)
    let fs = FileSystemActor()
    await pane.load(via: fs)
    #expect(!pane.selection.contains(victim.id))
}

@Test
@MainActor
func operationItemURLsUseSelectionWhenPresent() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }

    pane.cursorID = selectable[0].id
    pane.selection = Set([selectable[1].id, selectable[2].id])

    #expect(pane.operationItemURLs() == [selectable[1].url, selectable[2].url])
}

@Test
@MainActor
func operationItemURLsFallbackToCursorWhenSelectionIsEmpty() async throws {
    let (pane, base, selectable) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }

    pane.cursorID = selectable[1].id
    pane.selection = []

    #expect(pane.operationItemURLs() == [selectable[1].url])
}

@Test
@MainActor
func operationItemURLsIgnoreParentLinkCursor() async throws {
    let (pane, base, _) = try await makePopulatedPane()
    defer { try? FileManager.default.removeItem(at: base) }
    let parent = try #require(pane.entries.first(where: { $0.isParentLink }))

    pane.cursorID = parent.id
    pane.selection = []

    #expect(pane.operationItemURLs().isEmpty)
}
