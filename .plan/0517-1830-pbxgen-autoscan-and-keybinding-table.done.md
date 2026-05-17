# pbxproj 자동 스캔 + DualPaneView 키바인딩 테이블화

## 사용자 요구 (정제)
- **원문:** "1,2 다. 묻지말고 완수할때까지." — 직전 리팩토링 후속 후보 #1(pbxproj 자동 스캔)과 #2(DualPaneView keybinding 테이블화)를 함께 끝낸다.
- **정제:** 행동 변경 0. 빌드·테스트 통과 유지. 새 추상화는 검증 가능한 최소형으로.

## 개요
한 주 분량의 작업에서 누적된 두 가지 유지보수 함정을 해소한다.

1. **gen_xcode_pbx.py**는 새 Swift 파일마다 UID/BuildFile/FileReference/Group/Phase **5곳**에 수동 등록을 요구. 한 군데만 빠뜨려도 빌드 실패. 이번 세션에서도 1회 발생.
2. **DualPaneView.onKeyPress**는 70+줄의 if-chain에 IME 정규화·modifier 분기·F-키 라우팅이 얽혀 있어 다음 단축키 추가/수정 시 회귀 위험.

## 요구사항
- gen_xcode_pbx.py
  - `App/`, `Core/`, `Features/`, `DesignSystem/`, `Tests/UnitTests/`, `Tests/UITests/`를 walk해 모든 `*.swift`를 자동 등록한다.
  - UID는 (namespace + 상대경로) SHA-1 첫 24자(대문자) — 같은 파일은 같은 UID, diff 안정.
  - 그룹 계층은 발견된 디렉터리 구조를 그대로 미러링.
  - 타겟·빌드 컨피그·리소스 4개(Assets/entitlements/en+ko Localizable)는 하드코딩 유지 (자동화 가치 낮음).
  - 새 Swift 파일 추가 시 스크립트만 재실행하면 즉시 빌드 가능.
- DualPaneView 키 라우팅
  - `handleKeyPress(_:)` 단일 진입점으로 분리.
  - modifier+문자 단축키 6개(⌘L, ⌥U, ⌘A, ⌥K, ⌃N, ⌘Z, ⌥Z)는 `LetterShortcut` 테이블로.
  - 빌트인 `KeyEquivalent`(Tab/Return/Space/Esc/Arrow)는 단일 `switch press.key` 블록으로.
  - 한글 IME 정규화는 [`KoreanShortcutNormalizer`](../Features/DualPane/KoreanShortcutNormalizer.swift)를 통해 letter shortcut 비교 직전에만.
  - F2/F5/F6 펑션 키는 기존 `.onKeyPress(keys:)` 오버로드 유지 ([shortcuts.md](../docs/requirements/shortcuts.md) R2).
  - `editing` / `addressEditing` 모드 격리 의미 보존.

## 아키텍처
- `scripts/gen_xcode_pbx.py` 전면 재작성 (755줄 하드코딩 → 470줄 walk+template).
- `Features/DualPane/KeyShortcuts.swift` 신설: `LetterShortcut` struct + `DualPaneShortcuts.letterShortcuts` 테이블.
- `Features/DualPane/DualPaneView.swift`: `onKeyPress { press in handleKeyPress(press) }` + 본문 `handleKeyPress(_:)` 메서드.

## 통과 조건
- [x] `python3 scripts/gen_xcode_pbx.py` 후 `xcodebuild build` 성공.
- [x] `xcodebuild test -only-testing:MdirXTests` 통과 — 93 passed / 0 failed.
- [x] 단위 테스트 케이스 감소 없음.
- [x] DualPaneView의 onKeyPress 본문이 1줄 위임으로 축소, 로직은 `handleKeyPress(_:)`로.
- [x] letter shortcut 테이블 6항목이 기존 6개 단축키 동작을 1:1 보존 (⌘L, ⌥U, ⌘A, ⌥K, ⌃N, ⌘Z, ⌥Z).
- [x] 빌트인 키(Tab/Return/Space/Esc/Up/Down)와 `.` ascend는 switch + if로 명시 분기 유지.
- [x] 한글 IME 정규화 진입점은 letter 분기 한 곳만 (다른 분기는 한글 IME 영향 받지 않음).
- [x] F2/F5/F6 F-key 라우터 변경 없음.
- [x] 신규 파일(`KeyShortcuts.swift`)은 자동 스캔된 pbxproj에 자동 포함 — 수동 등록 0.
- [x] 완료 후 앱 재빌드·재실행.

## 구현 체크리스트
- [x] gen_xcode_pbx.py: walk + stable UID + group hierarchy 자동 생성
- [x] gen 재실행 → pbxproj 재생성 → 빌드 통과 검증
- [x] entitlements/Assets/Localizable 경로 보정 (재작성 중 발견된 정규화 차이 2건 수정)
- [x] KeyShortcuts.swift 신설: LetterShortcut struct + 테이블 6개
- [x] DualPaneView.handleKeyPress(_:) 분리, 본문 위임
- [x] 단위 테스트 93/93 통과
- [x] 앱 재실행 (수동 한글 IME 검증은 사용자 부재로 다음 세션에서)

## 제약·미해결
- **사용자 부재 상태에서 한글 IME 수동 검증 불가**. 변경의 핵심은 (a) 분기 데이터화 + (b) 정규화 진입점 1곳화이며, 비교 로직은 정확히 보존(`KoreanShortcutNormalizer.qwertyCharacter(for: press) == "k"` 식). 단위 테스트 6개(`KoreanShortcutNormalizerTests`)가 정규화 정확성 회귀를 막아준다.
- **gen_xcode_pbx.py의 리소스 부분은 여전히 하드코딩**. Assets/entitlements/Localizable 4건만 수동 유지. 새 리소스 추가가 잦아지면 그때 자동화 검토.

## 테스트 케이스
- 빌드: `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` ✓
- 단위: 93 passed / 0 failed ✓
- 수동 확인 (다음 세션): 영문/한글 IME 양쪽에서 ⌘L · ⌥K · ⌃N · ⌘A · ⌥U · ⌘Z · `.` · F2 · F5 · F6 · Tab · 방향키 동작
