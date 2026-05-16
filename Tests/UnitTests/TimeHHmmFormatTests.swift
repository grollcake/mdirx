import Foundation
import Testing
@testable import MdirX

@Test func timeMidnight() throws {
    let date = try makeDate(hour: 0, minute: 0)
    #expect(formatted(date) == "00:00")
}

@Test func timeNoon() throws {
    let date = try makeDate(hour: 12, minute: 0)
    #expect(formatted(date) == "12:00")
}

@Test func timeEvening() throws {
    let date = try makeDate(hour: 21, minute: 53)
    #expect(formatted(date) == "21:53")
}

@Test func timeNoAmPm() throws {
    let date = try makeDate(hour: 9, minute: 5)
    let result = formatted(date)
    #expect(!result.contains("오전"))
    #expect(!result.contains("오후"))
    #expect(!result.contains("AM"))
    #expect(!result.contains("PM"))
}

@Test func timeAlwaysTwoDigitHour() throws {
    let date = try makeDate(hour: 3, minute: 7)
    #expect(formatted(date) == "03:07")
}

// MARK: - helpers

private func makeDate(hour: Int, minute: Int) throws -> Date {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 5; comps.day = 13
    comps.hour = hour; comps.minute = minute; comps.second = 0
    let cal = Calendar(identifier: .gregorian)
    return try #require(cal.date(from: comps))
}

private func formatted(_ date: Date) -> String {
    let entry = DirectoryEntry(
        id: URL(fileURLWithPath: "/tmp/x"), url: URL(fileURLWithPath: "/tmp/x"),
        displayName: "x", ext: "", isDirectory: false, isSymlink: false, size: 0,
        modificationDate: date, isWritable: true, isSystemImmutable: false,
        isHiddenFlag: false, kindDescription: "", isParentLink: false, isMountedVolume: false
    )
    // PaneStatusBar uses its own private DateFormatter; we verify DirectoryEntry's date
    // via the static formatter in FileListView (HH:mm, en_US_POSIX).
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "HH:mm"
    return f.string(from: entry.modificationDate)
}
