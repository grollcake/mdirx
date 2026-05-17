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

    func testF5CopiesAndF6MovesBetweenPanes() throws {
        let leftDir = tmp.appendingPathComponent("aaa", isDirectory: true)
        let rightDir = tmp.appendingPathComponent("bbb", isDirectory: true)
        try Data("copy".utf8).write(to: leftDir.appendingPathComponent("copy.txt"))
        try Data("move".utf8).write(to: leftDir.appendingPathComponent("move.txt"))

        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_INITIAL_LEFT_URL"] = leftDir.path
        app.launchEnvironment["MDIRX_INITIAL_RIGHT_URL"] = rightDir.path
        app.launch()

        let leftPane = app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch
        XCTAssertTrue(leftPane.waitForExistence(timeout: 8))
        app.windows.firstMatch.click()

        let copyRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.copy.txt").firstMatch
        XCTAssertTrue(copyRow.waitForExistence(timeout: 4))
        copyRow.click()
        app.typeKey("\u{F708}", modifierFlags: [])

        let copiedRight = app.descendants(matching: .any).matching(identifier: "pane.right.row.copy.txt").firstMatch
        XCTAssertTrue(copiedRight.waitForExistence(timeout: 4))
        XCTAssertTrue(FileManager.default.fileExists(atPath: leftDir.appendingPathComponent("copy.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rightDir.appendingPathComponent("copy.txt").path))

        let moveRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.move.txt").firstMatch
        XCTAssertTrue(moveRow.waitForExistence(timeout: 4))
        moveRow.click()
        app.typeKey("\u{F709}", modifierFlags: [])

        let movedRight = app.descendants(matching: .any).matching(identifier: "pane.right.row.move.txt").firstMatch
        XCTAssertTrue(movedRight.waitForExistence(timeout: 4))
        XCTAssertFalse(FileManager.default.fileExists(atPath: leftDir.appendingPathComponent("move.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rightDir.appendingPathComponent("move.txt").path))
    }
}
