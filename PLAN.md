# MdirX — 계획 문서

> NexusFile 호환 클론. macOS 15 Sequoia+, SwiftUI/Swift 6 네이티브, 비샌드박스.
> "Mdir, reborn on macOS."

---

## 0. 프로젝트 메타

| 항목 | 값 |
|---|---|
| 앱 표시 이름 | MdirX |
| Repo 이름 | `mdirx` |
| 번들 ID | `app.mdirx.mac` |
| 작업 디렉터리 | `/Users/rollcake/lab/mdirx` |
| 라이선스 | **MIT** |
| 최소 macOS | 15.0 Sequoia |
| 권장 macOS | 26 Tahoe (Liquid Glass 대응 옵션) |
| 빌드 | Xcode 16 + SwiftPM |
| 언어 | Swift 6 (strict concurrency) |
| UI 프레임워크 | SwiftUI 우선, AppKit interop |
| 배포 | Developer ID + Notarization, 직접 배포 (App Store 미지원) |

---

## 1. 확정 결정사항

- ✅ **호환 클론**: NexusFile 상표·코드 미사용. 기능/UX 호환만.
- ✅ **비샌드박스**: Finder 수준 자유도 우선. App Store 포기.
- ✅ **최소 macOS 15**.
- ✅ **압축**: ZIP만 (AppleArchive). 7z/rar/tar.gz 제외.
- ✅ **FTP/SFTP 제외**. 차기 버전에서 재검토.
- ✅ **Swift 6 + SwiftUI**, AppKit은 `NSViewRepresentable`로만 사용.
- ✅ **상태 관리**: `@Observable` (Observation 프레임워크).
- ✅ **영속화**: SwiftData.
- ✅ **FS 작업**: actor 격리, `@MainActor` UI.
- ✅ **패널별 독립 탭은 최후 단계로 후순위**: 다른 모든 Phase 1~3 기능 완료 후 도입. 1.0 은 패널당 단일 경로로 도달.

---

## 2. 기능 스코프

### Phase 1 — Core (M1~M2)
- 단일/듀얼 패널 토글
- 폴더 트리 사이드바
- 주소표시줄 + 경로 히스토리 드롭다운
- 파일 작업: 복사·이동·붙여넣기·이름변경·새폴더
- 3단계 삭제: 휴지통 / 완전삭제 / 0-덮어쓰기
- 선택: 전체·역선택·패턴(글롭/정규식)
- 키보드 네비게이션 (Vim-like + macOS 표준 동시 지원)
- 작업폴더(워킹 디렉터리) 지정
- 폴더 점프 다이얼로그 (F10) — NCD/MCD 스타일 퍼지 검색
- 즐겨찾기 (F11)
- 고급 이름변경 (⇧⌥R) — 패턴·정규식·번호·대소문자
- 폴더 내 검색 (⌘F) + Spotlight 글로벌 검색

### Phase 2 — Power (M3~M4)
- ZIP 압축/해제 (⌘E), 지능형 해제 (⌥Q)
- 아카이브 내부 탐색 (가상 폴더처럼)
- QuickLook 미리보기 (Space)
- FSEvents 실시간 갱신
- 사용자 정의 함수키 (F1~F12)
- 경로 복사 옵션: 전체경로·파일명·폴더경로
- 심볼릭 링크 표시·해석
- 스킨/테마 (라이트/다크 + 컬러 토큰 커스텀)
- 설정 영속화·import/export

### Phase 3 — macOS 통합 (M5 이후)
- Finder 태그 통합
- iCloud Drive 인식 표시
- AppleScript / Shortcuts 지원
- 서비스 메뉴 등록

### Phase 4 — Last (모든 기능 완료 후)
- 패널별 독립 탭 (`⌘T`/`⌘W`/`⌃Tab`) — `PaneSnapshot.tabsJSON` 직렬화 포함

---

## 3. 단축키 매핑 (NexusFile → MdirX)

> 원칙: NexusFile 단축키를 1차로 두되, macOS 관용 매핑도 동시에 바인딩. 사용자 커스터마이즈 가능.

| 기능 | NexusFile (Win) | MdirX (mac) 기본 | macOS 보조 |
|---|---|---|---|
| 복사 | Ctrl+C | ⌘C | — |
| 잘라내기(이동) | Ctrl+X | ⌘X | — |
| 붙여넣기 | Ctrl+V | ⌘V | — |
| 즉시 복사 | Alt+C | ⌥C | — |
| 즉시 이동 | Alt+M | ⌥M | — |
| 휴지통 삭제 | Del | ⌫ / ⌘⌫ | — |
| 완전 삭제 | Shift+Del | ⇧⌘⌫ | — |
| 0-덮어쓰기 삭제 | (별도 메뉴) | ⌃⇧⌘⌫ | — |
| 새 폴더 | F7 | ⌘⇧N | F7 |
| 이름 변경 | F2 | ↩ (Finder식) | F2 |
| 고급 이름 변경 | Shift+Alt+R | ⇧⌥R | — |
| 폴더 트리 점프 | F10 | F10 | ⌘T 보조 |
| 즐겨찾기 | F11 | F11 | ⌘D 보조 |
| 단축키 도움말 | F12 | F12 | ⌘? 보조 |
| 폴더 내 검색 | Ctrl+F | ⌘F | — |
| Spotlight 검색 | — | ⌘⇧F | — |
| 압축 해제 | Ctrl+E | ⌘E | — |
| 지능형 해제 | Alt+Q | ⌥Q | — |
| 전체 선택 토글 | Alt+U | ⌥U | ⌘A |
| 선택 토글 (현재 행) | Space | Space | — |
| 선택 해제 | — | Esc | — |
| 범위 선택 (마우스) | Shift+클릭 | Shift+클릭 | — |
| 단일 토글 (마우스) | Ctrl+클릭 | ⌘+클릭 | — |
| QuickLook | — | ⌘Y | — |
| 패널 교체 | Tab | Tab | — |
| 다른 패널로 복사 | F5 | F5 | — |
| 다른 패널로 이동 | F6 | F6 | — |
| 새 탭 (Phase 4) | Ctrl+T | ⌘T | — |
| 탭 닫기 (Phase 4) | Ctrl+W | ⌘W | — |
| 다음 탭 (Phase 4) | Ctrl+Tab | ⌃Tab | — |
| 듀얼/단일 토글 | — | ⌘\\ | — |
| 환경설정 | — | ⌘, | — |

---

## 4. 아키텍처

### 4.1 디렉터리 구조
```
mdirx/
├── App/
│   ├── MdirXApp.swift            # @main, Commands
│   ├── AppDelegate.swift         # AppKit hooks
│   └── Commands/                 # menu/keyboard commands
├── Features/
│   ├── DualPane/
│   │   ├── DualPaneView.swift
│   │   └── DualPaneViewModel.swift
│   ├── Pane/
│   │   ├── PaneView.swift
│   │   ├── PaneTabsView.swift
│   │   ├── FileListView.swift
│   │   └── PaneViewModel.swift
│   ├── FolderTree/               # F10 점프
│   ├── Sidebar/                  # 좌측 폴더 트리
│   ├── AddressBar/
│   ├── Favorites/                # F11
│   ├── Search/
│   ├── Rename/                   # 고급 이름변경
│   ├── Archive/                  # ZIP
│   ├── QuickLook/
│   └── Settings/
├── Core/
│   ├── FileSystem/
│   │   ├── FileSystemActor.swift
│   │   ├── FileOperation.swift   # Copy/Move/Delete enum
│   │   ├── OperationQueue.swift  # progress, cancel
│   │   └── Permissions.swift
│   ├── Archive/
│   │   └── ZipService.swift      # AppleArchive
│   ├── Indexing/
│   │   └── SpotlightQuery.swift  # NSMetadataQuery
│   ├── Thumbnails/
│   │   └── ThumbnailCache.swift  # QLThumbnailGenerator + LRU
│   ├── Watching/
│   │   └── FSEventsMonitor.swift
│   └── Persistence/
│       ├── Models/
│       │   ├── Favorite.swift
│       │   ├── PathHistory.swift
│       │   ├── FunctionKey.swift
│       │   └── Theme.swift
│       └── ModelContainer.swift
├── DesignSystem/
│   ├── Tokens.swift              # 컬러/타이포/스페이싱
│   ├── Icons.swift               # SF Symbols + 커스텀
│   └── Themes/                   # 라이트/다크/커스텀
├── PlatformBridge/
│   ├── QuickLookPanel.swift      # QLPreviewPanel NSViewRep
│   ├── ServicesIntegration.swift
│   └── DragDrop.swift
├── Resources/
│   ├── Localization/
│   │   ├── ko.lproj/
│   │   └── en.lproj/
│   └── Assets.xcassets
└── Tests/
    ├── UnitTests/                # Swift Testing
    └── UITests/                  # XCUITest
```

### 4.2 동시성 모델
- `FileSystemActor`: 모든 FS read/write 직렬화. cancellation 지원.
- `OperationQueue`: 큰 작업(복사/압축)을 progress 토큰과 함께 추적.
- UI는 모두 `@MainActor`. ViewModel은 `@Observable` + `@MainActor`.
- 비동기 결과는 `AsyncStream`으로 UI에 흘림.

### 4.3 상태 관리
- ViewModel = `@Observable` 클래스, SwiftUI가 직접 관찰.
- 글로벌 상태(테마·즐겨찾기·함수키)는 SwiftData `ModelContainer`에서 직접 조회 + `@Environment` 주입.
- URL은 `URL` 그대로 + Security-Scoped Bookmark 데이터를 SwiftData에 보관.

---

## 5. 데이터 모델 (SwiftData)

```swift
@Model final class Favorite {
    var name: String
    var bookmarkData: Data         // Security-scoped
    var sortOrder: Int
    var createdAt: Date
}

@Model final class PathHistoryEntry {
    var path: String
    var visitedAt: Date
    var paneID: UUID?              // 어느 패널에서 방문했는지
}

@Model final class FunctionKeyBinding {
    var key: Int                   // 1...12
    var command: String            // 명령 ID
    var modifiers: Int             // bitmask
}

@Model final class ThemeProfile {
    var name: String
    var isBuiltin: Bool
    var tokensJSON: String         // 직렬화된 디자인 토큰
}

@Model final class PaneSnapshot {
    var paneSlot: Int              // 0(좌) / 1(우)
    var tabsJSON: String           // 탭별 경로/스크롤/선택
    var activeTabIndex: Int
}
```

---

## 6. UI 레이아웃 스케치

```
┌──────────────────────────────────────────────────────────────────┐
│ Toolbar: [< >] [⟳] [Address Bar........................] [⚙][🌓]│
├────────┬─────────────────────────────┬───────────────────────────┤
│        │ Tabs: [Home][Docs+][Dl]    │ Tabs: [Work][Tmp+]        │
│Sidebar ├─────────────────────────────┼───────────────────────────┤
│        │ Name  Size  Modified  Kind │ Name  Size  Modified  Kind│
│ ▾ Fav  │ ─────────────────────────  │ ─────────────────────────  │
│  📁 A  │ 📁 ProjectA                │ 📄 notes.md               │
│  📁 B  │ 📁 ProjectB                │ 📄 todo.txt               │
│ ▾ Vol  │ 📄 readme.md               │ 📁 archive/                │
│  💾 SSD│ ...                         │ ...                        │
│        │                             │                            │
├────────┴─────────────────────────────┴───────────────────────────┤
│ Status: 12 items, 3 selected • 2.4 GB • ⌘F search ▌            │
└──────────────────────────────────────────────────────────────────┘
```
- 좌측 사이드바: 즐겨찾기·iCloud·외장 볼륨·태그
- 중앙·우측: 듀얼 패널 (각 패널 = 단일 디렉터리 뷰; 탭 그룹은 Phase 4)
- 하단: 상태바 + 진행 중 작업 표시
- F10 누르면 폴더 점프 모달이 떠서 퍼지 검색으로 트리 탐색

---

## 7. 키 디자인 결정

1. **NCD/MCD 트리(F10)는 모달 오버레이로 구현**
   네이티브 사이드바 트리와 별개로, 키보드 only 점프 다이얼로그.
   - 타이핑 → 퍼지 매칭 하이라이트
   - ↑↓ 이동, Enter 진입
2. **고급 이름변경은 Live Preview 표 + 정규식 그룹 캡처 지원**
3. **함수키는 명령 팔레트(⌘⇧P)와 동일한 명령 카탈로그를 공유**
   → 키 바인딩 = 명령 ID 매핑 한 줄
4. **압축 해제는 항상 백그라운드 큐**, 진행률 상태바 표시
5. **0-덮어쓰기 삭제는 확인 다이얼로그 + "다시 묻지 않기"**

---

## 8. 리스크 & 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| 비샌드박스 권한 — Full Disk Access 필요 시 사용자 안내 | M | 첫 실행 온보딩에 명시 + 시스템 설정 딥링크 |
| Swift 6 strict concurrency 학습 비용 | M | M1 초기에 동시성 패턴 가이드 작성 |
| SwiftUI List 대용량(수만 개) 성능 | H | `LazyVStack` + 가상화, 필요 시 `NSTableView` interop fallback |
| NexusFile 사용자 키맵 기대치 | M | 초기 마이그레이션 가이드 + 키맵 프리셋 제공 |
| Notarization 첫 진행 | L | M5 베타 전 미리 테스트 통과 |

---

## 9. 마일스톤 (재정의)

| 마일스톤 | 기간 | 산출물 |
|---|---|---|
| M1 | 2주 | 듀얼 패널·기본 FS 작업·키보드 네비게이션, FS actor, ViewModel 기반 잡힘 (탭은 Phase 4) |
| M2 | 2주 | F10 점프·F11 즐겨찾기·고급 이름변경·검색·주소표시줄 히스토리 |
| M3 | 2주 | ZIP 압축/해제·QuickLook·FSEvents·함수키 카탈로그·명령 팔레트 |
| M4 | 1.5주 | 스킨/테마·환경설정·설정 영속화·import/export |
| M5 | 1주 | 베타·서명·공증·DMG 배포 채널 |

총 ~8.5주 단독 풀타임 기준 추정. 파트타임이면 ×2~3.

---

## 10. 다음 액션

- [x] 라이선스: **MIT** 확정
- [x] 작업 디렉터리: **`mdirx`** 로 반영됨
- [x] Xcode 16: 설치·사용 가능 확인됨
- [x] M1 킥오프 — 프로젝트 스캐폴딩 (`MdirX.xcodeproj` 빌드·테스트 통과; 세부는 [.plan/0516-1628-project-scaffolding.done.md](.plan/0516-1628-project-scaffolding.done.md))
