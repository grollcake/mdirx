# 패널 내부 디렉터리 나열 (FileListView + FileSystemActor)

## 사용자 요구 (정제)

- **정제:** 듀얼 패널 셸 위에 각 패널이 자기 `currentURL` 의 디렉터리 항목을 실제로 나열하도록 한다. 표시 컬럼·정렬·키 매핑은 **NexusFile V 캡처를 기준**으로 한다(Name | Ext | Size | Time 4컬럼, [DIR] 표기, HH:MM 시간, 디렉터리 우선 정렬). 키보드만으로 진입/상위/숨김 토글이 가능해야 하고, 앱을 다시 열면 마지막 열렸던 경로로 복원된다.
- **원문 뉘앙스:** "캡처랑 똑같이 요건을 정해. 숨김은 ⌘Z/⌥Z 토글, 디렉토리 우선, 상위는 ⌘↑ + `.`(NexusFile식), 엔터로 진입, 마지막 경로 없으면 홈, 권한 거부 인라인 OK, 심볼릭 링크 다음에, 항목 한계 default 로."
- **의도 보존:** 정렬·키맵·룩앤필은 NexusFile 식 으로, 구현은 SwiftUI `Table` + actor-격리 FS 호출. 본 계획은 단일 디렉터리 표시 한 단계만 다룸. 멀티 선택·복사·이름변경·QuickLook 은 모두 후속.

## 개요

`Core/FileSystem/FileSystemActor` 가 `URL` 을 받아 정렬된 `[DirectoryEntry]` 를 비동기 반환한다. 각 패널은 `PaneState`(`@Observable @MainActor`) 가 보유하는 `currentURL`·`entries`·`selectedID`·`error`·`hiddenVisible` 를 보고 SwiftUI `Table` 로 4컬럼을 그린다. 진입(Enter)·상위(⌘↑ 또는 `.`)·숨김 토글(⌘Z 또는 ⌥Z) 키가 활성 패널에 작용하며, 패널의 `currentURL` 은 `UserDefaults` 로 종료/재기동 사이에 영속화된다.

## 요구사항

### UI (NexusFile 캡처 매칭)
- 각 패널 내부 = (상단 1줄) **요약** + (본문) **`Table`** + (하단 1줄) **상태바**.
- 요약: `N 폴더, M 파일 (총 SIZE)` — 인간 친화 단위(`ByteCountFormatter`, `.file` 스타일).
- 본문 `Table`(SwiftUI macOS):
  - **Name** — `Image(systemName:)` + 확장자 제외한 표시 이름 (디렉터리는 통이름). 정렬 키 default.
  - **Ext** — 파일은 lowercased ext, 디렉터리는 빈 문자열.
  - **Size** — 파일은 `ByteCountFormatter`(`.file`, decimal), 디렉터리는 `[DIR]`.
  - **Time** — 수정시각, `HH:mm` 24h locale-인식.
- 하단 상태바: 선택 항목 종류(`폴더`/`파일`) · `yyyy-MM-dd HH:mm` · 빈 슬롯(후속에서 진행률).
- 컬럼 헤더 클릭 정렬은 **이번 범위 밖** — default sort 고정.
- 활성/비활성 패널 외곽선·헤더 틴트는 셸 계획에서 결정한 그대로 유지.

### 동작
- **앱 기동**: 각 패널 `currentURL` ← `UserDefaults.standard.url(forKey:)`(`pane.left.lastURL` / `pane.right.lastURL`). nil 이거나 경로가 더 이상 디렉터리가 아니면 `home`.
- **항목 선택**: 단일 선택만(`Set<URL>` 단 1개). ↑/↓ 키 이동 또는 **마우스 클릭** 으로 선택. 시작 시 첫 항목 선택. Tab 으로 활성 패널 바뀌면 그 패널의 마지막 selectedID 가 살아 있어야 함.
- **마우스로 패널 활성화**: 비활성 패널의 어디든(헤더·요약·리스트 영역·상태바·빈 공간) 클릭 시 즉시 그 패널이 활성으로 전환. 리스트 행 클릭이면 **활성화 + 행 선택이 한 번에** 일어남.
- **Enter**: 활성 패널의 선택 항목이 디렉터리면 `currentURL` ← `entry.url.resolvingSymlinksInPath()` → reload. 파일이면 이번 계획은 **무동작**(QuickLook·실행은 후속).
- **⌘↑ 또는 `.`(period)**: 활성 패널 `currentURL` ← `parent`. 루트(`/`) 에서는 무동작.
- **⌘Z 또는 ⌥Z**: 활성 패널 `hiddenVisible` 토글, reload(목록만 다시 필터; 디스크 재조회는 동일 디렉터리면 캐시 가능하지만 본 계획은 **항상 재호출**, 단순화 우선).
- **Tab**: 셸 계획 그대로(좌↔우 활성 토글).
- **종료**: 각 패널 `currentURL` 을 위 UserDefaults 키에 저장(상태 변경 시 즉시 set, 별도 종료 훅 불필요).
- **에러**: 권한/존재하지 않음/IO 에러는 `PaneState.error` 에 `LocalizedError.localizedDescription` 저장, 본문 `Table` 대신 인라인 메시지 표시. 키 입력은 계속 가능.

### 비범위
- 컬럼별 정렬 토글·다중 정렬 기준.
- 다중 선택, 패턴 선택, `⌥U` 선택 반전.
- 복사·이동·삭제·이름변경·새 폴더 — 후속.
- 확장자별 컬러 코딩(NexusFile 식 색상) — 후속 디자인 토큰 도입 시.
- 디스크 사용량 바(드라이브 라벨, free/total) — 후속.
- 심볼릭 링크 시각 구분 / non-follow 옵션 — 다음 계획.
- FSEvents 실시간 갱신 — Phase 2.
- 썸네일/QuickLook 미리보기.
- `LazyVStack` 직접 가상화. (`Table` 의 내장 가상화에 위임.)

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 유지.
- 디렉터리 IO 는 `FileSystemActor` 내부에서만. UI 호출은 `Task { await … }` 로 격리 경계를 명시.
- 동일 디렉터리 reload 는 idempotent 해야 함(테스트 가능).
- `BrowserSession` / `PaneState` / `DirectoryEntry` 는 모두 `Sendable`(또는 `@MainActor` 격리)로 strict concurrency 0 warning 유지.

## 수도 코드

```
// Core/FileSystem/DirectoryEntry.swift
struct DirectoryEntry: Identifiable, Hashable, Sendable {
    let id: URL                     // == url, 안정 식별
    let url: URL
    let displayName: String         // ext 제외
    let ext: String                 // lowercased, 디렉터리는 ""
    let isDirectory: Bool
    let isSymlink: Bool
    let size: Int64                 // 디렉터리는 0 (UI 에서 [DIR])
    let modificationDate: Date
}

// Core/FileSystem/FileSystemActor.swift
actor FileSystemActor {
    func listDirectory(at url: URL, includeHidden: Bool) async throws -> [DirectoryEntry] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey,
                                          .fileSizeKey, .contentModificationDateKey,
                                          .isHiddenKey, .nameKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: includeHidden ? [] : [.skipsHiddenFiles])
        var entries: [DirectoryEntry] = []
        entries.reserveCapacity(urls.count)
        for u in urls {
            let r = try u.resourceValues(forKeys: keys)
            let name = r.name ?? u.lastPathComponent
            let isDir = r.isDirectory ?? false
            let isLink = r.isSymbolicLink ?? false
            let (base, ext): (String, String) = isDir
                ? (name, "")
                : splitExt(name)            // "foo.tar.gz" → ("foo.tar", "gz")
            entries.append(.init(
                id: u, url: u,
                displayName: base, ext: ext.lowercased(),
                isDirectory: isDir, isSymlink: isLink,
                size: Int64(r.fileSize ?? 0),
                modificationDate: r.contentModificationDate ?? .distantPast))
        }
        return entries.sorted(by: defaultOrder)
    }
}

func defaultOrder(_ a: DirectoryEntry, _ b: DirectoryEntry) -> Bool {
    if a.isDirectory != b.isDirectory { return a.isDirectory }      // dirs first
    return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
}

// Features/DualPane/PaneState.swift
@Observable @MainActor final class PaneState {
    let slot: PaneSlot               // .left / .right (== UserDefaults key suffix)
    var currentURL: URL
    var entries: [DirectoryEntry] = []
    var selectedID: URL? = nil
    var error: String? = nil
    var hiddenVisible: Bool = false

    func load(via fs: FileSystemActor) async {
        do {
            let list = try await fs.listDirectory(at: currentURL, includeHidden: hiddenVisible)
            self.entries = list
            self.error = nil
            if selectedID == nil { selectedID = list.first?.id }
            persistURL()
        } catch {
            self.entries = []
            self.error = error.localizedDescription
        }
    }

    func enter(via fs: FileSystemActor) async {
        guard let sel = selectedID,
              let entry = entries.first(where: { $0.id == sel }),
              entry.isDirectory else { return }
        currentURL = entry.url.resolvingSymlinksInPath()
        selectedID = nil
        await load(via: fs)
    }

    func ascend(via fs: FileSystemActor) async {
        let parent = currentURL.deletingLastPathComponent()
        guard parent != currentURL else { return }      // 루트
        currentURL = parent
        selectedID = nil
        await load(via: fs)
    }

    func toggleHidden(via fs: FileSystemActor) async {
        hiddenVisible.toggle()
        await load(via: fs)
    }

    private func persistURL() {
        UserDefaults.standard.set(currentURL, forKey: "pane.\(slot.rawValue).lastURL")
    }
}

// Features/DualPane/BrowserSession.swift  (refactor)
@Observable @MainActor final class BrowserSession {
    let left  = PaneState(slot: .left,  initial: restoredURL(.left)  ?? home)
    let right = PaneState(slot: .right, initial: restoredURL(.right) ?? home)
    var activePane: ActivePane = .left
    let fs = FileSystemActor()

    func toggleActive() { activePane = (activePane == .left) ? .right : .left }
    var current: PaneState { activePane == .left ? left : right }

    func bootstrap() async {
        await left.load(via: fs)
        await right.load(via: fs)
    }
}

// Features/DualPane/DualPaneView.swift  (key handling 확장)
.onKeyPress(.tab)    { session.toggleActive(); return .handled }
.onKeyPress(.return) { Task { await session.current.enter(via: session.fs) }; return .handled }
.onKeyPress(.upArrow, modifiers: .command) {
    Task { await session.current.ascend(via: session.fs) }; return .handled
}
.onKeyPress(".")     { Task { await session.current.ascend(via: session.fs) }; return .handled }
.onKeyPress("z", modifiers: .command) {
    Task { await session.current.toggleHidden(via: session.fs) }; return .handled
}
.onKeyPress("z", modifiers: .option) {
    Task { await session.current.toggleHidden(via: session.fs) }; return .handled
}
.task { await session.bootstrap() }

// Features/Pane/FileListView.swift
struct FileListView: View {
    @Bindable var state: PaneState
    let onActivate: () -> Void          // 행 클릭 등 selection 변화 시 호출
    var body: some View {
        Group {
            if let err = state.error {
                ContentUnavailableView("열 수 없음", systemImage: "lock", description: Text(err))
            } else {
                Table(state.entries, selection: $state.selectedID) {
                    TableColumn("Name") { e in
                        Label(e.displayName, systemImage: e.isDirectory ? "folder" : "doc")
                    }
                    TableColumn("Ext") { e in Text(e.ext) }.width(min: 40, ideal: 60)
                    TableColumn("Size") { e in
                        Text(e.isDirectory ? "[DIR]"
                             : ByteCountFormatter.string(fromByteCount: e.size, countStyle: .file))
                    }.width(min: 70, ideal: 90)
                    TableColumn("Time") { e in
                        Text(e.modificationDate, format: .dateTime.hour().minute())
                    }.width(min: 50, ideal: 60)
                }
            }
        }
        .onChange(of: state.selectedID) { _, _ in onActivate() }   // 행 클릭 = 활성화 + 선택
    }
}

// Features/Pane/PaneColumnView.swift  (배경 클릭으로도 활성화)
struct PaneColumnView: View {
    @Bindable var state: PaneState
    let isActive: Bool
    let onActivate: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            PaneSummaryView(state: state)
            FileListView(state: state, onActivate: onActivate)
            PaneStatusBar(state: state)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isActive ? Color.accentColor : Color.separator, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onActivate() }     // 헤더·요약·상태바·빈 공간 클릭
    }
}
```

## 아키텍처

- **신규 파일**
  - `Core/FileSystem/DirectoryEntry.swift` — 값 타입(`Sendable`).
  - `Core/FileSystem/FileSystemActor.swift` — `actor`, FS 호출 격리.
  - `Features/DualPane/PaneState.swift` — `@Observable @MainActor`, 패널 단위 상태·네비게이션 동작.
  - `Features/Pane/FileListView.swift` — SwiftUI `Table` 4컬럼.
  - `Features/Pane/PaneStatusBar.swift` — 하단 1줄 (선택 종류 · datetime · 빈 슬롯).
  - `Features/Pane/PaneSummaryView.swift` — 상단 1줄 ("N 폴더, M 파일 (size)").
- **수정 파일**
  - `Features/DualPane/BrowserSession.swift` — `leftPath`/`rightPath: String` 제거, `PaneState left/right` 보유, `fs: FileSystemActor` 추가.
  - `Features/DualPane/DualPaneView.swift` — 키 바인딩 추가(Enter / ⌘↑ / `.` / ⌘Z / ⌥Z), `.task { bootstrap() }`.
  - `Features/Pane/PaneColumnView.swift` — placeholder `Color.clear` → `VStack { Summary; FileListView; StatusBar }`.
- **데이터 흐름**
  - 키 입력 → `DualPaneView.onKeyPress` → `session.current.{enter,ascend,toggleHidden}()` → `PaneState` 가 `FileSystemActor` 호출 → 결과 반영 → UI 재계산.
  - 마우스 클릭 → `PaneColumnView.onTapGesture` 또는 `FileListView.onChange(selectedID)` → `onActivate` 콜백 → `session.activePane` 갱신. 행 클릭이면 `Table` 가 `selectedID` 도 동시 갱신.
- **외부 의존성**: 표준 라이브러리 (`FileManager`, `URLResourceKey`, `ByteCountFormatter`, `UserDefaults`) + SwiftUI `Table`. AppKit interop 미사용.

## 통과 조건

- [ ] `xcodebuild build` 0 error / Swift·Clang 경고 0(strict concurrency).
- [ ] `xcodebuild test` — 신규 단위 + 기존 + UI 모두 통과.
- [ ] **단위 테스트** (`Tests/UnitTests/FileSystemActorTests.swift`):
  - 임시 디렉터리에 `dir/`, `b.txt`(10B), `.hidden`, `a.txt`(20B) 생성 후 `listDirectory(includeHidden: false)` 호출 → `dir, a.txt, b.txt` 순으로 3개.
  - 같은 디렉터리에서 `includeHidden: true` → 4개에 `.hidden` 포함, 디렉터리 우선·이름순 유지.
  - 존재하지 않는 경로 호출 시 `throws`.
- [ ] **단위 테스트** (`Tests/UnitTests/PaneStateTests.swift`):
  - 임시 디렉터리 기준 `load()` 후 `selectedID == first.id`.
  - 첫 항목이 디렉터리일 때 `enter()` 후 `currentURL` 이 그 하위로 이동.
  - `ascend()` 로 부모로 이동. 루트(`/`)에서는 변화 없음.
  - `toggleHidden()` 이 `hiddenVisible` 을 뒤집고 entries 가 그에 맞게 재호출됨.
- [ ] **UI 테스트** (`Tests/UITests/FileListNavigationTests.swift`):
  - 앱 기동 후 활성 패널에 적어도 1개 row.
  - ↓ 1회 → 두 번째 row 선택. Enter(만약 디렉터리) → 경로 헤더 변경.
  - ⌘↑ → 헤더가 부모 경로로 복귀.
  - `.` 키 → 동일 부모 이동(이미 부모면 무동작 — 변화 없음 검증).
  - ⌘Z → 점 파일 토글: 사전에 임시 점파일을 생성한 디렉터리에서 항목 수 변화 확인 (`XCUIApplication` launchEnvironment 로 테스트 디렉터리 주입).
  - **마우스 활성화**: 시작 시 활성=`pane.left`. `pane.right` 의 빈 영역 클릭 → 외곽 accent 가 우측으로 이동(`isSelected` 식별자로 검증). 다시 `pane.left` 의 행 클릭 → 좌측 활성 + 그 행 selected 상태.
- [ ] 수동: 앱을 끄고 다시 열면 좌/우 패널이 마지막 경로로 복원. 없거나 삭제된 경로면 홈.
- [ ] 수동: 권한 없는 디렉터리(`/private/var/db` 등) 진입 시 인라인 "열 수 없음" 메시지 + 키 입력 계속 가능.
- [ ] **사용자 OK** 후 `done` 전이 + STATUS · 커밋.

## 구현 체크리스트

- [ ] `Core/FileSystem/DirectoryEntry.swift`
- [ ] `Core/FileSystem/FileSystemActor.swift` — `listDirectory(at:includeHidden:)`, 디렉터리 우선·이름순 정렬
- [ ] `Features/DualPane/PaneState.swift` — `@Observable @MainActor`, load/enter/ascend/toggleHidden, UserDefaults persist
- [ ] `Features/DualPane/BrowserSession.swift` — 리팩터(PaneState 2개 보유, fs 보유, bootstrap)
- [ ] `Features/Pane/FileListView.swift` — `Table` 4컬럼 + error fallback
- [ ] `Features/Pane/PaneSummaryView.swift` — 상단 1줄
- [ ] `Features/Pane/PaneStatusBar.swift` — 하단 1줄
- [ ] `Features/Pane/PaneColumnView.swift` — placeholder → Summary + FileListView + StatusBar, `.onTapGesture { onActivate() }` 추가
- [ ] `FileListView` 의 `onChange(selectedID)` → `onActivate()` 연결 (행 클릭 = 활성화 + 선택)
- [ ] `Features/DualPane/DualPaneView.swift` — onKeyPress 5종 추가, `.task` bootstrap
- [ ] accessibility identifiers — `pane.<slot>.row.<basename>`, `pane.<slot>.header` 등 UI 테스트 안정화
- [ ] `Tests/UnitTests/FileSystemActorTests.swift`
- [ ] `Tests/UnitTests/PaneStateTests.swift`
- [ ] `Tests/UITests/FileListNavigationTests.swift`
- [ ] `MdirX.xcodeproj` 신규 소스 반영 (`scripts/gen_xcode_pbx.py` 재실행)
- [ ] `README.md` 상태 줄 갱신 ("M1 진행 중 — 디렉터리 나열·기본 네비게이션")
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): directory listing with FileSystemActor (M1)`

## 테스트 케이스

- **정상**
  - 기동 후 활성 패널이 홈(또는 마지막 경로)을 4컬럼으로 나열, 디렉터리가 위쪽.
  - ↓↓ Enter 로 하위 진입 후 ⌘↑ 로 복귀하면 동일 경로·항목 수.
  - `.` 키도 동일하게 부모로.
  - ⌘Z 한 번 → `.bashrc` 등 점 파일 등장, 다시 ⌘Z → 사라짐. ⌥Z 도 동일.
  - 좌·우 각자 독립적으로 다른 경로 유지, Tab 으로 활성 전환 시 selectedID 보존.
  - 종료 후 재기동 → 좌/우 마지막 경로 복원.
- **엣지**
  - `/` 에서 ⌘↑·`.` → 무동작(에러 없음).
  - 심볼릭 링크 디렉터리에 Enter → resolve 된 실제 경로로 이동(`/var → /private/var`).
  - 빈 디렉터리 → `Table` 비어 있고 상단 요약 "0 폴더, 0 파일 (0 B)".
  - 항목 1만 개 디렉터리(`/usr/share/man/man3` 등) → 스크롤 부드러움 — `Table` 가상화 검증.
- **에러 / 미지원**
  - 권한 거부 디렉터리 → 인라인 "열 수 없음" + 원본 에러 메시지. 키 입력은 계속.
  - 마지막 경로가 삭제됨 → 홈으로 fallback, 부모 경로 잔재 없이 깔끔.
  - 동시 Tab + Enter 폭격 시 race — `Task` 가 순차 큐는 아니므로 `PaneState.load` 마지막 호출 결과만 반영(중간 결과 덮어쓰기 OK).

## 디자인 결정 (사용자 답변 반영)

| # | 결정 | 메모 |
|---|---|---|
| 1 | **4컬럼: Name·Ext·Size·Time** | 캡처 매칭. 정렬 토글은 후속. |
| 2 | **숨김 토글: ⌘Z 또는 ⌥Z** | 둘 다 바인딩. 기본 off. |
| 3 | **상위 키: ⌘↑(맥표준) + `.`(NexusFile식)** | 둘 다 바인딩. |
| 4 | **진입 키: Enter** | Double-click 진입은 후속. (단일 클릭은 본 계획에서 활성화+선택까지만.) |
| 5 | **초기 경로: UserDefaults 의 마지막 경로, 없으면 홈** | 키 `pane.left.lastURL` / `pane.right.lastURL`. |
| 6 | **권한 거부 인라인 메시지** | `ContentUnavailableView`. |
| 7 | **심볼릭 링크 표시, 진입 시 resolve** | 시각 구분 없음(다음 계획). |
| 8 | **FSEvents 도입 안 함** | Phase 2. |
| 9 | **항목 한계 없음** | `Table` 가상화에 위임. |
| ⊕ | **마우스 클릭으로 패널 활성화 + 행 선택** | 추가 결정. `PaneColumnView` 배경 탭 + `FileListView` `onChange(selectedID)` 으로 처리. |
| ⊕ | **확장자별 컬러·디스크 사용량 바** | 비범위 — 후속 디자인 계획에서. |

---

**상태:** `done` — 2026-05-16 완료·사용자 OK.
