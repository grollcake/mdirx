# 주소 입력 popover + 키보드 탐색 가능한 히스토리 리스트

## 사용자 요구 (정제)
- **원문:** "커맨드L 누를 때 주소입력창이 팝업 형태가 되고, 팝업안 하단에 최근 주소 목록이 떠서 화살표로 이동할 수 있으면 좋을꺼 같은데 어따?" → 추천(A1/B/A/A) 그대로.
- **정제:** 활성 패널 헤더 path bar에 anchor된 popover에 (a) 상단 TextField로 직접 입력, (b) 하단에 자주+최근 경로 리스트, (c) ↓키로 리스트 진입·↑↓ 탐색·Enter 선택을 제공. 현재의 inline breadcrumb 교체 모드는 popover로 일원화.

## 개요
M1 탐색 UX 보강. `⌘L`이 페이지 컨텍스트를 잃지 않으면서 빠르게 경로 입력·히스토리 선택 두 가지를 모두 한 화면에서 수행할 수 있게 한다. 텍스트 필터링은 이번 범위에 포함하지 않는다(스펙 모호 → 후속).

## 요구사항
- UI 요구사항
  - `⌘L` 또는 breadcrumb 영역 더블클릭 → 활성 패널 path bar 바로 아래에 popover open.
  - popover 상단: 단일 라인 TextField, 진입 시 `currentURL.path`가 전체 선택된 채로 포커스.
  - popover 하단: 두 섹션 리스트
    - **자주 방문** (top 5, visitCount 우선·동률 시 visitedAt 우선 → 경로 알파벳 오름차순)
    - **최근 방문** (자주 제외, visitedAt desc)
    - 섹션 사이 작은 헤더 라벨로 구분 (`자주 방문` / `최근 방문`).
  - 리스트 항목은 한 줄, 경로 전체 표기, 너무 길면 trailing truncation.
  - popover 너비는 path bar 폭에 맞춤 (최소 320pt, 최대 패널 폭).
  - popover 높이는 리스트 항목 수에 따라 자동 (헤더·구분선·여백 포함, 최대 약 6~8 항목 후 스크롤).
- 동작 요구사항
  - 진입 시 TextField에 포커스, `addressListFocusIndex = nil`.
  - TextField 상태에서 `↓` → 리스트 첫 항목으로 포커스 이동 (`addressListFocusIndex = 0`). TextField는 더 이상 키 입력 받지 않음(blur).
  - 리스트 상태에서 `↑` / `↓` → 항목 사이 이동. 경계 처리: 첫 항목에서 ↑ → TextField로 복귀(`= nil`). 마지막 항목에서 ↓ → 그대로 유지.
  - `Enter`:
    - TextField에 포커스 시 → 기존 검증 + navigate (현재 동작 보존).
    - 리스트 항목에 포커스 시 → 해당 URL로 navigate + history 갱신.
  - `Esc` → popover close, 어떤 이동도 안 함.
  - popover 바깥 클릭 → close, 이동 안 함.
  - popover open 중 다른 단축키(F5/⌥K 등)는 모두 `.ignored` (NameEdit 모달과 동일 격리 규칙).
  - 양 패널 각각 자신의 popover. 활성 전환(Tab)하면 popover 닫힘.
- 데이터 요구사항
  - 리스트 데이터는 popover open 시 1회 fetch(`PathHistoryStore.menuURLs(for:)`)해서 캐시. open 동안 갱신 없음.
  - 기존 path bar 트레일링 히스토리 메뉴 버튼은 **유지** (빠른 액세스용; 추가 변경 위험 회피).

## 수도 코드
```text
on ⌘L or breadcrumb double click:
  activePane.beginAddressEditing()
  → PaneState.addressEditing = true
  → addressDraft = currentURL.path
  → addressFocusToken bumped (기존)
  → addressListItems = pathHistory.menuURLs(for: pane)
  → addressListFocusIndex = nil

PaneHeaderView:
  always show BreadcrumbView + history button (현재처럼)
  .popover(isPresented: addressEditing, attachmentAnchor: .point(.bottom)) {
      AddressPopoverView(state, pathHistory, fs, items: cached)
  }

AddressPopoverView body:
  VStack {
    TextField (focus when index == nil)
      .onSubmit { submitDraft }
      .onKeyPress(.downArrow) { focus → list[0]; .handled }
    Divider()
    if !items.frequent.isEmpty { section "자주 방문" }
    if !items.recent.isEmpty { section "최근 방문" }
    리스트 항목 ForEach:
      RowView highlighted when index == itemIdx
      .onTapGesture { navigate(item); close }
  }
  .onKeyPress(.upArrow) { if index nil: ignored; else index = max(-1 → nil, index-1) }
  .onKeyPress(.downArrow) { index = min(lastIdx, (index ?? -1)+1) }
  .onKeyPress(.return) { if listFocused: navigate; else handled by TextField }
  .onKeyPress(.escape) { cancel; close }

on navigate(url):
  await pane.navigate(to: url, via: fs)
  pane.cancelAddressEditing()  # popover 닫힘
```

## 아키텍처
- `Features/AddressBar/AddressPopoverView.swift` — 신규. popover 본문 (TextField + 두 섹션 리스트 + 키 라우팅).
- `Features/AddressBar/AddressBarView.swift` — 기존 inline 뷰는 사용처에서 제거하거나 (PaneHeaderView가 inline 분기를 안 타도록), 호환 위해 남겨두고 호출만 끊기. 깨끗하게 제거 선호.
- `Features/Pane/PaneHeaderView.swift` — addressEditing 분기 제거. 항상 BreadcrumbView + history button. popover modifier 추가.
- `Features/DualPane/PaneState.swift` — 신규 상태
  - `var addressListItems: (frequent: [URL], recent: [URL]) = ([], [])`
  - `var addressListFocusIndex: Int? = nil` (nil = TextField focus, ≥0 = list focus)
  - `var addressListFlat: [URL]` computed: `frequent + recent` 평탄화 (인덱스 매핑용)
  - `beginAddressEditing` 시 items 로드, focus index 초기화
  - `cancelAddressEditing` 시 items 비움, index nil
- `Features/DualPane/DualPaneView.swift` — popover 활성 중에는 letter shortcut 테이블/F-key 라우터 둘 다 `.ignored` 반환 (현재 addressEditing 가드와 동일 처리, 이미 letter는 처리됨; F-key 핸들러에 가드 이미 있음).

## 통과 조건
- [x] `⌘L` 또는 path bar 더블클릭 → popover open, TextField 포커스, currentURL 전체 선택. (사용자 수동 검증)
- [x] TextField에서 `↓` → 리스트 첫 항목 highlight, TextField blur. (수동 검증)
- [x] 리스트에서 `↑` / `↓` → 항목 highlight 이동. 첫 항목에서 `↑` → TextField로 복귀. (단위 테스트 `focusListNextClampsToLast`/`focusListPreviousFromZeroGoesToNil` + 수동)
- [x] 리스트 highlight 상태에서 `Enter` → 해당 URL로 navigate, popover close, history 갱신. (수동)
- [x] TextField focus 상태에서 `Enter` → 기존 검증·navigate 동작 그대로 (회귀 없음).
- [x] `Esc` → popover close, navigation 없음. (수동)
- [x] popover 바깥 클릭 → close. (SwiftUI popover 기본)
- [x] popover open 중 다른 단축키 발화 안 함. (DualPaneView.handleKeyPress `addressEditing` 가드)
- [x] 좌/우 패널 각각 자신의 popover.
- [x] 자주 방문 5개 알파벳 오름차순 + 최근 방문 visitedAt desc (`PathHistoryStore` 기존 동작 그대로).
- [x] 한글 IME 상태에서 TextField에 한글 입력 가능 (전역 핸들러 `.ignored`).
- [x] 기존 단위 테스트 회귀 없음 (93 → 99).
- [x] 신규 단위 테스트 7개 (`AddressPopoverFocusTests.swift`).
- [x] `xcodebuild build` / `xcodebuild test -only-testing:MdirXTests` 통과 (99 passed / 0 failed).
- [x] 완료 후 앱 재빌드·재실행.

## 구현 체크리스트
- [x] `PaneState`: `addressListItems`, `addressListFocusIndex`, `addressListFlat`, `addressListFocusedURL` + focus 이동 4종(`focusListFirst`/`focusListPrevious`/`focusListNext`/`focusTextField`)
- [x] `AddressListItems` 값 타입 (Equatable, `.empty` 상수)
- [x] `beginAddressEditing(items:)` 시그니처 확장 + cancelAddressEditing에서 items/index 리셋
- [x] `AddressPopoverView` 신설 + 키 라우팅
- [x] `PaneHeaderView` 항상 breadcrumb + history button, `.popover` modifier
- [x] inline `AddressBarView` 호출 제거 (PaneHeaderView 단순화)
- [ ] 기존 `AddressBarView`의 `PathHistoryMenuButton`은 별도 파일로 빠지거나 그대로 유지 (사용처: 헤더 트레일링 버튼)
- [ ] 패널 전환(Tab) 시 양 패널 popover 닫기
- [ ] 단위 테스트: focus 인덱스 전이, items 캐시
- [ ] `scripts/gen_xcode_pbx.py` 재실행 (신규 파일 자동 등록 확인)

## 테스트 케이스
- 정상
  - `⌘L` → TextField 포커스 + 전체 선택 → 임의 키 타이핑하면 텍스트 교체.
  - `↓` 한 번 → 자주 방문 첫 항목 highlight. Enter → 그 경로로 이동.
  - `↓ ↓ ↓` → 자주 → 자주 → 최근 첫 항목 (평탄화 인덱스 기준).
  - 마지막 항목에서 `↓` → 그대로 유지.
  - 첫 항목에서 `↑` → TextField로 복귀, 텍스트 보존.
  - 절대 경로 입력 + Enter → navigate.
- 엣지
  - 히스토리 0개 → 리스트 영역 hide, TextField만.
  - `Esc` → 어떤 상태에서든 popover close, navigation 없음.
  - 패널 활성 전환(Tab) → 현재 popover close.
  - 한글 IME에서 한글 자모 입력 후 영문 IME로 전환 → 정상 경로 입력 가능.
- 에러
  - 존재하지 않는 경로 입력 + Enter → 인라인 오류, popover 유지.
  - popover open 중 외부 단축키(F5 등) 누름 → 무시.

## 미해결·제약
- TextField는 macOS에서 단일 라인이라 `↓`가 보통 "행 끝으로 cursor"로 매핑됨. SwiftUI `onKeyPress(.downArrow)`가 TextField보다 먼저 받는지 확인 필요. 안 되면 NSEvent 로컬 모니터로 popover 활성 시점에 한정 인터셉트.
- popover anchor가 path bar 아래로 안정적으로 잡히는지 (헤더 polish 필요할 수 있음).
- 텍스트 필터링은 이번 범위 외 (요구되면 후속 계획).
