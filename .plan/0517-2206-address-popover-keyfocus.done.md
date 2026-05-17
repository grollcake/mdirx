# 주소 popover 리스트 키 포커스 수정

## 사용자 요구 (정제)
- 원문: “Command+L로 주소표시줄을 나오게 한 후에 키보드 위아래로 최근 목록을 이동할 수 있거든. 그런데 한번만 이동하고 그 다음부터는 뾱뾱 소리만 나.”
- 정제: `⌘L`로 주소 popover를 연 뒤 `↓`로 최근/자주 방문 목록에 진입하면, 이후 `↑`/`↓`를 반복해 목록 highlight가 계속 이동해야 한다. 첫 이동 뒤 system beep만 나는 포커스 손실을 수정한다.
- 작업 순서: 계획 작성 → 코드 수정 → 사용자 보고 → 사용자 컨펌 시 learnings 후보 기록 → 커밋/푸시.

## 개요
주소 popover의 TextField가 첫 `↓` 입력을 처리한 뒤 포커스를 잃고, 리스트/팝오버 쪽이 키보드 포커스를 받지 못해 후속 방향키가 처리되지 않는 문제를 작은 범위로 수정한다. 기존 `PaneState`의 리스트 인덱스 전이 로직은 유지하고, SwiftUI focus 라우팅만 보강한다.

## 요구사항
- `⌘L` 진입 시 기존처럼 TextField가 포커스되고 현재 경로 전체 선택이 유지된다.
- TextField 상태에서 `↓`를 누르면 첫 히스토리 항목이 highlight된다.
- 리스트 highlight 상태에서 `↓`/`↑`를 반복해 항목 사이를 이동한다.
- 첫 항목에서 `↑`를 누르면 TextField로 복귀하고, 다시 `↓`를 누르면 첫 항목으로 진입한다.
- 리스트 highlight 상태에서 `Enter`는 해당 URL로 이동하고 popover를 닫는다.
- 주소 popover 활성 중 전역 키 핸들러는 기존처럼 TextField IME 합성을 방해하지 않는다.
- 새 의존성은 추가하지 않는다.

## 수도 코드
```text
AddressPopoverView state:
  fieldFocused: Bool
  listFocused: Bool

on appear:
  syncFocus()
  select all text when addressListFocusIndex == nil

syncFocus():
  if addressListFocusIndex == nil:
    fieldFocused = true
    listFocused = false
  else:
    fieldFocused = false
    listFocused = true

TextField on down:
  if state.focusListFirst():
    syncFocus routes next key events to list/root handler
    handled

Popover/list key handler:
  if list focus and down:
    state.focusListNext()
  if list focus and up:
    state.focusListPrevious()
    syncFocus routes to TextField if index became nil
  if list focus and return:
    navigate selected URL and close
```

## 아키텍처
- `Features/AddressBar/AddressBarView.swift`
  - `AddressPopoverView`에 리스트 키 입력용 focus 상태를 추가한다.
  - popover/list 컨테이너를 focusable로 만들어 TextField blur 이후에도 `onKeyPress`가 수신되게 한다.
  - 기존 `PaneState`의 `addressListFocusIndex`를 단일 진실로 유지한다.
- `Features/DualPane/PaneState.swift`
  - 현재 focus 이동 메서드가 이미 존재하므로, 필요할 때만 테스트 보강 수준으로 제한한다.
- `Tests/UnitTests/AddressPopoverFocusTests.swift`
  - 상태 전이는 이미 보호되어 있으므로 필요 시 리스트↔TextField 왕복 테스트만 보강한다.

## 통과 조건
- [x] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과.
- [x] `xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist CONFIGURATION_BUILD_DIR=$(pwd)/dist -only-testing:MdirXTests` 통과.
- [x] 앱 재빌드 후 실행. 표준 `dist/Build/Products/Debug/MdirX.app` 경로는 stale/missing 상태라 실패했고, 실제 생성된 `dist/MdirX.app` 실행으로 대체.
- [x] 사용자 수동 확인: `⌘L` → `↓ ↓ ↓`가 system beep 없이 목록 highlight를 연속 이동한다.
- [x] 사용자 수동 확인: 목록 첫 항목에서 `↑` → TextField 복귀, 다시 `↓` → 첫 항목 highlight.
- [x] 사용자 수동 확인: 목록 highlight 상태에서 `Enter` → 해당 경로 이동 및 popover close.

## 완료 기록
- 2026-05-17 22:12 사용자 확인: “둘 다 성공.”
- learnings 기록: `docs/learnings/swiftui/popover-highlight-state-is-not-keyboard-focus-or-scroll.md`

## 구현 체크리스트
- [x] `AddressPopoverView` 리스트 focus 상태 추가.
- [x] `addressListFocusIndex` 변화에 맞춰 TextField/list focus 동기화.
- [x] popover/list 컨테이너에 키 이벤트 수신 가능한 focusable 설정 추가.
- [x] 필요한 최소 테스트 보강.
- [x] 빌드·테스트·앱 재실행.

## 테스트 케이스
- 정상: `⌘L` → `↓` → 첫 항목 highlight → `↓` 반복으로 다음 항목 이동.
- 정상: 첫 항목 highlight → `↑` → TextField focus/전체 선택 유지.
- 정상: highlight 상태 → `Enter` → 선택 URL 이동.
- 엣지: 히스토리 0개 상태에서 `↓`는 기존처럼 미처리되고 TextField 입력을 방해하지 않는다.
- 회귀: 주소 popover 활성 중 일반 텍스트/한글 입력은 전역 핸들러에 먹히지 않는다.
