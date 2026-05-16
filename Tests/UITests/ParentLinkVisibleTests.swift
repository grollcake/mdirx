import XCTest

/// UI sanity: synthetic `..` row is exposed to accessibility for automation.
/// Keyboard/click + Enter on `..` is covered by `ParentLinkSynthesisTests`, `PaneCursorInitTests`, and `PaneStateTests` + `FileListNavigationTests`.
final class ParentLinkVisibleTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try Data([1]).write(to: tmp.appendingPathComponent("marker.txt"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
        tmp = nil
        try super.tearDownWithError()
    }

    func testParentLinkRowIsVisible() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launch()

        let parentRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.parent").firstMatch
        XCTAssertTrue(parentRow.waitForExistence(timeout: 8))
    }
}
