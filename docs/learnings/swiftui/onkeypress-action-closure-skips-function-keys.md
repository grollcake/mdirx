# SwiftUI `.onKeyPress(action:)` 클로저는 펑션 키(F1~F12)를 전달하지 않는다

## 상황 / 의도
듀얼 패널의 `DualPaneView`에 단일 `.onKeyPress { press in … }` 클로저로 Tab·Return·화살표·문자키와 함께 F2(rename)·F5(copy)·F6(move)도 처리하려 했다. 비교는 `press.key == KeyEquivalent(Character(Unicode.Scalar(0xF705)!))` 식 (`NSF2FunctionKey = 0xF705`, F5=0xF708, F6=0xF709).

## 잘못된 접근
- F2/F5/F6 핸들러를 다른 키와 같은 `.onKeyPress(action:)` 블록 안의 분기로 둠.
- 빌드·단위 테스트는 통과. 그러나 실제 키 입력 시 **아무 반응 없이 macOS system beep(뾱)** 만 남.
- 같은 패턴인데 Tab/Return/화살표/문자(`a`, `n`, `k`, …)는 잘 동작 → 키 라우팅 문제로 좁힘.

## 원인
`.onKeyPress(action:)`의 클로저는 텍스트 입력 키와 `KeyEquivalent`의 빌트인 상수(`.tab`, `.return`, `.upArrow`, `.escape`, …)만 라우팅한다. 펑션 키처럼 private-use area 스칼라(0xF704~0xF70F)로만 표현되는 키는 클로저로 들어오지 않거나 `press.key` 비교가 일치하지 않아 매칭 실패 → 미처리로 분류 → 시스템 beep.

이 함정은 단위 테스트로 잡히지 않는다(키 라우팅은 SwiftUI runtime 책임).

## 올바른 해결
**`.onKeyPress(keys: [KeyEquivalent], action:)` 명시 등록 오버로드**를 별도로 추가해 펑션 키를 정확히 매칭한다.

```swift
.onKeyPress(keys: [
    KeyEquivalent(Character(Unicode.Scalar(0xF705)!)), // F2
    KeyEquivalent(Character(Unicode.Scalar(0xF708)!)), // F5
    KeyEquivalent(Character(Unicode.Scalar(0xF709)!)), // F6
]) { press in
    switch press.key.character.unicodeScalars.first?.value {
    case 0xF705: …; return .handled
    case 0xF708: …; return .handled
    case 0xF709: …; return .handled
    default: return .ignored
    }
}
```

기존 `.onKeyPress(action:)` 블록은 문자/빌트인 키 처리용으로 그대로 두고, 펑션 키만 분리해 `keys:` 오버로드에 등록.

## 참고
- `Features/DualPane/DualPaneView.swift` — F2/F5/F6 분리 등록
- 계획: `.plan/0517-0919-f5-f6-file-ops.done.md`
- 함의: F3·F4·F7~F12 등 다른 펑션 키 단축키를 추가할 때 동일 함정 재발 가능. 새 펑션 키 바인딩은 무조건 `keys:` 오버로드에 추가할 것.
