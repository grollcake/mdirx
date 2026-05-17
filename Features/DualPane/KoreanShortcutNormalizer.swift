import SwiftUI

/// 한글 IME가 켜진 상태에서 modifier+문자 단축키가 동작하도록,
/// `press.key.character`로 들어오는 한글 자모(Hangul Compatibility Jamo)를
/// 표준 2-set 자판의 QWERTY 위치 문자로 역매핑한다.
///
/// modifier(`command`/`option`/`control`)가 없으면 원본 문자 그대로 반환한다.
/// 자모 매핑 테이블 밖이거나 이미 ASCII면 원본을 그대로 돌려준다.
enum KoreanShortcutNormalizer {
    static func qwertyCharacter(for press: KeyPress) -> Character {
        let hasModifier = press.modifiers.contains(.command)
            || press.modifiers.contains(.option)
            || press.modifiers.contains(.control)
        guard hasModifier else { return press.key.character }
        guard let scalar = press.key.character.unicodeScalars.first else { return press.key.character }
        return hangulToQwerty[scalar] ?? press.key.character
    }

    static let hangulToQwerty: [Unicode.Scalar: Character] = [
        "ㅂ": "q", "ㅈ": "w", "ㄷ": "e", "ㄱ": "r", "ㅅ": "t",
        "ㅛ": "y", "ㅕ": "u", "ㅑ": "i", "ㅐ": "o", "ㅔ": "p",
        "ㅁ": "a", "ㄴ": "s", "ㅇ": "d", "ㄹ": "f", "ㅎ": "g",
        "ㅗ": "h", "ㅓ": "j", "ㅏ": "k", "ㅣ": "l",
        "ㅋ": "z", "ㅌ": "x", "ㅊ": "c", "ㅍ": "v", "ㅠ": "b",
        "ㅜ": "n", "ㅡ": "m",
        "ㅃ": "Q", "ㅉ": "W", "ㄸ": "E", "ㄲ": "R", "ㅆ": "T",
        "ㅒ": "O", "ㅖ": "P",
    ]
}
