# 주소표시줄 + 경로 히스토리

## 사용자 요구 (정제)
- **원문 맥락:** "이제 어떤 계획을 해야하지?" → 후보 3번 선택.
- **정제:** 현재 breadcrumb 기반 패널 헤더에 직접 경로를 입력할 수 있는 주소표시줄을 추가하고, 이동한 경로를 패널별 히스토리로 저장·재사용할 수 있게 하는 계획을 세운다.
- **의도 보존:** 구현은 아직 하지 않고, M2 탐색 UX의 기반인 주소 입력·검증·히스토리 저장 흐름을 `.plan` 문서로 먼저 고정한다.

## 개요
각 패널 상단 헤더에 breadcrumb와 전환 가능한 주소 입력 모드를 제공한다. 사용자는 현재 경로를 직접 편집해 이동할 수 있고, 성공한 이동은 `PathHistoryEntry`에 저장된다. 이번 범위는 주소 입력과 히스토리 저장/드롭다운 호출까지이며, 사이드바·F10 점프·검색 결과 가상 폴더는 별도 계획으로 둔다.

## 요구사항
- UI 요구사항
  - 패널 헤더는 기본 상태에서 기존 breadcrumb를 유지한다.
  - breadcrumb 영역을 더블클릭하거나 `⌘L`을 누르면 활성 패널 헤더가 주소 입력 모드로 전환된다.
  - 주소 입력 모드에는 현재 `currentURL.path`가 전체 선택된 TextField로 표시된다.
  - Enter는 입력 경로로 이동, Esc는 편집 취소 후 breadcrumb 복귀.
  - 현재 화면의 경로 표시줄(breadcrumb) 오른쪽 끝에 작은 경로 히스토리 드롭다운 버튼을 항상 둔다.
  - 주소 입력 모드에서도 TextField 오른쪽 끝에 같은 드롭다운 버튼을 유지한다.
  - 드롭다운 버튼은 경로 표시줄 높이를 늘리지 않고, 기존 breadcrumb 텍스트 영역의 trailing accessory로 배치한다.
  - 드롭다운은 상단에 **가장 많이 방문한 Top 5**를 먼저 보여 주고, 구분선 1개를 둔 뒤, 그 아래에 **최근 방문 경로**를 최신순으로 보여 준다.
- 동작 요구사항
  - 입력값은 `~` 확장, 상대경로 금지, 절대경로만 허용한다.
  - 입력 경로가 존재하지 않거나 디렉터리가 아니면 이동하지 않고 인라인 오류를 표시한다.
  - 이동 성공 시 `PaneState.navigate(to:via:)`를 사용해 기존 selection/cursor 정리 규칙을 유지한다.
  - 성공한 이동은 패널별 히스토리에 저장한다. 같은 경로가 이미 있으면 중복 행을 만들지 않고 `visitedAt`과 방문 횟수를 갱신한다.
  - 앱 재시작 후에도 최근 경로 히스토리가 유지되어야 한다.
- 성능/제약
  - 히스토리는 패널별 최근 20개만 유지한다.
  - SwiftData 도입 시 `scripts/gen_xcode_pbx.py` 재실행을 계획에 포함한다.
  - 부모 `.onKeyPress`가 TextField 키 입력을 먹지 않도록 주소 편집 중에는 전역 키 핸들러가 `.ignored`를 반환해야 한다.

## 수도 코드
```text
on command-L or breadcrumb double click:
  activePane.addressEditing = true
  draft = activePane.currentURL.path
  focus address TextField
  select all text

on history button tap:
  open history dropdown for pane under the same path bar
  do not enter address editing mode

on address submit:
  input = expandTilde(draft)
  if input is not absolute path:
    addressError = "절대 경로를 입력하세요"
    return
  if input does not exist or is not directory:
    addressError = "폴더를 찾을 수 없습니다"
    return
  await pane.navigate(to: inputURL, via: fs)
  await pathHistory.record(inputURL, pane: pane.slot)
  addressEditing = false

on history dropdown select(url):
  await pane.navigate(to: url, via: fs)
  await pathHistory.record(url, pane: pane.slot)
  addressEditing = false

history dropdown:
  frequent = top 5 paths by visitCount desc, then visitedAt desc
  recent = latest paths by visitedAt desc excluding paths already in frequent
  render frequent
  if frequent and recent are both non-empty: render divider
  render recent
```

## 아키텍처
- `Features/AddressBar/AddressBarView.swift`
  - 주소 입력 TextField, 오류 라벨, 히스토리 드롭다운 UI.
  - breadcrumb 모드와 address 모드 양쪽에서 재사용되는 trailing 드롭다운 버튼을 제공한다.
  - 드롭다운 버튼 accessibility id: `pane.<slot>.path.history`.
- `Features/Pane/PaneHeaderView.swift`
  - 현재 `BreadcrumbView` 오른쪽 끝에 히스토리 드롭다운 버튼을 배치한다.
  - `PaneHeaderView`가 breadcrumb 모드와 address 모드를 전환해 표시한다.
- `Features/DualPane/PaneState.swift`
  - `addressEditing`, `addressDraft`, `addressError` 상태와 시작/취소/검증 헬퍼 추가.
- `Core/Persistence/Models/PathHistoryEntry.swift`
  - SwiftData `@Model`로 `path`, `visitedAt`, `visitCount`, `paneID` 또는 `paneSlotRaw` 저장.
  - 기존 `PLAN.md`의 `PathHistoryEntry` 방향을 따르되 현재 `PaneSlot`과 맞춰 최소 필드로 시작한다.
- `Core/Persistence/ModelContainer.swift`
  - 빈 schema에서 `PathHistoryEntry` 포함 schema로 변경.
  - 테스트용 in-memory container와 앱용 persistent container 분리 여부를 구현 시 결정하지 말고, 계획 구현 단계에서 명시적으로 선택한다.
- `Core/Persistence/PathHistoryStore.swift`
  - Top 5 조회, 최근 경로 조회, upsert, 20개 초과 pruning 담당.

## 통과 조건
- [ ] `⌘L`을 누르면 활성 패널만 주소 입력 모드가 되고 현재 경로가 TextField에 채워진다.
- [ ] 기본 breadcrumb 모드에서도 경로 표시줄 오른쪽 끝에 히스토리 드롭다운 버튼이 보인다.
- [ ] 히스토리 드롭다운 버튼 클릭은 주소 편집 모드로 전환하지 않고, 같은 경로 표시줄 아래에 히스토리 메뉴만 연다.
- [ ] Esc를 누르면 이동 없이 breadcrumb 모드로 복귀한다.
- [ ] 존재하는 절대 디렉터리 경로 입력 후 Enter → 해당 패널이 그 경로로 이동하고 selection이 비워진다.
- [ ] 존재하지 않는 경로 또는 파일 경로 입력 후 Enter → 이동하지 않고 인라인 오류가 보인다.
- [ ] 성공한 이동은 `PathHistoryEntry`에 저장되고, 같은 경로 재방문은 중복 없이 `visitedAt`과 `visitCount`가 갱신된다.
- [ ] 히스토리 드롭다운은 Top 5 frequent 섹션 → 구분선 → recent 섹션 순서로 표시된다.
- [ ] Top 5에 이미 표시된 경로는 recent 섹션에서 중복 표시하지 않는다.
- [ ] 히스토리 드롭다운 전체 후보는 패널별 20개 이하로 유지되고, 선택 시 해당 경로로 이동한다.
- [ ] 주소 편집 중 Enter/Esc는 TextField/주소 UI가 처리하고, 파일 리스트 Enter/Esc 동작이 실행되지 않는다.
- [ ] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과.
- [ ] `xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath .build/derived CONFIGURATION_BUILD_DIR=$(pwd)/dist -only-testing:MdirXTests` 통과.
- [ ] 완료 후 프로젝트 규칙대로 앱을 재빌드·재실행한다.

## 구현 체크리스트
- [ ] `PathHistoryEntry` SwiftData 모델 추가
- [ ] `PathHistoryStore` 추가: frequent/recent/upsert/prune(패널별 20개 제한)
- [ ] `ModelContainer` schema 갱신
- [ ] `PaneState` 주소 편집 상태·검증 메서드 추가
- [ ] `AddressBarView` 추가
- [ ] `PaneHeaderView` breadcrumb 오른쪽 끝 history button 배치 + breadcrumb/address 모드 전환
- [ ] `DualPaneView` `⌘L` 키 바인딩 및 주소 편집 중 `.ignored` 처리
- [ ] 단위 테스트: 경로 검증, 히스토리 upsert/prune, `PaneState` 주소 상태
- [ ] UI 테스트 또는 수동 검증: `⌘L` → 입력 → Enter 이동, Esc 취소, 히스토리 선택
- [ ] `scripts/gen_xcode_pbx.py` 재실행 및 신규 Swift 파일 등록

## 테스트 케이스
- 정상 케이스
  - 홈 하위 임시 폴더 절대경로 입력 후 이동.
  - `~/Desktop` 같은 tilde 경로 입력 후 이동.
  - 히스토리 드롭다운 Top 5 또는 recent 경로 선택 후 이동.
  - breadcrumb 모드에서 경로 표시줄 오른쪽 끝 드롭다운 버튼으로 히스토리 열기.
  - address 편집 모드에서도 TextField 오른쪽 끝 드롭다운 버튼으로 히스토리 열기.
  - 좌/우 패널 각각 다른 히스토리 순서 유지.
  - Top 5와 recent 사이에 구분선 1개 표시.
- 엣지 케이스
  - 입력값 앞뒤 공백 trim.
  - 현재 경로와 같은 경로 입력: reload 또는 no-op 중 하나로 고정(구현 시 명시).
  - 히스토리 21번째 저장 시 가장 오래된 항목 제거.
  - Top 5에 들어간 경로는 recent에서 제외되어 중복 노출되지 않음.
  - 주소 편집 중 Tab은 패널 전환이 아니라 TextField 기본 포커스 동작으로 둘지, 전역 무시로 둘지 구현 전 고정.
- 에러 케이스
  - 존재하지 않는 경로.
  - 파일 경로.
  - 권한 없는 디렉터리.
  - SwiftData 저장 실패 시 이동은 유지하되 히스토리 오류만 로그/상태로 남김.
