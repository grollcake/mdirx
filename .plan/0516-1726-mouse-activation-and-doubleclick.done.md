# 마우스 — 패널 활성화 + 더블클릭 진입/실행

## 사용자 요구 (정제)

- **정제:** 현재 빌드에서 두 가지가 동작하지 않는다. ① **단일 클릭으로 패널 간 활성 전환이 안 됨** — 비활성 패널의 빈 공간·헤더·리스트 행 어디를 클릭해도 활성 외곽선이 옮겨가지 않는다(셸 계획·file-listing 계획에서 `.onTapGesture` 와 `onChange(selectedID)` 로 처리하기로 했으나 SwiftUI `Table` 이 클릭 이벤트를 먼저 소비하는 것으로 추정). ② **더블클릭으로 폴더 진입·파일 실행이 안 됨** — 키보드 Enter 만 동작하며 마우스 더블클릭 핸들러가 없다. 본 계획은 이 두 동작만 좁게 다룬다.
- **원문 뉘앙스:** "마우스 두번 클릭으로 실행이나 폴더 내부 이동이 안돼 / 마우스 클릭으로 탭간에 활성화 전환이 안돼" (← "탭간" 은 "패널 간" 의미로 해석).
- **의도 보존:** 키 매핑·다중 선택 모델·시각화는 그대로 두고, **마우스 이벤트 라우팅 한 군데**만 손본다. 새 자료구조·새 토큰·새 View 없음.

## 개요

`PaneColumnView` 전체 영역에 `simultaneousGesture(TapGesture(count: 1))` + `simultaneousGesture(TapGesture(count: 2))` 두 개를 동시에 걸어, `Table` 이 단일 클릭으로 cursor 를 갱신하든 말든 우리는 별도로 **활성화** 와 **더블클릭 진입** 을 받는다. 더블클릭은 현재 cursor 의 항목에 따라 분기 — 폴더면 `enter`, `..` 이면 `ascend`, 마운트 볼륨 행이면 root 로 진입, 일반 파일이면 `NSWorkspace.shared.open(url)`.

## 요구사항

### 동작
- **단일 클릭** (비활성 패널 / 활성 패널 어디든)
  - 그 패널을 `activePane` 으로 설정.
  - 클릭이 행 위라면 `Table` 의 single selection 바인딩이 자연스럽게 cursor 를 그 행으로 옮긴다(기존 동작).
  - selection set 은 변화 없음 (다중 선택 계획 그대로).
- **더블클릭**
  - 활성 패널의 cursor 항목 기준 분기:
    - `..` (parent link) → `PaneState.ascend()`.
    - 폴더 → `PaneState.enter()`.
    - 마운트 볼륨 행 → `currentURL ← volume.id`, `load()`.
    - 일반 파일 → `NSWorkspace.shared.open(entry.url)`. 성공/실패 모두 인라인 에러 표시 없음 — 실패 시 `PaneState.error` 에 한 줄("실행할 수 있는 앱 없음 등") 기록할지 결정만 필요(default: 무동작 + 콘솔 로그).
  - 비활성 패널 위에서 더블클릭하면: ① 그 패널 활성화 + cursor 가 그 행으로 이동 + ② 위 분기 실행을 **한 번에**. 두 클릭 사이에 활성 패널이 바뀌므로 두 번째 클릭은 이미 활성이 된 패널에서 발생 — 자연 처리됨.
- **trackpad 두 번 탭** (macOS 14+ 의 system gesture) — 동일하게 더블클릭으로 처리(SwiftUI 의 `TapGesture(count: 2)` 가 OS 설정 따름).

### 비범위
- 더블클릭으로 미리보기(QuickLook): Space 키와 함께 별도 계획.
- 더블클릭으로 이름 변경 시작(Finder 식): NexusFile 워크플로우에 없음 — 미도입.
- 우클릭 컨텍스트 메뉴.
- 드래그 선택, 드래그 이동/복사.
- 더블클릭 시 파일이 실행 불가일 때의 에러 다이얼로그.

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 유지.
- `NSWorkspace` 는 `@MainActor`. 메인스레드 호출이라 비동기 변환 불필요.

## 수도 코드

```
// Features/Pane/PaneColumnView.swift  (마우스 라우팅 추가)
struct PaneColumnView: View {
    @Bindable var state: PaneState
    let isActive: Bool
    let onActivate: () -> Void
    let onDoubleClick: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            PaneHeaderView(state: state, onSegmentTap: { /* breadcrumb */ })
            PaneSummaryView(state: state)
            FileListView(state: state)
            PaneStatusBar(state: state)
        }
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(isActive ? .accentColor : .separator, lineWidth: 1))
        .contentShape(Rectangle())
        // 두 제스처를 simultaneously 등록 — Table 의 선택 처리와 공존
        .simultaneousGesture(TapGesture(count: 2).onEnded { onDoubleClick() })
        .simultaneousGesture(TapGesture(count: 1).onEnded { onActivate() })
    }
}

// Features/DualPane/DualPaneView.swift  (분기 핸들러 호출)
PaneColumnView(state: session.left,
               isActive: session.activePane == .left,
               onActivate: { session.activePane = .left },
               onDoubleClick: { Task { await handleDoubleClick(on: session.left) } })

func handleDoubleClick(on pane: PaneState) async {
    guard let id = pane.cursorID,
          let entry = pane.entries.first(where: { $0.id == id }) else { return }
    if entry.isParentLink             { await pane.ascend(via: session.fs); return }
    if entry.isMountedVolume          { pane.currentURL = entry.url; await pane.load(via: session.fs); return }
    if entry.isDirectory              { await pane.enter(via: session.fs); return }
    NSWorkspace.shared.open(entry.url)
}
```

### SwiftUI `simultaneousGesture` 동시-탭 주의
- `TapGesture(count: 2)` 와 `TapGesture(count: 1)` 을 같이 걸면, 단일 클릭이 들어왔을 때 시스템은 **double-click delay** 동안 두 번째 탭 가능성을 기다린 뒤 single 로 결정한다 → `onActivate()` 가 ~250ms 지연될 수 있다.
- 본 계획은 이 지연을 **수용**한다. 활성 외곽선이 클릭 후 약간 늦게 그려지더라도 cursor 갱신은 `Table` 이 즉시 처리하므로 UX 손상 작음.
- 단일 클릭 즉시 활성화가 필수라면 fallback: `simultaneousGesture` 두 개 대신 `onChange(of: state.cursorID)` + 빈 영역만 `onTapGesture(count: 1)` 식으로 분기. 본 계획은 simultaneousGesture 우선, 체감상 불편하면 위 fallback 으로 전환.

## 아키텍처

- **수정 파일**
  - `Features/Pane/PaneColumnView.swift` — `onDoubleClick` 콜백 prop 추가 + `simultaneousGesture` 두 개 등록. 기존 `.onTapGesture { onActivate() }` 제거.
  - `Features/DualPane/DualPaneView.swift` — `PaneColumnView` 호출부에 `onDoubleClick` 핸들러 추가, `handleDoubleClick(on:)` 함수 신설.
- **신규 파일**: 없음.
- **데이터 흐름**: 마우스 탭 → `PaneColumnView` 두 제스처 중 하나 → `DualPaneView` 가 활성화 또는 분기 실행.
- **외부 의존성**: 기존 + `NSWorkspace`.

## 통과 조건

- [x] `xcodebuild build` 0 error / 0 warning. (`xcodebuild test -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS'` 빌드 단계 통과; AppIntents 미사용 metadata informational warning 은 기존 예외)
- [x] `xcodebuild test` — 신규 + 기존 모두 통과.
- [x] **단위 테스트** (`Tests/UnitTests/DoubleClickRoutingTests.swift`):
  - `handleDoubleClick` 의 cursor 가 `..` 항목 → `ascend` 가 호출됨(spy).
  - cursor 가 디렉터리 → `enter`.
  - cursor 가 마운트 볼륨 → `currentURL = volume.id` + `load`.
  - cursor 가 파일 → `NSWorkspace.shared.open` 호출(스파이 또는 mock 으로 protocol 화).
- [x] **UI 테스트** (`Tests/UITests/MouseActivationAndDoubleClickTests.swift`):
  - 시작 시 좌측 활성. 우측 패널의 빈 영역 클릭(또는 `pane.right` accessibility identifier 의 frame 영역) → 활성 외곽선이 우측으로 이동(`isSelected` 식별).
  - 한 번 더 좌측 패널 클릭 → 좌측 활성 복귀.
  - 활성 패널의 폴더 행 더블클릭 → 헤더 경로가 그 폴더로 변경.
  - 활성 패널의 일반 파일 더블클릭 → `NSWorkspace.shared.open` 이 호출되는지 검증(테스트 환경에선 mock 으로 호출 카운트만 확인).
- [ ] 수동: 비활성 패널의 일반 파일을 한 번에 더블클릭 → 그 패널이 활성화되고 동시에 기본 앱으로 파일이 열린다.
- [ ] 수동: 단일 클릭 활성화 지연이 250ms 이하로 체감되거나, 본 계획 fallback(`onChange(cursorID)` 단일 분기) 로 즉시 활성화 전환됨이 명시됨.
- [ ] **사용자 OK** 후 `done` 전이.

## 구현 체크리스트

- [x] `Features/Pane/PaneColumnView.swift` — `onDoubleClick` prop + `simultaneousGesture(TapGesture(count: 2))` + 단일 탭 활성화 라우팅 정리
- [x] `Features/DualPane/DualPaneView.swift` — `handleDoubleClick(on:)` 신설 + `PaneColumnView` 두 호출부에 핸들러 연결
- [x] `Core/FileSystem/DirectoryEntry.swift` — 이미 있는 `isParentLink`/`isMountedVolume` 플래그 사용 확인(없으면 추가). nexus-look 의존.
- [x] `Tests/UnitTests/DoubleClickRoutingTests.swift` — `handleDoubleClick` 분기 4종 (spy 로 호출 검증)
- [x] `Tests/UITests/MouseActivationAndDoubleClickTests.swift` — 활성 전환 + 폴더 더블클릭 + 파일 더블클릭(open mock)
- [x] 단일 클릭 활성화 지연이 체감상 어색하면 fallback 으로 전환 후 결정 기록
- [x] `MdirX.xcodeproj` 신규 소스 반영
- [x] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): mouse activation + double-click open/enter`

## 테스트 케이스

- **정상**
  - 좌측 활성 상태에서 우측 빈 영역 클릭 → 우측 외곽 accent 로 변경, 좌측 외곽 회색 복귀.
  - 우측 폴더 행 더블클릭 → 우측 헤더 경로가 그 폴더로 변경, cursor 가 첫 항목.
  - 일반 파일(`.md`, `.swift` 등) 더블클릭 → Finder 기본 앱으로 열림.
  - `..` 행 더블클릭 → 상위 디렉터리로 이동, selection 자동 초기화.
  - 마운트 볼륨 행 더블클릭 → 볼륨 root 진입.
- **엣지**
  - cursor 없음(빈 디렉터리) 상태에서 더블클릭 → 무동작.
  - 더블클릭 사이 간격이 OS 설정(시스템 환경설정 > 트랙패드/마우스 더블클릭 속도) 보다 길면 두 번의 단일 클릭으로 해석 — 정상.
  - 더블클릭 대상이 권한 없는 디렉터리 → `enter` 가 `PaneState.error` 에 메시지를 남김, 활성 패널은 계속 작동.
- **에러 / 미지원**
  - `NSWorkspace.shared.open` 가 false 반환(기본 앱 없음) → 콘솔 로그만, UI 무변화.
  - 더블클릭이 단일 클릭 지연을 만든다는 시각적 어색함이 있을 시: 본 계획 fallback 으로 전환 — `onChange(cursorID)` + 빈 공간 `onTapGesture(count: 1)` 분리. 어느 길을 선택했는지 본 문서 끝에 기록.

## 디자인 결정 (default 채택)

| # | 결정 | 메모 |
|---|---|---|
| 1 | **더블클릭 — 폴더 = `enter`** | Enter 키와 동일 분기 |
| 2 | **더블클릭 — `..` = `ascend`** | ⌘↑ / `.` 키와 동일 |
| 3 | **더블클릭 — 마운트 볼륨 = 볼륨 root 진입** | nexus-look 행과 일관 |
| 4 | **더블클릭 — 파일 = `NSWorkspace.shared.open`** | Finder 기본 앱 |
| 5 | **단일 클릭 = 활성화 + cursor 만 이동, selection 변화 없음** | 다중 선택 계획 결정 그대로 |
| 6 | **단일 클릭 활성화의 ~250ms 지연 수용** | 불편 시 fallback 으로 전환 |

## 구현 기록

- `PaneColumnView` 패널 전체에 단일/더블클릭 `simultaneousGesture` 를 추가했다.
- 검증 중 SwiftUI `Table` 행 더블클릭은 패널 전체 `simultaneousGesture` 만으로 전달되지 않는 것을 확인했다.
- fallback 으로 `FileListView` 의 모든 컬럼 셀에 동일한 primary mouse modifier 를 붙였다. 이 modifier 는 단일 클릭 시 패널 활성화+cursor 이동, OS double-click interval 안의 같은 셀 두 번째 클릭 시 더블클릭 분기를 실행한다.
- 활성 패널과 native `Table` focus/selection 표시가 어긋나는 문제를 확인해, 행 배경은 `isActive + selectedID` 기준의 명시적 표시로 전환했다. 활성 선택은 accent, 비활성 선택은 muted 배경으로 구분한다.
- 컬럼 셀 단위 modifier 로는 컬럼 사이/행의 남는 폭이 클릭 대상이 되지 않는 것을 확인해, `Table` 을 custom header + full-width row list 로 교체했다. 각 행 루트가 선택 배경, accessibility identifier, 단일/더블클릭 gesture 를 소유한다.
- `Table` 을 custom row 로 바꿀 때 고정 컬럼 폭을 과하게 잡아 좁은 패널에서 `Name` 컬럼이 화면 밖으로 밀렸다. `GeometryReader` 로 패널 폭에 맞는 compact column layout 을 계산하도록 보정했다.
- 테스트 환경의 파일 실행 검증은 `MDIRX_TEST_OPEN_LOG` 로 우회해 실제 앱 실행 대신 선택 파일 경로 기록을 확인한다.
- **후속 비범위:** QuickLook / 우클릭 / 드래그

---

**상태:** `done` — 사용자 검토·OK 완료. `xcodebuild test -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS'` 통과.
