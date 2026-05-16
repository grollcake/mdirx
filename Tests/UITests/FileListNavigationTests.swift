import XCTest

final class FileListNavigationTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("aaa", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("bbb", isDirectory: true), withIntermediateDirectories: true)
        try Data([2]).write(to: tmp.appendingPathComponent("bbb/nested.txt"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
        tmp = nil
        try super.tearDownWithError()
    }

    func testKeyboardNavigationAndMouseActivation() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launch()

        let leftPane = app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch
        let rightPane = app.descendants(matching: .any).matching(identifier: "pane.right").firstMatch
        XCTAssertTrue(leftPane.waitForExistence(timeout: 8))
        XCTAssertTrue(rightPane.waitForExistence(timeout: 2))

        let rowAAA = app.descendants(matching: .any).matching(identifier: "pane.left.row.aaa").firstMatch
        XCTAssertTrue(rowAAA.waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "pane.left.row.parent").firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "pane.left.row.bbb").firstMatch.waitForExistence(timeout: 2))

        app.windows.firstMatch.click()

        app.typeKey(XCUIKeyboardKey.downArrow.rawValue, modifierFlags: [])
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])

        let nestedRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.nested.txt").firstMatch
        XCTAssertTrue(nestedRow.waitForExistence(timeout: 6))

        // XCUIApplication often does not surface Command-modifier consistently to SwiftUI onKeyPress; "." ascend is the paired binding from the spec.
        app.typeText(".")
        XCTAssertTrue(rowAAA.waitForExistence(timeout: 4))

        XCTAssertTrue(leftPane.isSelected)
        rightPane.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
        XCTAssertTrue(rightPane.waitForExistence(timeout: 2))
        XCTAssertTrue(rightPane.isSelected)

        let rowBBBLeft = app.descendants(matching: .any).matching(identifier: "pane.left.row.bbb").firstMatch
        XCTAssertTrue(rowBBBLeft.waitForExistence(timeout: 2))
        rowBBBLeft.click()
        XCTAssertTrue(leftPane.isSelected)
    }
}
