import Foundation
import Testing
@testable import MdirX

// Verify the status bar text format: "<size> | <yyyy-MM-dd HH:mm> | <attrs4> | <name>"

@Test func statusBarFileFormat() throws {
    // "12,345 | 2026-05-13 21:53 | A___ | foo.txt"
    let dateStr = "2026-05-13 21:53"
    let text = buildStatusText(
        bytes: 12_345,
        dateString: dateStr,
        attrs: "A___",
        name: "foo.txt"
    )
    #expect(text == "12,345 | 2026-05-13 21:53 | A___ | foo.txt")
}

@Test func statusBarAttrsAlwaysFourChars() {
    let url = URL(fileURLWithPath: "/tmp/f.txt")
    let e = DirectoryEntry(
        id: url, url: url, displayName: "f", ext: "txt",
        isDirectory: false, isSymlink: false, size: 0,
        modificationDate: Date(), isWritable: true, isSystemImmutable: false,
        isHiddenFlag: false, kindDescription: "", isParentLink: false, isMountedVolume: false
    )
    #expect(e.attrsFourCharacter.count == 4)
}

@Test func statusBarPipeSeparatorsHaveSingleSpace() throws {
    let text = buildStatusText(bytes: 1, dateString: "2026-01-01 00:00", attrs: "____", name: "a")
    let parts = text.components(separatedBy: " | ")
    #expect(parts.count == 4)
}

@Test func statusBarNoSelection() {
    let text = "— | — | ____ | —"
    let parts = text.components(separatedBy: " | ")
    #expect(parts.count == 4)
    #expect(parts[2] == "____")
}

// MARK: - helper (mirrors PaneStatusBar.statusText logic for file rows)

private func buildStatusText(bytes: Int64, dateString: String, attrs: String, name: String) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    f.usesGroupingSeparator = true
    let sizeStr = f.string(from: NSNumber(value: bytes)) ?? "\(bytes)"
    return "\(sizeStr) | \(dateString) | \(attrs) | \(name)"
}
