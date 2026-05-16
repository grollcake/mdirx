import Foundation
import UniformTypeIdentifiers

struct DirectoryEntry: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let displayName: String
    let ext: String
    let isDirectory: Bool
    let isSymlink: Bool
    let size: Int64
    let modificationDate: Date
    let isWritable: Bool
    let isSystemImmutable: Bool
    let isHiddenFlag: Bool
    let kindDescription: String
    let isParentLink: Bool
    let isMountedVolume: Bool

    var attrsFourCharacter: String {
        if isParentLink { return "____" }
        var s = ""
        s += isDirectory ? "_" : "A"
        s += isWritable ? "_" : "R"
        s += isHiddenFlag ? "H" : "_"
        s += isSystemImmutable ? "S" : "_"
        return s
    }

    func relativeOrCalendarDate(reference: Date = .now, calendar: Calendar = .current) -> String {
        let startDay = calendar.startOfDay(for: modificationDate)
        let refDay = calendar.startOfDay(for: reference)
        let days = calendar.dateComponents([.day], from: startDay, to: refDay).day ?? 999
        if days >= 0, days <= 7 {
            if days == 0 { return "0일 전" }
            return "\(days)일 전"
        }
        let f = DateFormatter()
        f.calendar = calendar
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: modificationDate)
    }

    static func makeKindDescription(isDirectory: Bool, ext: String, contentType: UTType?) -> String {
        if isDirectory {
            return contentType?.localizedDescription
                ?? UTType.folder.localizedDescription
                ?? "Folder"
        }
        if let contentType {
            return contentType.localizedDescription ?? ext.uppercased()
        }
        if ext.isEmpty { return "Document" }
        return ext.uppercased()
    }

    static var parentLinkKindKey: String { "parent.directory" }
}
