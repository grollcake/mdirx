# SwiftUI `onKeyPress`는 한글 IME 상태에서 `press.key.character`를 자모로 바꿔서 준다

## 상황 / 의도
`DualPaneView`의 단축키 라우팅이 `press.key == KeyEquivalent("l")` 같은 문자 비교로 되어 있었다. macOS 입력 소스가 영문일 때는 모든 단축키가 정상이었는데, 한글로 전환하면 `⌘L`/`⌥K`/`⌃N`/`⌘A`/`⌥U`/`⌘Z` 같은 **modifier + 문자** 조합이 무동작 + system beep만 났다. F-키·Tab·Esc·방향키·Space는 영향 없음.

## 잘못된 접근 (가설 오판 가능성)
- "IME가 keyDown을 흡수해 onKeyPress 자체가 호출되지 않을 것" — **틀림.** 임시 NSLog로 잡아 보면 `onKeyPress`는 호출된다.
- "Cmd/Option은 modifier니까 character는 ASCII로 유지될 것" — **틀림.** 한글 IME는 modifier가 눌렸어도 character를 한글 자모(Hangul Compatibility Jamo)로 변환해 전달한다.

## 올바른 해결
modifier가 동반된 상태에서 `press.key.character`가 한글 자모면 표준 2-set 자판의 QWERTY 위치 문자로 역매핑한 뒤 비교한다.

```swift
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
```

비교 사이트는 `let qwerty = KoreanShortcutNormalizer.qwertyCharacter(for: press)` 한 줄을 두고 `qwerty == "k"` 식으로만 바꿔주면 된다. 영문 IME에서는 헬퍼가 원본을 그대로 돌려주므로 회귀 없음.

## 증거 (참고)
한글 IME ON에서 잡힌 값:
- `⌘L` → `chars="ㅣ"` (U+3163) mods=16 → `KeyEquivalent("l")`(U+006C) 비교 실패
- `⌥K` → `chars="ㅏ"` (U+314F) mods=8 → 실패
- `F5` → scalar=U+F708 mods=64 → 영문과 동일하게 정상 발화
- `Tab` → `"\t"` → 정상

## 참고
- 영구 요건: [`docs/requirements/shortcuts.md`](../../requirements/shortcuts.md)
- 구현: [`Features/DualPane/KoreanShortcutNormalizer.swift`](../../../Features/DualPane/KoreanShortcutNormalizer.swift)
- 테스트: [`Tests/UnitTests/KoreanShortcutNormalizerTests.swift`](../../../Tests/UnitTests/KoreanShortcutNormalizerTests.swift)
- 계획: `.plan/0517-1750-shortcuts-broken-in-korean-ime.done.md`
- 일본어/중국어 IME는 동일 함정 가능. 필요해질 때 같은 헬퍼에 매핑만 확장.
