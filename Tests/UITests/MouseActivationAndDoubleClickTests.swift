import XCTest

final class MouseActivationAndDoubleClickTests: XCTestCase {
    private var tmp: URL!
    private var openLog: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("aaa", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("bbb", isDirectory: true), withIntermediateDirectories: true)
        try Data([2]).write(to: tmp.appendingPathComponent("bbb/nested.txt"))
        try Data([3]).write(to: tmp.appendingPathComponent("openme.txt"))
        openLog = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-open.log")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: openLog)
        tmp = nil
        openLog = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testBlankAreaActivationAndFolderDoubleClick() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launchEnvironment["MDIRX_TEST_OPEN_LOG"] = openLog.path
        app.launch()

        let leftPane = app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch
        let rightPane = app.descendants(matching: .any).matching(identifier: "pane.right").firstMatch
        XCTAssertTrue(leftPane.waitForExistence(timeout: 8))
        XCTAssertTrue(rightPane.waitForExistence(timeout: 2))

        XCTAssertTrue(leftPane.isSelected)
        app.windows.firstMatch.click()

        let rowBBB = app.descendants(matching: .any).matching(identifier: "pane.left.row.bbb").firstMatch
        XCTAssertTrue(rowBBB.waitForExistence(timeout: 4))

        rightPane.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)).tap()
        XCTAssertTrue(rightPane.waitForExistence(timeout: 2))
        XCTAssertTrue(rightPane.isSelected)
        XCTAssertEqual(rowValue("pane.left.row.aaa", in: app), "inactive-selected")
        XCTAssertEqual(rowValue("pane.right.row.aaa", in: app), "active-selected")

        let rowAAA = app.descendants(matching: .any).matching(identifier: "pane.left.row.aaa").firstMatch
        rowAAA.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        XCTAssertTrue(leftPane.isSelected)
        XCTAssertEqual(rowValue("pane.left.row.aaa", in: app), "active-selected")
        XCTAssertEqual(rowValue("pane.right.row.aaa", in: app), "inactive-selected")

        rowBBB.doubleClick()

        let nestedRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.nested.txt").firstMatch
        XCTAssertTrue(nestedRow.waitForExistence(timeout: 8))
    }

    @MainActor
    func testInactivePaneRowDoubleClickEntersThatPane() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launchEnvironment["MDIRX_TEST_OPEN_LOG"] = openLog.path
        app.launch()

        let leftPane = app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch
        let rightPane = app.descendants(matching: .any).matching(identifier: "pane.right").firstMatch
        XCTAssertTrue(leftPane.waitForExistence(timeout: 8))
        XCTAssertTrue(rightPane.waitForExistence(timeout: 2))
        XCTAssertTrue(leftPane.isSelected)

        let rightBBB = app.descendants(matching: .any).matching(identifier: "pane.right.row.bbb").firstMatch
        XCTAssertTrue(rightBBB.waitForExistence(timeout: 4))

        rightBBB.doubleClick()

        XCTAssertTrue(rightPane.isSelected)
        let nestedRow = app.descendants(matching: .any).matching(identifier: "pane.right.row.nested.txt").firstMatch
        XCTAssertTrue(nestedRow.waitForExistence(timeout: 8))
    }

    @MainActor
    func testFileDoubleClickUsesOpenHook() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launchEnvironment["MDIRX_TEST_OPEN_LOG"] = openLog.path
        app.launch()

        let fileRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.openme.txt").firstMatch
        XCTAssertTrue(fileRow.waitForExistence(timeout: 8))

        fileRow.doubleClick()

        let expected = tmp.appendingPathComponent("openme.txt").standardizedFileURL.path
        let opened = expectation(description: "file open hook writes selected file")
        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline {
            if let text = try? String(contentsOf: openLog, encoding: .utf8), text.contains(expected) {
                opened.fulfill()
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        wait(for: [opened], timeout: 0.1)
    }

    @MainActor
    private func rowValue(_ identifier: String, in app: XCUIApplication) -> String? {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch.value as? String
    }
}
