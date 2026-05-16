import XCTest

final class LaunchTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    func testLaunchShowsWindow() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertGreaterThanOrEqual(app.windows.count, 1)
    }
}
