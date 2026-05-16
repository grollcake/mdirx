import XCTest

/// UI regression: 9-column Nexus-style file list look & feel.
final class NexusLookExactTests: XCTestCase {
    private var app: XCUIApplication!
    private var tmp: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("Applications"), withIntermediateDirectories: true, attributes: nil)
        try Data([1, 2, 3]).write(to: tmp.appendingPathComponent("readme.md"))

        app = XCUIApplication()
        app.launchEnvironment["MDIRX_INITIAL_LEFT_URL"] = tmp.path
        app.launchEnvironment["MDIRX_INITIAL_RIGHT_URL"] = tmp.path
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        try? FileManager.default.removeItem(at: tmp)
        tmp = nil
        try super.tearDownWithError()
    }

    // MARK: - Column headers

    func testColumnHeadersVisible() {
        let headers = ["#", "Name", "Ext", "Size", "Date", "Time", "Attrs", "Description"]
        for label in headers {
            XCTAssert(
                app.staticTexts[label].waitForExistence(timeout: 5),
                "Header '\(label)' not found"
            )
        }
    }

    // MARK: - Full name display (no left truncation)

    func testFolderNameFullyVisible() {
        let cell = app.staticTexts["Applications"]
        XCTAssert(cell.waitForExistence(timeout: 5), "Full name 'Applications' not found — name may be truncated")
    }

    // MARK: - Time format (24h, no AM/PM)

    func testTimeIsIn24hFormat() {
        // Any Time cell should match HH:mm (two digits colon two digits) with no AM/PM text
        let timeRegex = try! NSRegularExpression(pattern: #"^[0-2]\d:[0-5]\d$"#)
        let allTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        let amPmFound = allTexts.contains { $0.contains("오전") || $0.contains("오후") || $0.contains("AM") || $0.contains("PM") }
        XCTAssertFalse(amPmFound, "AM/PM text found — time should be 24h HH:mm")
        let hasValidTime = allTexts.contains { label in
            let range = NSRange(label.startIndex..., in: label)
            return timeRegex.firstMatch(in: label, range: range) != nil
        }
        XCTAssertTrue(hasValidTime, "No HH:mm-format time found in UI")
    }

    // MARK: - Volume description shows "남음"

    func testVolumeDescriptionShowsNamEum() {
        // Volume rows have a "남음" label in the Description column.
        // At minimum the breadcrumb volume badge shows this even if no volumes are in tmp.
        let namEumExists = app.staticTexts.allElementsBoundByIndex
            .contains { $0.label.hasSuffix("남음") }
        XCTAssertTrue(namEumExists, "No '남음' label found — volume description may not be rendering")
    }
}

private func FileManager_createDirectory(at url: URL, isDirectory: Bool, attributes: [FileAttributeKey: Any]?) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
}
