# 듀얼 패널 셸 — 좌우 분할 + Tab 포커스 토글

## 사용자 요구 (정제)

- **정제:** M1 스캐폴딩 직후 첫 기능으로, `ContentView` 의 placeholder "MdirX" 텍스트를 **좌우 두 패널 레이아웃**으로 교체하고 **`Tab` 키만으로 활성 패널을 토글**할 수 있게 한다. 실제 파일 시스템 나열·복사 등은 본 계획 범위 밖이며, 각 패널에는 **경로 문자열(홈 디렉터리)만** 보여 준다. 사용자가 듀얼 패널 UX 의 체감을 가장 먼저 확인하기 위한 최소 단계.
- **이전 EXAMPLE 계획**은 삭제하고 본 문서로 정식 승격했으며, 스캐폴딩으로 이미 갖춰진 자산( `Features/DualPane/`, `Features/Pane/` 빈 디렉터리·`@Observable`·Swift 6 strict concurrency)을 명시적으로 활용한다.
- **의도 보존:** "리스트는 다음 계획에서" — 이번엔 레이아웃·키 이벤트만, 데이터·연산은 후속.

## 개요

`DualPaneView` 가 `HStack` 으로 두 `PaneColumnView` 를 좌우 배치하고, 두 패널의 상태(경로 문자열·활성 여부)는 단일 `@Observable` 모델인 `BrowserSession` 이 보유한다. 활성 패널은 테두리·헤더 배경 틴트로 시각 구분하고, `Tab` 키 입력으로 좌↔우 활성을 토글한다. 경로 입력·파일 목록·`NavigationSplitView` 사이드바는 본 계획 범위 밖.

## 요구사항

### UI
- 단일 `WindowGroup` 윈도우 안에 좌·우 1:1 두 컬럼.
- 각 컬럼 = 상단 헤더(경로 문자열 1줄) + 본문 영역(빈 placeholder; 이후 계획에서 `FileListView` 로 교체).
- 활성 컬럼은 **헤더 배경 accent 틴트** + **외곽 1pt accent 테두리** 로 비활성과 구분.
- 비활성 컬럼은 기본 배경·테두리(`.separator` 1pt).
- 윈도우 기본 사이즈 1000×600, 최소 800×500.

### 동작
- 앱 기동 시 `leftPath = rightPath = FileManager.default.homeDirectoryForCurrentUser.path`.
- 초기 활성: `.left`.
- `Tab` 키 누름 → 활성이 `.left ↔ .right` 토글, 시각 변화 즉시 반영.
- 윈도우 포커스가 앱 밖으로 나갔다 돌아와도 활성 상태는 유지.

### 비범위
- 디렉터리 항목 나열 / 정렬 / 스크롤.
- 탭 그룹(패널 내 다중 탭) — 후속 계획.
- 사이드바 / 주소표시줄 / 툴바.
- `FileSystemActor` 도입 — 후속 계획. 본 계획은 FS 호출 없음(경로 문자열만).
- 키맵 커스터마이즈, 명령 팔레트.

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 유지.
- SwiftUI 만 사용. `NSViewRepresentable` 도입 금지.
- `BrowserSession` 은 `@Observable` + `@MainActor` 격리(상태 변경이 UI 스레드에서만 발생함을 명시).

## 수도 코드

```
ENUM ActivePane { left, right }

@Observable @MainActor class BrowserSession {
    var leftPath:  String = home
    var rightPath: String = home
    var activePane: ActivePane = .left

    func toggleActive() {
        activePane = (activePane == .left) ? .right : .left
    }
}

@main struct MdirXApp: App {
    var body: some Scene {
        WindowGroup { DualPaneView() }
            .defaultSize(width: 1000, height: 600)
    }
}

struct DualPaneView: View {
    @State private var session = BrowserSession()
    var body: some View {
        HStack(spacing: 0) {
            PaneColumnView(path: session.leftPath,
                           isActive: session.activePane == .left)
            Divider()
            PaneColumnView(path: session.rightPath,
                           isActive: session.activePane == .right)
        }
        .frame(minWidth: 800, minHeight: 500)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.tab) {
            session.toggleActive()
            return .handled
        }
    }
}

struct PaneColumnView: View {
    let path: String
    let isActive: Bool
    var body: some View {
        VStack(spacing: 0) {
            Text(path)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.head)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
            Color.clear  // 본문 placeholder (후속 계획에서 FileListView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isActive ? Color.accentColor : Color.separator,
                        lineWidth: 1)
        )
    }
}
```

## 아키텍처

- **View**
  - [App/MdirXApp.swift](../App/MdirXApp.swift) — `WindowGroup` 이 `DualPaneView()` 를 **직접 호스팅**. `.defaultSize(width: 1000, height: 600)`.
  - `App/ContentView.swift` — **삭제**. 스캐폴딩 placeholder 는 본 계획에서 그 역할을 다함.
  - `Features/DualPane/DualPaneView.swift` (신규) — HStack + Divider + 두 `PaneColumnView`, `BrowserSession` 을 `@State` 로 보유, `.onKeyPress(.tab)` 처리.
  - `Features/Pane/PaneColumnView.swift` (신규) — 위 수도 코드 정의.
- **ViewModel / 상태**
  - `Features/DualPane/BrowserSession.swift` (신규) — `@Observable @MainActor final class BrowserSession`. `leftPath`, `rightPath`, `activePane: ActivePane`, `toggleActive()`. SwiftData 미도입(본 계획).
- **데이터 흐름**: 단방향. `DualPaneView` 가 세션 보유, 자식 `PaneColumnView` 는 `path`·`isActive` 값만 받음(콜백 없음).
- **외부 의존성**: 표준 라이브러리·SwiftUI 만. FS 호출은 `FileManager.default.homeDirectoryForCurrentUser.path` 1회.

## 통과 조건

- [x] `xcodebuild build` 0 error / Swift·Clang 경고 0 (strict concurrency 유지; 툴체인 informational 로그는 스캐폴딩 계획과 동일 전제).
- [x] `xcodebuild test` — 단위(BrowserSession×2 + 스모크) + UI(Launch + Tab 토글) 모두 통과.
- [x] **단위 테스트** (`Tests/UnitTests/BrowserSessionTests.swift`):
  - 초기 `activePane == .left`.
  - `toggleActive()` 후 `.right`, 한 번 더 후 `.left`.
- [x] **UI 테스트** (`Tests/UITests/DualPaneTabToggleTests.swift`):
  - 앱 기동 후 `pane.left` / `pane.right` 존재.
  - 시작 시 `pane.left` 가 `isSelected`.
  - Tab 후 `pane.right` 활성, 한 번 더 Tab 후 `pane.left` 재활성.
- [x] 수동: macOS 15+ 실기에서 Tab 5회 연속·포커스 아웃/복귀 확인 — **사용자 완료 처리로 확인**.
- [x] **사용자 OK** — 본 문서·파일명 `done`, [STATUS.md](STATUS.md) 완료일시·✅ 반영.

## 구현 체크리스트

- [x] `Features/DualPane/BrowserSession.swift` — `@Observable @MainActor` 모델 + `ActivePane` enum
- [x] `Features/DualPane/DualPaneView.swift` — HStack + Divider + 두 PaneColumnView, `.onKeyPress(.tab)` 처리
- [x] `Features/Pane/PaneColumnView.swift` — 헤더(monospaced path) + 본문 placeholder + 활성 시 accent 테두리/틴트
- [x] `App/ContentView.swift` — **삭제** (스캐폴딩 placeholder 제거)
- [x] `App/MdirXApp.swift` — `WindowGroup { DualPaneView() }` + `.defaultSize(width: 1000, height: 600)`
- [x] accessibility identifiers (`pane.left`, `pane.right`) + 활성 시 `isSelected`
- [x] `Tests/UnitTests/BrowserSessionTests.swift`
- [x] `Tests/UITests/DualPaneTabToggleTests.swift`
- [x] `xcodebuild test` 전부 통과; `MdirX.xcodeproj` 는 `scripts/gen_xcode_pbx.py` 로 신규 소스 반영
- [x] [README.md](../README.md) 상태 줄 갱신
- [x] [`.plan/STATUS.md`](STATUS.md) — 완료일시·✅ 반영
- [ ] 커밋 — 사용자 요청 시 `feat(dualpane): split layout with Tab focus toggle (M1)`

## 테스트 케이스

- **정상**
  - 기동 직후 좌·우 두 컬럼 보이고 좌측이 활성.
  - Tab 1회 → 우측 활성. Tab 2회 → 좌측 활성. 5회 반복도 안정.
  - 각 컬럼 헤더에 홈 경로(예: `/Users/rollcake`) 표시.
- **엣지**
  - 윈도우를 최소 사이즈(800×500)로 줄여도 헤더 truncation(head) 으로 경로가 잘려서라도 표시.
  - 한국어 sysytem locale 에서도 동일 (경로는 로케일 영향 없음).
  - 윈도우 포커스 아웃 → 다른 앱 사용 → 복귀: 활성 패널 유지.
- **에러 / 미지원**
  - `.onKeyPress(.tab)` 이 macOS 15 미만에서 동작하지 않을 수 있으나 Deployment Target 15.0 이므로 범위 밖.
  - 포커스링 충돌로 Tab 이 기본 포커스 순환에 먹힐 경우 `.focusEffectDisabled()` + `return .handled` 로 막음 — UI 테스트에서 회귀 잡기.

---

**상태:** `done` — 2026-05-16 사용자 완료 처리. 자동 테스트·문서 동기화 완료.
