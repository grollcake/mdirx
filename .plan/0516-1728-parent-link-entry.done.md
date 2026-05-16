# `..` 부모 항목 — 리스트 최상단에 합성

## 사용자 요구 (정제)

- **정제:** NexusFile/NCD 의 관례대로, **각 디렉터리 목록의 최상단에 `..` (parent link) 행을 합성**해 키보드·마우스 양쪽으로 상위 디렉터리 진입을 자연스럽게 한다. 현재 빌드의 좌측 패널 캡처에는 `..` 행이 비어 있는데, 이는 합성 단계가 없어서다. 합성 위치는 `FileSystemActor.listDirectory(...)` 의 결과 끝단(또는 `PaneState.load()` 직후) 한 군데. 정렬은 항상 절대 첫 행, sort key 와 무관.
- **원문 뉘앙스:** "왜 파일 목록 최상단에 .. 가 없어?"
- **의도 보존:** `..` 는 **selection 대상이 아니다**(다중 선택 계획에서 이미 `selectableIDs` 필터링에 isParentLink 제외). 더블클릭/Enter 시 ascend 와 동치(마우스 계획에서 이미 isParentLink 분기).

## 개요

`Core/FileSystem/DirectoryEntry.swift` 에 이미 도입(예정) 된 `isParentLink: Bool` 플래그를 활용해, `FileSystemActor.listDirectory(at:includeHidden:)` 가 결과 정렬 직후 **부모가 존재하면(filesystem root 가 아니면)** 첫 행으로 `..` 엔트리를 prepend 한다. `..` 의 `id`/`url` 은 `currentURL.deletingLastPathComponent()`, `displayName = ".."`, `isParentLink = true`, 그 외 메타데이터는 부모 디렉터리의 `URLResourceKey` 한 번 호출로 채운다(또는 표시상 비워도 무방 — default: Date/Time 만 채우고 size 는 0).

## 요구사항

### 데이터
- `FileSystemActor.listDirectory(at: URL, includeHidden: Bool)` 가 반환 직전 다음 처리:
  - `parent = url.deletingLastPathComponent()`
  - `if parent != url` 이면 `DirectoryEntry` 합성:
    - `id = parent`
    - `url = parent`
    - `displayName = ".."`
    - `ext = ""`
    - `isDirectory = true`
    - `isSymlink = false`
    - `isParentLink = true`
    - `isMountedVolume = false`
    - `size = 0`
    - `modificationDate = (parent 의 contentModificationDate) ?? .distantPast`
    - 색상 토큰: 폴더와 동일 orange
  - 합성 후 result 의 **맨 앞** 에 삽입(정렬 결과 위쪽).
- filesystem root(`/`) 에서는 합성하지 않음. 마운트 볼륨 root 도 동일(`URL(fileURLWithPath: "/Volumes/X")` 의 `deletingLastPathComponent()` 가 `/Volumes` 이므로 부모 존재 — 합성 OK).
- 합성된 `..` 는 sort 결과의 영향을 받지 않음(이미 정렬 후 prepend).

### 표시
- `# (row number)` 컬럼: `..` 행은 **1** 로 시작. 그 다음 일반 항목들이 2~N.
- `Name` 컬럼: `..` 텍스트, 폴더 아이콘.
- `Ext` 컬럼: 빈 문자열.
- `Size` 컬럼: 빈 칸(또는 `[DIR]` 가능; 캡처처럼 비워 두는 쪽 권장).
- `Date`/`Time` 컬럼: 부모 디렉터리의 mtime 표기.
- `Attrs` 컬럼: `____` (디렉터리 + parent link 인 경우 모든 비트 `_`).
- `Description` 컬럼: `상위 디렉터리` (i18n: en `Parent directory`).
- 색상: 폴더 orange.

### 동작
- 키보드 ↓↑ 이동 시 `..` 도 포함되어 cursor 가 멈출 수 있음.
- `Space` 또는 `Shift+↑↓` 으로 `..` 위에서 토글 시도 → **무동작**(`selectableIDs` 에서 제외, 다중 선택 계획 결정).
- `⌥U`/`⌘A` 전체 선택 토글 시 `..` 는 selection 에서 제외.
- `Enter` 또는 더블클릭 시 `..` → `ascend`(키보드/마우스 계획 결정 그대로).
- 초기 cursor 위치: `load()` 직후 cursor 는 `..` 가 아닌 **첫 번째 selectable 항목** 으로 설정(`entries.first(where: { !$0.isParentLink && !$0.isMountedVolume })`). 단, 디렉터리가 비어 있어서 `..` 만 있는 경우 → cursor 가 `..` 에 놓임.

### 요약·상태바
- 상단 요약("N 폴더, M 파일 (size)") 카운트에는 `..` 포함하지 않음 — 실제 내용물 기준.
- 마운트된 볼륨 행도 동일하게 제외(nexus-look 의 결정).
- 하단 상태바: cursor 가 `..` 일 때 `폴더 | 〈부모 mtime〉 | ____ | ..` 표기.

### 비범위
- `..` 의 i18n 별칭(예: `← 상위` 같은 표기) — `..` 그대로 유지.
- `..` 행을 더블클릭 외의 다른 표시(예: 별도 toolbar 버튼) — 별도 도입 없음.
- root 에서 `..` 를 표시하는 옵션(NexusFile 의 일부 설정) — 도입하지 않음.

### 성능·제약
- 디렉터리 1회당 한 번의 추가 `URLResourceKey` 조회(`parent`) — 무시할 수준.
- strict concurrency 0 warning 유지(actor 안에서 동기 호출만).

## 수도 코드

```
// Core/FileSystem/FileSystemActor.swift  (반환 직전 합성)
actor FileSystemActor {
    func listDirectory(at url: URL, includeHidden: Bool) async throws -> [DirectoryEntry] {
        var entries = try realChildren(of: url, includeHidden: includeHidden)
            .sorted(by: defaultOrder)
        let parent = url.deletingLastPathComponent()
        if parent != url {
            let pe = try? parent.resourceValues(forKeys: [.contentModificationDateKey])
            entries.insert(.init(
                id: parent, url: parent,
                displayName: "..", ext: "",
                isDirectory: true, isSymlink: false,
                isParentLink: true, isMountedVolume: false,
                size: 0,
                modificationDate: pe?.contentModificationDate ?? .distantPast
            ), at: 0)
        }
        return entries
    }
}

// Features/DualPane/PaneState.swift  (load 직후 cursor 초기 위치)
func load(via fs: FileSystemActor) async {
    do {
        let list = try await fs.listDirectory(at: currentURL, includeHidden: hiddenVisible)
        self.entries = list
        self.error = nil
        self.cursorID = list.first(where: { !$0.isParentLink && !$0.isMountedVolume })?.id
                     ?? list.first?.id
        self.selection.formIntersection(Set(list.map(\.id)))
        persistURL()
    } catch { /* 기존 동일 */ }
}
```

## 아키텍처

- **수정 파일**
  - `Core/FileSystem/FileSystemActor.swift` — `listDirectory` 결과에 `..` prepend.
  - `Core/FileSystem/DirectoryEntry.swift` — `isParentLink: Bool` 이미 도입 가정(없으면 본 계획에서 추가).
  - `Features/DualPane/PaneState.swift` — `load()` 의 cursor 초기 위치 로직 변경(첫 selectable, 없으면 첫 entry).
  - `Features/Pane/FileListView.swift` — `..` 행의 컬럼별 표시 분기(Ext/Size 비움, Description `상위 디렉터리`). 색상은 폴더 토큰 그대로.
  - `Features/Pane/PaneSummaryView.swift` — 카운트 시 isParentLink 제외(`selectableEntries` 사용).
- **신규 파일**: 없음.
- **데이터 흐름**: 변동 없음(합성은 actor 내부).
- **외부 의존성**: `URLResourceKey.contentModificationDateKey` 만.

## 통과 조건

- [ ] `xcodebuild build` 0 error / 0 warning.
- [ ] `xcodebuild test` — 신규 + 기존 모두 통과.
- [ ] **단위 테스트** (`Tests/UnitTests/ParentLinkSynthesisTests.swift`):
  - 임시 디렉터리 `/tmp/xyz/` 에 빈 디렉터리 + 파일 2개 → `listDirectory` 결과의 **첫 항목** 이 `..`, `isParentLink == true`, `url == /tmp/xyz/..` resolve 결과 = `/tmp`.
  - `/` 에서 `listDirectory` → `..` 없음.
  - 빈 디렉터리 → 결과 길이 1 (`..` 하나).
- [ ] **단위 테스트** (`Tests/UnitTests/PaneCursorInitTests.swift`):
  - `load()` 후 cursor 가 첫 일반 항목(또는 `..` 만 있으면 `..`).
  - 다중 선택 `⌥U` 토글 시 `..` 가 selection 에 포함되지 않음.
- [ ] **UI 테스트** (`Tests/UITests/ParentLinkVisibleTests.swift`):
  - 홈 디렉터리 열 때 첫 행이 `..` 텍스트.
  - 그 행 더블클릭 → 헤더 경로가 `/Users` 로 변경.
  - 그 행에서 Space 누름 → ▶ 마커 안 붙음(무동작).
- [ ] 수동: 캡처와 좌측 패널 비교 시 `..` 행이 1번에 보임.
- [ ] **사용자 OK** 후 `done` 전이.

## 구현 체크리스트

- [ ] `Core/FileSystem/DirectoryEntry.swift` — `isParentLink` 플래그 (없으면 추가)
- [ ] `Core/FileSystem/FileSystemActor.swift` — `listDirectory` 반환 직전 합성
- [ ] `Features/DualPane/PaneState.swift` — cursor 초기 위치 로직 갱신
- [ ] `Features/Pane/FileListView.swift` — `..` 행 컬럼 분기 표시
- [ ] `Features/Pane/PaneSummaryView.swift` — count·sum 에서 isParentLink 제외
- [ ] `Tests/UnitTests/ParentLinkSynthesisTests.swift`
- [ ] `Tests/UnitTests/PaneCursorInitTests.swift`
- [ ] `Tests/UITests/ParentLinkVisibleTests.swift`
- [ ] `MdirX.xcodeproj` 신규 소스 반영
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): synthesize ".." parent link at list top`

## 테스트 케이스

- **정상**
  - 홈 열기 → 첫 행 `..`, Date/Time 에 `/Users` mtime, Description `상위 디렉터리`.
  - `..` 더블클릭 → `/Users` 로 이동.
  - `..` 위에서 Space → 무동작, ▶ 안 붙음.
- **엣지**
  - filesystem root(`/`) 열기 → `..` 없음, 첫 행이 일반 디렉터리(`Applications`, `Users` 등).
  - 빈 디렉터리(예: 막 만든 `mkdir`) → 결과가 `..` 1개, 요약은 `0 폴더, 0 파일 (0 B)`.
  - 권한 거부 디렉터리: 에러 분기에 들어가므로 `..` 도 표시되지 않음(현재 에러 UI 우선).
  - 마운트 볼륨 root(`/Volumes/USB`) → 부모 `/Volumes` 가 있으므로 `..` 표시 OK.
- **에러 / 미지원**
  - 부모 디렉터리의 `URLResourceKey` 조회 실패 → modificationDate `.distantPast` 로 fallback, 표시는 정상.
  - 권한 거부 분기에서 `..` 만이라도 보여 줘 ascend 가능하게 할지: 본 계획 비범위. 현재 에러 화면 그대로.

## 디자인 결정 (default 채택)

| # | 결정 | 메모 |
|---|---|---|
| 1 | **합성 위치 = FileSystemActor 내부** | `PaneState` 가 view-layer 까지만 책임지도록 단일 책임 유지 |
| 2 | **root 에서는 미표시** | 부모가 자신과 같은 URL 인지로 판별 |
| 3 | **항상 최상단(정렬 무관)** | 정렬 적용 후 prepend |
| 4 | **selection·count 제외** | 다중 선택·요약 카운트 모두 isParentLink 필터 |
| 5 | **cursor 초기 위치 = 첫 selectable** | `..` 만 있는 빈 디렉터리는 cursor 가 `..` 에 |
| 6 | **표시 = `..` 텍스트 + 폴더 아이콘** | i18n 대체 표기 없음 |
| 7 | **Description = `상위 디렉터리`** | en `Parent directory` |

---

**상태:** `done` — 2026-05-16 완료·사용자 OK.
