import XCTest

final class DualPaneTabToggleTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    func testTabTogglesActivePane() throws {
        let app = XCUIApplication()
        app.launch()

        let left = app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch
        let right = app.descendants(matching: .any).matching(identifier: "pane.right").firstMatch

        XCTAssertTrue(left.waitForExistence(timeout: 5))
        XCTAssertTrue(right.waitForExistence(timeout: 5))
        XCTAssertTrue(left.isSelected)
        XCTAssertFalse(right.isSelected)

        app.windows.firstMatch.click()
        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])

        XCTAssertTrue(right.isSelected)
        XCTAssertFalse(left.isSelected)

        app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])

        XCTAssertTrue(left.isSelected)
        XCTAssertFalse(right.isSelected)
    }
}
