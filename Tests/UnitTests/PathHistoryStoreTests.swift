import Foundation
import SwiftData
import Testing
@testable import MdirX

@Test
@MainActor
func pathHistoryRecordMergesSamePath() throws {
    let container = try PersistenceBootstrap.makeEmptyContainer()
    let ctx = ModelContext(container)
    let store = PathHistoryStore(modelContext: ctx)
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    try store.recordVisit(to: url, pane: .left)
    try store.recordVisit(to: url, pane: .left)
    let fetch = FetchDescriptor<PathHistoryEntry>()
    let rows = try ctx.fetch(fetch)
    #expect(rows.count == 1)
    #expect(rows[0].visitCount == 2)
    #expect(rows[0].paneSlotRaw == PaneSlot.left.rawValue)
}

@Test
@MainActor
func pathHistoryPrunesPerPane() throws {
    let container = try PersistenceBootstrap.makeEmptyContainer()
    let ctx = ModelContext(container)
    let store = PathHistoryStore(modelContext: ctx)
    let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdirx-path-hist-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    var urls: [URL] = []
    for i in 0..<22 {
        let u = base.appendingPathComponent("d\(i)", isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        urls.append(u)
    }
    for u in urls {
        try store.recordVisit(to: u, pane: .right)
    }
    let slot = PaneSlot.right.rawValue
    let fetch = FetchDescriptor<PathHistoryEntry>(
        predicate: #Predicate { $0.paneSlotRaw == slot }
    )
    let rows = try ctx.fetch(fetch)
    #expect(rows.count == 20)
}

@Test
@MainActor
func pathHistoryMenuSplitsFrequentAndRecent() throws {
    let container = try PersistenceBootstrap.makeEmptyContainer()
    let ctx = ModelContext(container)
    let store = PathHistoryStore(modelContext: ctx)
    let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdirx-split-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: base) }

    let hot = base.appendingPathComponent("hot", isDirectory: true)
    let warm = base.appendingPathComponent("warm", isDirectory: true)
    try FileManager.default.createDirectory(at: hot, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: warm, withIntermediateDirectories: true)

    for _ in 0..<10 { try store.recordVisit(to: hot, pane: .left) }
    try store.recordVisit(to: warm, pane: .left)

    for i in 0..<4 {
        let d = base.appendingPathComponent("mid\(i)", isDirectory: true)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        for _ in 0..<2 { try store.recordVisit(to: d, pane: .left) }
    }

    let (freq, recent) = try store.menuURLs(for: .left)
    let freqPaths = Set(freq.map { $0.standardizedFileURL.path })
    let recentPaths = Set(recent.map { $0.standardizedFileURL.path })
    #expect(freqPaths.contains(hot.standardizedFileURL.path))
    #expect(recentPaths.contains(warm.standardizedFileURL.path))
    #expect(!recentPaths.contains(hot.standardizedFileURL.path))
}

@Test
func addressValidationRejectsRelativePath() {
    let r = AddressPathValidator.expandAndNormalize("foo/bar")
    guard case .failure(let err) = r else {
        Issue.record("expected failure")
        return
    }
    #expect(err == .notAbsolutePath)
}

@Test
func addressValidationExpandsTilde() {
    let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
    switch AddressPathValidator.expandAndNormalize("~") {
    case .success(let url):
        #expect(url.standardizedFileURL.path == home)
    case .failure:
        Issue.record("expected success for ~")
    }
}
