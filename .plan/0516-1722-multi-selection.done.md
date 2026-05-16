# 다중 선택 — cursor / selection 분리 모델

## 사용자 요구 (정제)

- **정제:** 각 패널에 **두 개의 독립 상태**를 둔다. ① **cursor** = 키보드가 가리키는 단일 행, ② **selection set** = 다중 선택된 행 집합. Space 는 cursor 행의 selection 멤버십을 토글하고 cursor 를 다음 행으로 이동한다. `⌥U` 와 `⌘A` 는 "전체 선택 토글"(모두 선택 ↔ 전체 해제), `Esc` 는 selection 만 해제(cursor 유지). 마우스 단일 클릭은 cursor 만 옮기고 selection 은 건드리지 않는다. Shift+클릭은 cursor~클릭 위치 범위를 selection 에 누적, ⌘+클릭은 그 행의 selection 토글이며 두 경우 모두 cursor 가 클릭 위치로 이동한다. Shift+↑/↓ 는 cursor 이동 + 이전 cursor 행을 selection 토글(= Space 의 대칭). 네비게이션(Enter/⌘↑/`.`)이 일어나면 selection 자동 초기화. 시각화는 NexusFile 캡처 그대로: cursor = 행 배경 옅은 띠, selection = 행 첫 칸 `▶` 마커 + 강조 텍스트 색, 셀렉션 있을 때 상단 요약을 `선택정보: N 항목 (총 size)` 로 교체.
- **원문 뉘앙스:** "다중 선택은 기본적으로 스페이스. 스페이스를 누르면 현재 것이 선택되고 다음 항목으로 포커스 이동. 전체 선택은 Alt+U 로 토글." + 표 1~10 + "10 = 캡처 참고".
- **의도 보존:** 후속 F5/F6 복사·이동·삭제가 동작할 **선택 집합** 자료구조를 명확히 깐다. 본 계획은 선택 자체와 시각화·키맵까지로 한정하며, 파일 작업은 다음 계획.

## 개요

`PaneState` 의 `selectedID: URL?` 를 `cursorID: URL?` 로 의미 변경하고, 별도로 `selection: Set<URL>` 을 추가한다. `DualPaneView` 가 새 키(Space, ⌥U, ⌘A, Esc, Shift+↑, Shift+↓)를 `.onKeyPress` 로 가로채 활성 패널의 selection 메서드를 호출한다. SwiftUI `Table` 의 selection 바인딩은 **cursor 단일 모드**로만 쓰고, 다중 selection 의 시각화는 첫 컬럼에 직접 그리는 `▶` 마커 + 행 텍스트 색 톤으로 처리한다. 상단 `PaneSummaryView` 가 `selection.isEmpty` 에 따라 두 모드 사이를 전환한다.

[PLAN.md §3 키맵](../PLAN.md) 의 `⌥U` 의미가 "선택 반전" 에서 **"전체 선택 토글"** 로 바뀌며, Space·⌘A·Esc·Shift+↑/↓ 는 새로 추가된다.

## 요구사항

### 자료구조
- `PaneState`
  - `cursorID: URL?` (기존 `selectedID` 이름 변경)
  - `selection: Set<URL>` (신규)
  - `selectableIDs: [URL]` (계산 프로퍼티: `..` 부모 + 마운트된 볼륨 행 제외한 entries 의 url 리스트)
- 직렬화·SwiftData 영속화 본 계획에선 없음.

### 동작 — 키
| 키 | 동작 |
|---|---|
| `Space` | `cursorID` 의 selection 멤버십 토글 → cursor 한 칸 ↓ (없거나 마지막이면 cursor 유지). `..`·볼륨 행에서는 토글 없이 cursor 만 ↓. |
| `Shift+↓` | Space 와 동일(직관 위해 같은 동작). |
| `Shift+↑` | cursor 행 selection 토글 → cursor 한 칸 ↑. 첫 칸이면 토글만 하고 cursor 유지. |
| `⌥U` | "전체 선택 토글": `selection == Set(selectableIDs)` 이면 `selection.removeAll()`, 아니면 `selection = Set(selectableIDs)`. |
| `⌘A` | `⌥U` 와 동일(별칭 바인딩). |
| `Esc` | `selection.removeAll()`. `cursorID` 와 `currentURL` 는 유지. |
| `Enter` / `⌘↑` / `.` | 기존 네비게이션 + `selection.removeAll()`(이동 후 자동 초기화). |
| `↑` / `↓` | cursor 만 이동. selection 변화 없음. (Table 의 기본 동작.) |
| `⌘Z` / `⌥Z` | 숨김 토글 — selection 영향 없음(목록 자체가 바뀌면 selection 의 사라진 url 은 자동 정리 — 아래 동작 규칙). |

### 동작 — 마우스
| 행위 | 동작 |
|---|---|
| 단일 좌클릭 | cursor 가 클릭 행으로 이동. selection 변화 없음. |
| Shift+좌클릭 | cursor 위치 ~ 클릭 위치 사이 범위(`selectableIDs` 의 인덱스 기준) 전부를 `selection` 에 **추가**. cursor 는 클릭 위치로 이동. |
| ⌘+좌클릭 | 클릭 행의 selection 토글. cursor 는 클릭 위치로 이동. |
| 비활성 패널 어디든 클릭 | 그 패널이 활성으로 전환(셸 계획 결정 그대로). cursor·selection 은 그 패널의 기존 값 유지. |

### 동작 — 네비게이션·정합성
- `Enter`/`⌘↑`/`.` 로 디렉터리 이동 시 `selection.removeAll()` + `cursorID = entries.first?.id`.
- `load()` 가 다시 호출되면 `selection = selection.intersection(Set(entries.map(\.id)))` 로 사라진 항목 자동 정리.
- Tab 으로 패널 활성 전환 → 양쪽 패널 각자 selection 보존.

### 시각화 (캡처 매칭)
| 요소 | 표기 |
|---|---|
| **Cursor** | 행 배경 `Color.white.opacity(0.10)` (활성) / `0.05` (비활성). |
| **Selection 마커** | 행 가장 왼쪽 컬럼 자리(`#` 컬럼 안 또는 별도 prefix 컬럼)에 `▶` (U+25B6) 표시. 활성/비활성 무관 동일. |
| **Selection 텍스트 색** | 기본 토큰의 "강조 톤"(폴더는 더 밝은 orange, 파일은 더 밝은 흰색·기타 카테고리도 +10~20% lightness). |
| **상단 요약 — selection 비어 있음** | 기존 `N 폴더, M 파일 (size)`. |
| **상단 요약 — selection 있음** | `선택정보: N 항목 (총 size)` 노랑 텍스트. 캡처 매칭. |

- cursor 와 selection 은 **독립** — 한 행이 cursor 이면서 selection 일 수 있고, 그 경우 배경 띠 + `▶` 마커 + 강조 색이 모두 동시에 표시된다.

### 비범위
- F5/F6 복사·이동, Del/⇧⌘⌫/⌃⇧⌘⌫ 삭제 — 다음 계획. selection 자료구조는 본 계획에서만 깔아 둔다.
- 패턴(글롭·정규식) 선택 — `⌥+` / `⌥-` 등 — 후속.
- 컬러 코딩 토큰 자체는 nexus-look 에서 정의. 본 계획은 그 토큰의 "강조 톤" 변형만 추가.
- 드래그 선택(마우스 드래그로 박스 선택) — 후속.

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 유지.
- `Set<URL>` 멤버십·intersection 은 O(N) — 1만 항목까지 무리 없음.
- selection 메서드는 `@MainActor` (`PaneState` 격리 그대로).

### 위험 — SwiftUI Table 의 Shift+arrow 기본 동작
- `Table` 는 multi-selection 바인딩이 걸리면 Shift+arrow 를 내부에서 범위 선택으로 소비한다.
- 본 계획은 Table 의 selection 을 **single** 로만 쓰기 때문에 위험은 작지만, Shift+arrow 가 우리 `.onKeyPress` 보다 먼저 소비되지 않는지 구현 단계에서 확인 필요.
- 만약 충돌하면 fallback: Table → `List` 또는 `LazyVStack` 로 변경하고 cursor 를 직접 관리. 본 계획 통과 조건 안에 해당 fallback 기록을 남긴다.

## 수도 코드

```
// Features/DualPane/PaneState.swift  (확장)
@Observable @MainActor final class PaneState {
    // ...
    var cursorID: URL?              // 기존 selectedID 의 의미 변경 + 이름 변경
    var selection: Set<URL> = []    // 신규

    var selectableEntries: [DirectoryEntry] {
        entries.filter { !$0.isParentLink && !$0.isMountedVolume }
    }
    var selectableIDs: [URL] { selectableEntries.map(\.id) }

    func moveCursor(by delta: Int) {
        guard let cur = cursorID,
              let i = entries.firstIndex(where: { $0.id == cur }) else { return }
        let next = max(0, min(entries.count - 1, i + delta))
        cursorID = entries[next].id
    }

    func toggleAtCursor() {
        guard let cur = cursorID,
              let e = entries.first(where: { $0.id == cur }),
              !e.isParentLink, !e.isMountedVolume else { return }
        if selection.contains(cur) { selection.remove(cur) } else { selection.insert(cur) }
    }

    func spacePress()       { toggleAtCursor(); moveCursor(by: +1) }
    func shiftDownPress()   { spacePress() }
    func shiftUpPress()     { toggleAtCursor(); moveCursor(by: -1) }

    func selectAllToggle() {
        let all = Set(selectableIDs)
        selection = (selection == all) ? [] : all
    }
    func clearSelection() { selection.removeAll() }

    func extendRange(to clickedID: URL) {
        guard let from = cursorID,
              let i = selectableIDs.firstIndex(of: from),
              let j = selectableIDs.firstIndex(of: clickedID) else { return }
        let lo = min(i, j), hi = max(i, j)
        for k in lo...hi { selection.insert(selectableIDs[k]) }
        cursorID = clickedID
    }

    func toggleSingle(at clickedID: URL) {
        cursorID = clickedID
        if selection.contains(clickedID) { selection.remove(clickedID) }
        else { selection.insert(clickedID) }
    }

    // load() / enter() / ascend() 끝에 selection.removeAll() (네비게이션은 초기화)
    // load() 끝에 selection.formIntersection(Set(entries.map(\.id))) (사라진 항목 자동 정리)
}

// Features/DualPane/DualPaneView.swift  (키 5종 추가)
.onKeyPress(.space) {
    Task { await session.current.spacePressAndLoad() }   // load 무관, 그냥 spacePress()
    return .handled
}
.onKeyPress(.downArrow, modifiers: .shift) { session.current.shiftDownPress(); return .handled }
.onKeyPress(.upArrow,   modifiers: .shift) { session.current.shiftUpPress();   return .handled }
.onKeyPress("u", modifiers: .option)       { session.current.selectAllToggle(); return .handled }
.onKeyPress("a", modifiers: .command)      { session.current.selectAllToggle(); return .handled }
.onKeyPress(.escape) { session.current.clearSelection(); return .handled }

// Features/Pane/FileListView.swift  (selection 시각화)
TableColumn("") { row in
    Text(state.selection.contains(row.entry.id) ? "▶" : " ")
        .monospaced().foregroundStyle(.yellow)
}.width(14)
// Name / Description 색: state.selection.contains(id) ? token.emphasized : token.normal
// 배경(cursor 표시): .listRowBackground 또는 .background 로 cursorID 행만 띠 적용

// Features/Pane/PaneSummaryView.swift
if state.selection.isEmpty {
    Text("\(folderCount) 폴더, \(fileCount) 파일 (\(humanSize))")
} else {
    Text("선택정보: \(state.selection.count) 항목 (총 \(humanSelectionSize))")
        .foregroundStyle(.yellow)
}
```

## 아키텍처

- **수정 파일**
  - `Features/DualPane/PaneState.swift`
    - 필드: `selectedID` → `cursorID`(이름 변경), `selection: Set<URL>` 추가.
    - 메서드: `moveCursor`, `toggleAtCursor`, `spacePress`, `shiftDownPress`, `shiftUpPress`, `selectAllToggle`, `clearSelection`, `extendRange`, `toggleSingle`.
    - `load`/`enter`/`ascend` 끝에 selection 초기화 또는 intersection.
  - `Features/DualPane/DualPaneView.swift`
    - `.onKeyPress` 5종 추가 (Space, Shift+↑/↓, ⌥U/⌘A, Esc).
  - `Features/Pane/FileListView.swift`
    - 마커 컬럼 14pt 폭 신설(`#` 앞에 prefix), `▶` 또는 공백.
    - Name / Description 컬럼 텍스트 색을 `selection.contains` 분기.
    - cursor 행 배경 띠 적용(`Color.white.opacity(0.10/0.05)`).
    - 마우스 핸들러: Shift+클릭 → `extendRange`, ⌘+클릭 → `toggleSingle`, 단일 클릭 → cursor 이동(Table 의 기본 single selection 으로 자연 처리).
  - `Features/Pane/PaneSummaryView.swift` — 두 모드 전환.
  - `Core/FileSystem/DirectoryEntry.swift` — `isParentLink: Bool`, `isMountedVolume: Bool` 두 플래그 추가(이미 nexus-look 에서 볼륨 도입 시 들어옴; 본 계획에서 의존).
- **데이터 흐름**
  - 키 → `DualPaneView.onKeyPress` → `session.current.*` → `PaneState` 메서드 → UI 재계산.
  - 마우스 → `FileListView` 의 row gesture → `PaneState.{extendRange, toggleSingle}` 또는 단일 클릭은 Table 의 기본 selection 바인딩이 cursor 갱신.
- **외부 의존성**: 표준 라이브러리만.

## 통과 조건

- [ ] `xcodebuild build` 0 error / 0 warning.
- [ ] `xcodebuild test` — 신규 단위 + 기존 + UI 모두 통과.
- [ ] **단위 테스트** (`Tests/UnitTests/PaneSelectionTests.swift`):
  - 초기 `cursorID == entries.first?.id`, `selection.isEmpty`.
  - `spacePress()` → cursorID 가 다음으로 이동, 이전 cursor 가 selection 에 추가.
  - 한 번 더 `spacePress()` → 이전 cursor 제거 안 됨(다른 행을 토글); 첫 번째로 다시 가서 `spacePress()` 하면 토글 해제.
  - `shiftUpPress()` → 현재 cursor 토글 후 위로 이동.
  - `selectAllToggle()` → `selection.count == selectableIDs.count`. 한 번 더 → `selection.isEmpty`.
  - `clearSelection()` → selection 비고 cursor 는 유지.
  - `extendRange(to:)` → 범위 추가, cursor 이동.
  - `toggleSingle(at:)` → 그 행만 토글, cursor 이동.
  - `enter()`/`ascend()` 호출 후 selection 비어 있음.
  - load 후 사라진 url 은 selection 에서 자동 제거.
- [ ] **UI 테스트** (`Tests/UITests/PaneMultiSelectTests.swift`):
  - 시작 시 ▶ 마커가 어디에도 없음.
  - Space 1회 → 첫 항목 옆 ▶ 마커 등장, cursor 가 두 번째 항목으로 이동(accessibility identifier 기준).
  - Space 2회 더 → 항목 3개에 ▶, 상단 요약이 `선택정보: 3 항목 (...)` 노랑 표기.
  - ⌥U → 가능한 모든 selectable 행에 ▶, 한 번 더 → 모두 사라짐.
  - ⌘A → ⌥U 와 동일 결과.
  - Esc → ▶ 모두 사라지고 상단 요약이 기본으로 복귀, cursor 유지.
  - Enter 로 디렉터리 진입 → selection 비어 있음.
- [ ] 수동: 빈 디렉터리에서 Space → 무동작.
- [ ] 수동: `..` 행에서 Space → 토글 없이 cursor 만 이동.
- [ ] 수동: 마운트 볼륨 행에서 Space → 동일(토글 없이 cursor 만 이동).
- [ ] 수동: ⌘+클릭으로 5개 토글 추가, Shift+클릭으로 범위 확장 후 ⌥U 한 번이면 비어짐 확인.
- [ ] **사용자 OK** 후 `done` 전이.

## 구현 체크리스트

- [ ] `Features/DualPane/PaneState.swift` — 필드·메서드 확장
- [ ] `Features/DualPane/DualPaneView.swift` — `.onKeyPress` 5종 추가
- [ ] `Features/Pane/FileListView.swift` — 마커 컬럼·선택 색·cursor 배경·마우스 modifier 처리
- [ ] `Features/Pane/PaneSummaryView.swift` — selection 비어있을 때/있을 때 두 모드
- [ ] `Core/FileSystem/DirectoryEntry.swift` — `isParentLink`/`isMountedVolume` 플래그(이미 nexus-look 에서 의존)
- [ ] `Tests/UnitTests/PaneSelectionTests.swift`
- [ ] `Tests/UITests/PaneMultiSelectTests.swift`
- [ ] [`PLAN.md`](../PLAN.md) §3 키맵 갱신:
  - `선택 반전 | Alt+U | ⌥U | —` 행 → **`전체 선택 토글 | Alt+U | ⌥U | ⌘A`** 로 의미·보조 변경
  - 새 행 추가: `선택 토글 (현재 행) | Space | Space | —`
  - 새 행 추가: `선택 해제 | — | Esc | —`
  - 새 행 추가: `범위 선택 (마우스) | Shift+클릭 | Shift+클릭 | —`
  - 새 행 추가: `단일 토글 (마우스) | Ctrl+클릭 | ⌘+클릭 | —`
- [ ] [`TODO.md`](../TODO.md) — 다중 선택·전체 선택 항목 체크 표시
- [ ] [`README.md`](../README.md) 상태 줄 갱신
- [ ] `MdirX.xcodeproj` 신규 소스 반영
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): cursor + multi-selection (Space, ⌥U/⌘A, Esc, Shift/⌘ click)`

## 테스트 케이스

- **정상**
  - 홈에서 Space 3회 → 처음 3개 선택, cursor 가 4번째 행. 상단 요약 `선택정보: 3 항목 (총 X)`.
  - ⌥U → 가능한 전부 선택(부모·볼륨 제외), 한 번 더 → 비어짐.
  - Esc → ▶ 사라지고 cursor 는 그 자리.
  - Enter 로 하위 디렉터리 진입 → 새 디렉터리에서 selection 비어 있고 cursor 가 첫 행.
- **엣지**
  - 빈 디렉터리: Space·Shift+arrow 모두 무동작, 에러 없음.
  - 1만 항목 디렉터리: ⌥U 1회 → selection 1만 개, 상단 요약 즉시 갱신, 스크롤 부드러움.
  - cursor 가 마지막 행에서 Space → 토글 후 cursor 유지(범위 밖 이동 차단).
  - 부모 `..` 와 마운트 볼륨은 selectable 에서 제외 — 토글 무동작.
  - load 도중 외부에서 파일 삭제됨 → 다음 reload 시 사라진 항목 자동 정리, selection 줄어듦.
- **에러 / 미지원**
  - SwiftUI Table 이 Shift+arrow 를 가로채면 → fallback: List 기반 cursor 직접 처리(통과 조건 통과 시점에 어느 길을 선택했는지 본 문서에 기록).
  - 비활성 패널 selection 은 화면에서 색 톤이 같지만 cursor 띠가 옅어짐.

## 디자인 결정 반영표

| # | 결정 | 본 계획 반영 |
|---|---|---|
| 1 | **cursor / selection 두 상태 분리** | `cursorID` + `selection: Set<URL>` |
| 2 | **마우스 단일 클릭 = cursor 만 이동** | Table 기본 single-selection 바인딩이 cursor 역할 |
| 3 | **Shift+클릭 = 범위 누적** | `extendRange(to:)` |
| 4 | **⌘+클릭 = 단일 토글** | `toggleSingle(at:)` |
| 5 | **Shift+↑/↓ = 토글 + 이동** | Space 와 대칭 |
| 6 | **⌘A = ⌥U 동일** | `"a"` 와 `"u"` 두 키프레스 모두 같은 메서드 |
| 7 | **Esc = selection 만 해제** | `clearSelection()` |
| 8 | **네비게이션 시 selection 초기화** | `load`/`enter`/`ascend` 끝에 removeAll |
| 9 | **활성 패널 전환 시 selection 유지** | 각 `PaneState` 가 자기 selection 보관 |
| 10 | **캡처 참고: cursor 띠 + ▶ 마커 + 강조 텍스트 + 노랑 요약** | FileListView·SummaryView 에서 처리 |

---

**상태:** `done` (2026-05-16 20:50) — cursor/selection 분리, Space/Shift+↑↓/⌥U/⌘A/Esc 키맵, ▶ 마커·markedBackground(픽셀 매치)·요약 노랑 모두 반영. 자체 캡처 픽셀 검증 색차 6.8/255. 자동 테스트는 사용자 지시로 중단(단위 테스트 파일은 작성됨).
