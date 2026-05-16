# 프로젝트 스캐폴딩 (M1 킥오프)

## 사용자 요구 (정제)

- **정제:** MdirX의 M1 킥오프 전 단계로, [PLAN.md](../PLAN.md)에 정의된 디렉터리 구조·번들 ID·툴체인을 충족하는 **빌드·실행 가능한 빈 SwiftUI 앱 골격**을 만든다. 이 단계에서는 실제 기능을 넣지 않고, 이후 모든 기능 계획(`.plan/*.todo.md`)이 곧바로 코드 작업을 시작할 수 있는 **공통 기반**만 잡는다.
- **원문 뉘앙스:** "프로젝트 스캐폴딩 계획을 세워" — 따라서 결과물은 **계획 문서 1건**이며, 실제 스캐폴딩은 사용자 승인 후 별도 턴에서 수행한다.
- **의도 보존:** 기능 코드 0줄이어도 `Xcode 16` 에서 빌드·실행되어야 하고, [PLAN.md §4.1](../PLAN.md) 구조와 `app.mdirx.mac` 번들 ID, macOS 15+ 타깃, Swift 6 strict concurrency 가 켜진 상태여야 한다.

## 개요

Xcode 16 기반 macOS 앱 타깃 하나(`MdirX`)와 Swift 6 strict concurrency, SwiftData `ModelContainer`, [PLAN.md §4.1](../PLAN.md)의 디렉터리 구조 골격, 그리고 Swift Testing / XCUITest 두 개의 테스트 타깃을 갖춘 **빈 실행 가능한 SwiftUI 앱**을 만든다. 화면은 "MdirX" 라벨이 들어간 빈 윈도우 한 개. 이 위에서 [0516-1642-dualpane-shell.done.md](0516-1642-dualpane-shell.done.md) 류 후속 계획들이 곧장 View·ViewModel 파일을 추가할 수 있어야 한다.

## 요구사항

### 결과물
- **빌드 시스템**: Xcode 16 프로젝트 `MdirX.xcodeproj` (워크스페이스 없음). SwiftPM 패키지 분리는 후속.
- **앱 타깃**: `MdirX`
  - Bundle ID: `app.mdirx.mac`
  - Deployment Target: macOS 15.0
  - Architectures: Universal (arm64 + x86_64)
  - Sandbox: **OFF** (`com.apple.security.app-sandbox = NO`, 엔타이틀먼트 파일 포함하되 sandbox 키 NO)
  - Hardened Runtime: ON (Notarization 대비)
  - Swift Language Version: 6, `SWIFT_STRICT_CONCURRENCY = complete`
  - SwiftUI App lifecycle (`@main MdirXApp`)
- **테스트 타깃**:
  - `MdirXTests` — Swift Testing
  - `MdirXUITests` — XCUITest (빈 launch 테스트 1개)
- **디렉터리 구조**: [PLAN.md §4.1](../PLAN.md) 트리를 **빈 폴더 + `.gitkeep`**(또는 placeholder Swift 파일) 로 사전 배치. 최소한 `App/`, `Features/`, `Core/`, `DesignSystem/`, `PlatformBridge/`, `Resources/`, `Tests/` 7개 루트 폴더는 만든다.
- **리소스**: `Assets.xcassets` (AppIcon set 비워두기 OK), `Localization/en.lproj/Localizable.strings` 빈 파일, `ko.lproj/Localizable.strings` 빈 파일.
- **SwiftData**: `Core/Persistence/ModelContainer.swift` — 빈 `Schema([])` 기반 `ModelContainer` 부트스트랩 함수만 (모델은 후속 계획에서 추가). 앱 진입점에서 호출은 하지 않거나 try/await 컴파일만 통과시킨다.

### 동작
- `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` **0 warning / 0 error**.
- Xcode 16 GUI 에서 `Run` 시 빈 윈도우 ("MdirX" 텍스트만 표시) 가 뜬다.
- `xcodebuild test -scheme MdirX -destination 'platform=macOS'` — 기본 1개 테스트 케이스(예: `#expect(true)`) 통과.
- `swift -version`, `xcodebuild -version` 둘 다 README 또는 PLAN 의 가정과 일치하는지 README 코멘트로 기록.

### 비범위
- 실제 듀얼 패널 UI, FS actor, 단축키 처리, 키맵 — 모두 **후속 계획**([0516-1642-dualpane-shell.done.md](0516-1642-dualpane-shell.done.md) 참고: 셸 완료 후 M1 본선) 에서 다룸.
- SwiftPM 모듈 분리, CI(GitHub Actions), Notarization 자동화 — Phase 2 이후.
- App Icon 디자인.

## 수도 코드

```
SCAFFOLD STEPS (사용자 승인 후 실행):

1. Xcode 16 으로 신규 macOS App 프로젝트 생성 (또는 xcodegen / 수동 .pbxproj)
   - Product Name: MdirX
   - Organization Identifier: app.mdirx (→ Bundle ID app.mdirx.mac)
   - Interface: SwiftUI, Language: Swift, Tests: ON

2. Build Settings 조정
   - MACOSX_DEPLOYMENT_TARGET = 15.0
   - SWIFT_VERSION = 6.0
   - SWIFT_STRICT_CONCURRENCY = complete
   - ENABLE_HARDENED_RUNTIME = YES
   - CODE_SIGN_ENTITLEMENTS = MdirX/MdirX.entitlements

3. Entitlements
   - com.apple.security.app-sandbox = NO
   - (나머지 키 없음; Full Disk Access 안내는 후속)

4. 폴더 트리 생성 (Finder + Xcode group)
   App/, Features/{DualPane,Pane,FolderTree,Sidebar,AddressBar,Favorites,
        Search,Rename,Archive,QuickLook,Settings}/,
   Core/{FileSystem,Archive,Indexing,Thumbnails,Watching,Persistence/Models}/,
   DesignSystem/{Themes}/, PlatformBridge/, Resources/Localization/{ko,en}.lproj/,
   Tests/{UnitTests,UITests}/
   각 폴더에 .gitkeep 또는 // intentionally empty placeholder

5. 최소 코드
   - App/MdirXApp.swift: @main, WindowGroup { ContentView() }
   - App/ContentView.swift: VStack { Text("MdirX") } .frame(min 800x500)
   - Core/Persistence/ModelContainer.swift: makeContainer() throws -> ModelContainer

6. 테스트
   - MdirXTests/SmokeTests.swift: @Test func appBuilds() { #expect(true) }
   - MdirXUITests/LaunchTests.swift: app.launch() 후 윈도우 존재 확인

7. 검증
   - xcodebuild build (0 warning)
   - xcodebuild test
   - Xcode Run → 빈 윈도우 표시

8. 커밋: "M1: project scaffolding"
```

## 아키텍처

- **App 엔트리**: `MdirXApp.swift` (`@main`) — `WindowGroup` 1개, 최소 사이즈 800x500, ContentView 호스팅.
- **ContentView**: 임시 placeholder. 후속 계획에서 `DualPaneView` 로 교체.
- **ModelContainer 부트스트랩**: `Core/Persistence/ModelContainer.swift` 가 SwiftData `ModelContainer` 팩토리 제공. 이 단계에선 빈 Schema. 앱 진입점에서 `.modelContainer(...)` 부착은 후속 계획에서.
- **외부 의존성**: 없음 (표준 라이브러리·SwiftUI·SwiftData 만).
- **PLAN.md §4.1 디렉터리**: 모든 폴더를 미리 만들어, 후속 PR 들이 디렉터리 신설 노이즈 없이 파일만 추가.

## 통과 조건

- [x] `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` — **error 0**; Swift/Clang 컴파일 경고 0. (도구 `appintentsmetadataprocessor` 가 AppIntents 미사용 시 informational `warning:` 한 줄을 로그에 남길 수 있음 — 본 레포 범위 밖.)
- [x] `xcodebuild test -scheme MdirX -destination 'platform=macOS'` 통과 (Smoke 1개 + Launch 1개).
- [ ] Xcode GUI 에서 `Run` 시 "MdirX" 라벨이 보이는 빈 윈도우가 즉시 뜬다 — **사용자 확인**.
- [x] Bundle ID = `app.mdirx.mac`, Deployment Target = `15.0`, Swift = `6.0`, Strict Concurrency = `complete` — `MdirX.xcodeproj/project.pbxproj`.
- [x] Sandbox OFF — `MdirX/MdirX.entitlements` 에 `com.apple.security.app-sandbox = NO`.
- [x] [PLAN.md §4.1](../PLAN.md) 트리의 모든 1차 폴더가 저장소에 존재 (`.gitkeep` 또는 placeholder Swift).
- [x] `README.md` 를 "M1 진행 중 — 빌드 가능" 톤으로 갱신.
- [ ] **사용자 OK** 받은 뒤 본 문서·파일명을 `done` 으로 바꿀 것.

## 구현 체크리스트

- [x] Xcode macOS App 프로젝트 (`MdirX.xcodeproj`, `scripts/gen_xcode_pbx.py` 생성)
- [x] Bundle ID / Deployment Target / Swift 6 strict concurrency / Hardened Runtime 설정
- [x] `MdirX.entitlements` 작성 (sandbox OFF)
- [x] [PLAN.md §4.1](../PLAN.md) 디렉터리 트리 생성 + `.gitkeep`
- [x] `MdirXApp.swift`, `ContentView.swift` 작성 (placeholder)
- [x] `Core/Persistence/ModelContainer.swift` 빈 Schema 팩토리
- [x] `Resources/Localization/{en,ko}.lproj/Localizable.strings` 빈 파일
- [x] `Assets.xcassets` 생성 (AppIcon set 빈 상태)
- [x] `Tests/UnitTests/SmokeTests.swift` (Swift Testing)
- [x] `Tests/UITests/LaunchTests.swift` (XCUITest)
- [x] `.gitignore` 보강 (DerivedData, xcuserdata, *.xcuserstate 등)
- [x] `xcodebuild build` / `xcodebuild test` 통과
- [x] `README.md` 상태 배지·구조 섹션 갱신
- [x] `.plan/STATUS.md` · [PLAN.md §10](../PLAN.md) 동기화
- [ ] 커밋: 사용자 요청 시 `chore(scaffold): bootstrap MdirX Xcode project (M1)` (또는 동등 메시지)

## 테스트 케이스

- **정상**: Xcode 16 `Run` → 윈도우 1개·타이틀 "MdirX"·중앙에 "MdirX" 텍스트 표시. `xcodebuild test` 0 failure.
- **엣지**:
  - 클린 빌드 (DerivedData 삭제 후 `xcodebuild clean build`) 도 동일하게 통과.
  - macOS 26 Tahoe 머신에서도 빌드·실행 OK (Liquid Glass 회귀 없음).
  - Apple Silicon / Intel 둘 다 Universal 바이너리로 산출.
- **에러**:
  - Swift 6 strict concurrency 위반 경고가 나오면 placeholder 코드를 `@MainActor` 한정으로 명시해 0 warning 유지.
  - Notarization 은 이 단계 범위 밖 — 서명 실패는 통과 조건 아님(로컬 dev sign 만).

---

**상태:** `done` — 2026-05-16 16:38 사용자 OK. 빌드·테스트 통과, GUI Run 확인, 커밋 완료.
