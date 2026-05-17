import Foundation
import SwiftData

@MainActor
struct PathHistoryStore {
    private let modelContext: ModelContext
    private let maxPathsPerPane = 20
    private let frequentLimit = 5

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func recordVisit(to url: URL, pane: PaneSlot) throws {
        let standardizedPath = url.standardizedFileURL.path
        let slot = pane.rawValue
        let fetch = FetchDescriptor<PathHistoryEntry>(
            predicate: #Predicate { entry in
                entry.path == standardizedPath && entry.paneSlotRaw == slot
            }
        )
        let found = try modelContext.fetch(fetch)
        let now = Date()
        if let existing = found.first {
            existing.visitCount += 1
            existing.visitedAt = now
        } else {
            modelContext.insert(PathHistoryEntry(
                path: standardizedPath,
                visitedAt: now,
                visitCount: 1,
                paneSlotRaw: slot
            ))
        }
        try prune(for: pane)
        try modelContext.save()
    }

    private func prune(for pane: PaneSlot) throws {
        let slot = pane.rawValue
        let fetch = FetchDescriptor<PathHistoryEntry>(
            predicate: #Predicate { $0.paneSlotRaw == slot },
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(fetch)
        guard all.count > maxPathsPerPane else { return }
        for entry in all[maxPathsPerPane...] {
            modelContext.delete(entry)
        }
    }

    /// Frequent: top `frequentLimit` by `visitCount` then `visitedAt`. Recent: remaining paths by `visitedAt`, excluding frequent paths.
    func menuURLs(for pane: PaneSlot) throws -> (frequent: [URL], recent: [URL]) {
        let slot = pane.rawValue
        let fetch = FetchDescriptor<PathHistoryEntry>(
            predicate: #Predicate { $0.paneSlotRaw == slot }
        )
        let entries = try modelContext.fetch(fetch)
        let frequent = entries
            .sorted {
                if $0.visitCount != $1.visitCount { return $0.visitCount > $1.visitCount }
                return $0.visitedAt > $1.visitedAt
            }
            .prefix(frequentLimit)
        let frequentPaths = Set(frequent.map(\.path))
        let frequentURLs = frequent
            .sorted { $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending }
            .map { URL(fileURLWithPath: $0.path, isDirectory: true) }
        let recent = entries
            .filter { !frequentPaths.contains($0.path) }
            .sorted { $0.visitedAt > $1.visitedAt }
            .map { URL(fileURLWithPath: $0.path, isDirectory: true) }
        return (Array(frequentURLs), recent)
    }
}
