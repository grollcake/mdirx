# GUI 앱 디버그 로그는 `print()` 말고 `NSLog`

## 상황 / 의도
한글 IME 단축키 버그를 잡으려 `DualPaneView.onKeyPress` 진입부에 `print("[key:...]" + ...)`를 임시로 추가하고, 빌드한 앱 바이너리를 직접 실행해 stdout을 캡처했다. 사용자가 키를 누르고 끝났다고 했는데 **출력 파일에 `[key:...]` 라인이 하나도 없었다.** 단 시스템 로그(`IMKCFRunLoopWakeUpReliable` 같은 NSLog 계열)는 캡처되어 있었다.

## 잘못된 접근
- `open MdirX.app` 으로 띄우면 stdout이 어디론가 가 버리니, 바이너리(`MdirX.app/Contents/MacOS/MdirX`)를 직접 실행하면 stdout이 잡힐 거라고 가정. → **stdout이 비대화형(=tty 없음)일 때 Swift `print()`는 블록 단위로 버퍼**되어 라인이 흘러나오지 않을 수 있다. GUI 앱에서는 더 심하게 묻힌다.

## 올바른 해결
디버그 로그는 `NSLog`로 보낸다. Foundation의 `NSLog`는 stderr + 통합 로깅(unified logging) 두 곳 모두에 즉시 흘리므로, 어느 방식으로 캡처해도 잡힌다.

```swift
import Foundation

NSLog("[key:%@] chars=%@ scalars=%@ keyChar=%@ keyScalar=%@ mods=%lu",
      label, press.characters.debugDescription, scalars,
      press.key.character.debugDescription, keyScalar, press.modifiers.rawValue)
```

## 캡처 팁
- 바이너리 직접 실행 + `2>&1` 합쳐 백그라운드로 캡처하면 `NSLog`가 그 파일로 들어간다.
- `open` 으로 띄웠다면 `log stream --process MdirX --predicate 'eventMessage CONTAINS "[key:"'` 로 통합 로그를 필터링해 본다.
- 임시 디버그 로그는 작업 끝나면 반드시 제거 — release 빌드에까지 흘러가지 않게.

## 참고
- 사례: `.plan/0517-1750-shortcuts-broken-in-korean-ime.done.md` 증거 수집 절.
