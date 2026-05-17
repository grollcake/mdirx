import SwiftUI

/// modifier + 문자(QWERTY 위치) 단축키 한 건의 명세.
///
/// IME가 한글일 때 `press.key.character`가 자모로 들어와도
/// [`KoreanShortcutNormalizer`](KoreanShortcutNormalizer.swift)로 정규화한 뒤
/// `qwertyChar`와 비교한다.
struct LetterShortcut: Sendable {
    let qwertyChar: Character
    let modifiers: EventModifiers
    let action: @MainActor (BrowserSession) -> Void

    @MainActor
    func matches(qwerty: Character, modifiers held: EventModifiers) -> Bool {
        qwertyChar == qwerty && held.contains(modifiers)
    }
}

enum DualPaneShortcuts {
    /// 활성 패널 단축키 (편집 모달/주소 입력 중에는 무시됨)
    static let letterShortcuts: [LetterShortcut] = [
        .init(qwertyChar: "l", modifiers: .command, action: { $0.current.beginAddressEditing() }),
        .init(qwertyChar: "u", modifiers: .option, action: { $0.current.selectAllToggle() }),
        .init(qwertyChar: "a", modifiers: .command, action: { $0.current.selectAllToggle() }),
        .init(qwertyChar: "k", modifiers: .option, action: { $0.current.requestNewFolder() }),
        .init(qwertyChar: "n", modifiers: .control, action: { $0.current.requestNewFile() }),
        // ⌘Z 와 ⌥Z 둘 다 hidden 토글
        .init(qwertyChar: "z", modifiers: .command, action: { s in Task { await s.current.toggleHidden(via: s.fs) } }),
        .init(qwertyChar: "z", modifiers: .option, action: { s in Task { await s.current.toggleHidden(via: s.fs) } }),
    ]
}
