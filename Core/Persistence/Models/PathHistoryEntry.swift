import Foundation
import SwiftData

@Model
final class PathHistoryEntry {
    var path: String
    var visitedAt: Date
    var visitCount: Int
    var paneSlotRaw: String

    init(path: String, visitedAt: Date, visitCount: Int, paneSlotRaw: String) {
        self.path = path
        self.visitedAt = visitedAt
        self.visitCount = visitCount
        self.paneSlotRaw = paneSlotRaw
    }
}
