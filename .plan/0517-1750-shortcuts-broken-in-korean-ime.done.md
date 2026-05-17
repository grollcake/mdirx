# 한글 IME 상태에서 단축키가 동작하지 않는 문제

## 사용자 요구 (정제)
- **원문:** "단축키가 한글 IME 상태일때 작동하지 않아. 뾱뾱 소리만 나."
- **정제:** macOS 입력 소스가 한글로 설정되어 있을 때 앱 내 모든 키 단축키(`⌘L`, `⌥K`, `⌃N`, `⌘A`, `⌥U`, `⌘Z`/`⌥Z`, `.`, F2/F5/F6 등)가 발화하지 않고 시스템 beep만 발생한다. 영문 입력 소스로 전환하면 정상 동작한다.
- **의도 보존:** 사용자가 한글 IME를 켠 상태로 파일 관리를 하다가도 단축키가 작동해야 한다(현 시점에서 텍스트 입력은 NameEdit 모달과 주소창에서만 사용).

## 개요
SwiftUI `.onKeyPress`는 macOS 입력 소스가 한글일 때 `press.key`/`press.characters`에 **한글 자모**가 들어와 `KeyEquivalent("k")` 류 비교가 깨질 가능성이 높다. 함수 키(F2/F5/F6)도 같은 증상이라면 IME 합성 모드가 이벤트 자체를 가로채고 있을 수 있다. 이번 범위는 **원인 증거 수집 → 가장 작은 수정 → 회귀 방지 단위 테스트**까지이며, 텍스트 편집(NameEdit/AddressBar) 내부에서의 한글 입력은 별도 주제로 둔다.

## 요구사항
- 동작 요구사항
  - 한글 IME가 켜진 상태에서 다음 단축키가 모두 정상 발화한다: `⌘L`, `⌥K`, `⌃N`, `⌘A`, `⌥U`, `.` (ascend), `⌘Z`/`⌥Z`, F2, F5, F6, Tab, Return, 방향키, Space, Escape.
  - 영문 IME 상태의 기존 동작은 회귀 없이 유지된다.
  - NameEdit 모달과 주소창 편집 모드에서는 한글이 정상 입력되어야 한다(단축키 라우팅 수정이 텍스트 입력을 막아서는 안 된다).
- 증거 요구사항
  - 한글 IME 상태에서 `press.key.character`와 `press.modifiers`, 가능하면 NSEvent `keyCode`/`charactersIgnoringModifiers`를 일시 로깅으로 캡처해 **어떤 값이 들어오는지** 기록한다.
  - 영문 IME 상태와 한글 IME 상태 각각에서 같은 키를 눌렀을 때 들어오는 `press` 값을 비교한다.
- 제약
  - **수정 전에 증거를 모은다.** 추정만으로 키 핸들러를 통째로 갈아엎지 않는다(CLAUDE.md "추정 수정 금지").
  - 가능하면 SwiftUI `.onKeyPress` 안에서 해결한다. 그래도 안 되면 `NSEvent.addLocalMonitorForEvents` 폴백을 후보로 둔다.

## 수도 코드
```text
phase 1 — 증거 수집:
  - DualPaneView.onKeyPress의 최상단에 임시 로그를 둔다:
    print("[key] char=\(press.key.character)  scalar=\(scalar(press.key))  mods=\(press.modifiers)")
  - 한글 IME ON / OFF 두 상태에서 다음을 각각 1회씩 누른다: ⌘L, ⌥K, ⌃N, ⌘A, ⌥U, F2, F5, F6, Tab, ., Esc.
  - 한글 상태에서 어떤 키가 어떤 character로 들어오는지를 기록.

phase 2 — 후보 가설:
  (가) IME가 keyDown 자체를 흡수해 onKeyPress가 호출되지 않는다.
       → press 로그가 전혀 안 찍힘. 해결: AppKit 레벨 로컬 이벤트 모니터로 키 코드 라우팅.
  (나) onKeyPress는 호출되지만 character가 한글 자모로 바뀌어 KeyEquivalent("k") 비교가 실패한다.
       → press 로그는 찍힘. 해결: NSEvent.charactersIgnoringModifiers 또는 keyCode 기반 비교로 전환.
  (다) 함수 키(F2/F5/F6)는 character 변환이 없으므로 (가)에 해당. 문자 키만 (나).

phase 3 — 최소 수정:
  - (가): 글로벌 NSEvent 로컬 모니터를 도입해 modifier 단축키만 처리, SwiftUI onKeyPress는 텍스트/일반 키 유지.
  - (나): KeyEquivalent 문자 비교를 NSEvent keyCode 비교로 전환.
  - 둘 다인 경우: (가) 인프라 위에 (나)의 keyCode 매핑 테이블 구축.

phase 4 — 검증:
  - 한글 IME ON에서 위 단축키 전부 발화.
  - NameEdit/AddressBar 텍스트 입력에서 한글 정상 입력.
  - 단위 테스트로 keyCode → 액션 매핑을 회귀 방지.
```

## 아키텍처
- `Features/DualPane/DualPaneView.swift`
  - 증거 수집용 임시 로그 삽입 위치.
  - 수정 시 키 라우팅이 들어갈 단일 진입점.
- (가설 가/다 적중 시 신설) `Features/DualPane/GlobalKeyMonitor.swift`
  - `NSEvent.addLocalMonitorForEvents(.keyDown)`로 modifier 포함 단축키 가로채기.
  - 현재 `activePane`/`editing`/`addressEditing` 상태와 결합 가능한 의존성 주입 형태.
- (가설 나 적중 시) `Core/Input/KeyCodeMatching.swift`
  - 가상 키 코드 상수(`kVK_ANSI_K`, `kVK_ANSI_N`, `kVK_F2`…) 매핑 헬퍼.
- `Tests/UnitTests/KeyShortcutMatchingTests.swift`
  - 가설별 단위 테스트(가능한 부분만; 실제 IME 상태는 UI 테스트 영역).

## 증거 (캡처 결과)

한글 IME ON에서 `press`로 들어온 값:
- `⌘L` → chars=`"ㅣ"` (U+3163) mods=16 ← `KeyEquivalent("l")` 비교 실패
- `⌥K` → chars=`"ㅏ"` (U+314F) mods=8 ← `KeyEquivalent("k")` 비교 실패
- `F5` → scalar=U+F708 mods=64 → 정상 발화 (영문 IME와 동일)
- `Tab` → `"\t"` → 정상 발화

→ **가설 (나) 적중**: IME가 keyDown을 흡수하지 않음. `onKeyPress`는 호출되지만 modifier 동반에도 character가 한글 자모로 변환되어 매칭 실패.
→ F-키·빌트인 키(Tab/Esc/Arrow/Space/Return)는 영향 없음.

## 통과 조건
- [x] 증거 단계: 한글 IME ON에서 `press` 로그 캡처 후 위 "증거" 절에 기록.
- [x] 한글 IME ON에서 `⌘L`이 주소 입력 모드로 들어간다. (사용자 수동 검증)
- [x] 한글 IME ON에서 `⌥K`/`⌃N`이 새 폴더/새 파일 편집을 연다. (사용자 수동 검증)
- [x] 한글 IME ON에서 `F2`/`F5`/`F6`는 원래부터 정상 (증거에서 확인).
- [x] 한글 IME ON에서 `⌘A`/`⌥U`가 전체 선택 토글을 발화한다. (사용자 수동 검증)
- [x] 한글 IME ON에서 `.`/`⌘↑`이 부모로 이동한다. (`.`는 ASCII, `⌘↑`은 빌트인 — IME 무관)
- [x] 한글 IME ON에서 `⌘Z`/`⌥Z`가 hidden 토글을 발화한다. (사용자 수동 검증)
- [x] 한글 IME ON에서 Tab/Return/Space/Esc/방향키가 기존 동작과 동일하게 발화한다. (빌트인 KeyEquivalent — 영향 없음)
- [x] NameEdit 모달과 주소창 편집 모드에서 한글이 정상 입력된다 (전역 핸들러가 `.ignored` 반환, 영향 없음).
- [x] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과.
- [x] `xcodebuild test` 단위 테스트 신규 6개 추가 (`KoreanShortcutNormalizerTests.swift`).
- [x] 완료 후 앱을 재빌드·재실행한다.

## 구현 체크리스트
- [x] 증거 수집용 임시 NSLog 추가 및 한글 ON/OFF 캡처
- [x] 결과를 본 계획 문서 "증거" 절에 기록
- [x] 가설 (나) 확정 — modifier+character가 자모로 변환되어 매칭 실패
- [x] 최소 수정 적용: `KoreanShortcutNormalizer` 헬퍼 도입, modifier 있을 때 한글 자모 → QWERTY 역매핑
- [x] 임시 NSLog 제거
- [x] 단위 테스트 추가: `KoreanShortcutNormalizerTests.swift` 6개
- [x] `scripts/gen_xcode_pbx.py` 갱신 및 재실행 (신규 src/test 파일 등록)
- [x] `docs/requirements/shortcuts.md` 신설 — 단축키 IME-불변 영구 요건화
- [x] 한글 IME ON 상태 수동 검증

## 테스트 케이스
- 정상 케이스
  - 영문 IME에서 기존 모든 단축키 정상 (회귀 없음).
  - 한글 IME에서 `⌘L`/`⌥K`/`⌃N`/`F2`/`F5`/`F6`/`⌘A`/`⌥U`/`.`/`⌘Z`/Tab/Return/Space/Esc 각각.
  - NameEdit 모달에서 한글 자모 정상 합성, Esc로 취소, Return으로 commit.
  - 주소창 편집 모드에서 한글 입력 후 영문 경로로 IME 전환 → Enter 이동.
- 엣지 케이스
  - 한글 IME에서 단축키 누른 직후 한글 자모가 입력 필드에 새지 않는지.
  - 입력 합성 중(예: `ㄱ`만 누른 상태)에 단축키 누르면 합성 취소 동작이 어떻게 되는지 명시.
  - 글로벌 NSEvent 모니터 사용 시 다른 앱이 활성일 때 이벤트가 새지 않는지(local monitor 한정 여부 확인).
- 에러 케이스
  - 모니터 등록 실패: 해당 단축키만 비활성, 앱 크래시 금지.
