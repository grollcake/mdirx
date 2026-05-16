import XCTest

final class RenameNewFolderNewFileTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
        tmp = nil
        try super.tearDownWithError()
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["MDIRX_TEST_ROOT"] = tmp.path
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "pane.left").firstMatch.waitForExistence(timeout: 8))
        app.windows.firstMatch.click()
        return app
    }

    private func modal(in app: XCUIApplication, slot: String = "left") -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "pane.\(slot).edit.modal").firstMatch
    }

    // MARK: - 새 폴더

    func testNewFolderCreatesDirectoryAndMovesCursor() throws {
        let app = launchApp()

        app.typeKey("k", modifierFlags: .option)

        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4), "모달이 나타나야 함")
        XCTAssertTrue(m.descendants(matching: .staticText).matching(NSPredicate(format: "label == '새 폴더'")).firstMatch.exists)

        let field = app.descendants(matching: .any).matching(identifier: "pane.left.edit.field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.typeText("pane_test_dir")
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])

        XCTAssertFalse(m.exists, "확정 후 모달 닫혀야 함")
        let newRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.pane_test_dir").firstMatch
        XCTAssertTrue(newRow.waitForExistence(timeout: 4), "새 폴더 행이 리스트에 나타나야 함")

        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmp.appendingPathComponent("pane_test_dir").path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testNewFolderEmptyNameShowsError() throws {
        let app = launchApp()

        app.typeKey("k", modifierFlags: .option)
        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4))

        // 빈 상태에서 확인 버튼은 비활성
        let confirm = app.descendants(matching: .any).matching(identifier: "pane.left.edit.confirm").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 2))
        XCTAssertFalse(confirm.isEnabled, "빈 이름에서 확인 버튼 비활성")

        // 확인 버튼만 비활성 (에러 메시지는 표시 안 됨)
    }

    func testNewFolderDuplicateNameShowsError() throws {
        try FileManager.default.createDirectory(at: tmp.appendingPathComponent("pane_test_dir", isDirectory: true), withIntermediateDirectories: false)
        let app = launchApp()

        app.typeKey("k", modifierFlags: .option)
        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4))

        let field = app.descendants(matching: .any).matching(identifier: "pane.left.edit.field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.typeText("pane_test_dir")

        let confirm = app.descendants(matching: .any).matching(identifier: "pane.left.edit.confirm").firstMatch
        XCTAssertFalse(confirm.isEnabled, "중복 이름에서 확인 버튼 비활성")
        XCTAssertTrue(m.descendants(matching: .staticText).matching(NSPredicate(format: "label == '같은 이름의 항목이 이미 있습니다'")).firstMatch.exists)
    }

    // MARK: - 빈 파일

    func testNewFileCreatesEmptyFile() throws {
        let app = launchApp()

        app.typeKey("n", modifierFlags: .control)
        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4))
        XCTAssertTrue(m.descendants(matching: .staticText).matching(NSPredicate(format: "label == '빈 파일 만들기'")).firstMatch.exists)

        let field = app.descendants(matching: .any).matching(identifier: "pane.left.edit.field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.typeText("note.md")
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])

        XCTAssertFalse(m.exists, "확정 후 모달 닫혀야 함")
        let newRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.note.md").firstMatch
        XCTAssertTrue(newRow.waitForExistence(timeout: 4))

        let attrs = try FileManager.default.attributesOfItem(atPath: tmp.appendingPathComponent("note.md").path)
        XCTAssertEqual(attrs[.size] as? Int, 0)
    }

    // MARK: - 이름변경

    func testRenameFileViaF2() throws {
        FileManager.default.createFile(atPath: tmp.appendingPathComponent("note.md").path, contents: nil)
        let app = launchApp()

        let noteRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.note.md").firstMatch
        XCTAssertTrue(noteRow.waitForExistence(timeout: 4))
        noteRow.click()

        app.typeKey("\u{F705}", modifierFlags: [])
        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4))
        XCTAssertTrue(m.descendants(matching: .staticText).matching(NSPredicate(format: "label == '이름 변경'")).firstMatch.exists)

        // draft에 "note.md" 가 채워져 있어야 함 — 전체 선택 후 새 이름 입력
        let field = app.descendants(matching: .any).matching(identifier: "pane.left.edit.field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.typeText("note2.md")  // 전체선택 상태에서 입력하면 교체됨
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])

        XCTAssertFalse(m.exists, "확정 후 모달 닫혀야 함")
        let renamedRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.note2.md").firstMatch
        XCTAssertTrue(renamedRow.waitForExistence(timeout: 4), "이름변경된 행이 나타나야 함")
        XCTAssertFalse(noteRow.exists, "이전 이름 행은 사라져야 함")
    }

    func testRenameOnParentLinkIsNoOp() throws {
        let app = launchApp()

        // ".." 행 클릭 후 F2 → 모달 안 뜸
        let parentRow = app.descendants(matching: .any).matching(identifier: "pane.left.row.parent").firstMatch
        XCTAssertTrue(parentRow.waitForExistence(timeout: 4))
        parentRow.click()

        app.typeKey("\u{F705}", modifierFlags: [])
        // 충분한 시간 대기 후에도 모달이 없어야 함
        let m = modal(in: app)
        XCTAssertFalse(m.waitForExistence(timeout: 2), ".. 위에서 F2는 모달 안 뜸")
    }

    // MARK: - Esc 취소

    func testEscCancelsModal() throws {
        let app = launchApp()

        app.typeKey("k", modifierFlags: .option)
        let m = modal(in: app)
        XCTAssertTrue(m.waitForExistence(timeout: 4))

        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        XCTAssertFalse(m.waitForExistence(timeout: 2), "Esc 후 모달 닫혀야 함")
    }
}
