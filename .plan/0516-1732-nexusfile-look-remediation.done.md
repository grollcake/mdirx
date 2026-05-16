> **⚠️ ABANDONED (2026-05-16 18:55)** — 본 계획은 **폐기**한다.
>
> **사유:** 실제 구현 결과가 명세와 크게 어긋남(`.plan/MdirX Current.png` 캡처로 확인). 9컬럼이 7컬럼으로 줄어 Attrs·Description 누락, 시간이 24h 가 아닌 한국식 "오전/오후 …", Name 컬럼 내용 좌측이 잘려 표시, 볼륨 행이 단순 텍스트로만 들어가 capsule + "남음" 표시 빠짐. "구현 후 기록"에서 UI 테스트가 LocalAuthentication 오류로 진입 못 한 채 종료된 점도 검증 미흡. 본 doc 의 사양은 **참고용으로만** 보존하고, 후속 [0516-1855-nexus-look-exact.todo.md](0516-1855-nexus-look-exact.todo.md) 가 새 통과 조건과 함께 다시 진행한다.
>
> 파일명 `.done.md` 는 README 의 "사용자 OK 후 done" 정의와 충돌하나, 사용자 지시(2026-05-16)에 따라 **폐기 보관용 컨벤션**으로 사용한다.

---

# NexusFile 룩앤필 — 누락 항목 보완 (remediation) <s>(폐기)</s>

## 사용자 요구 (정제)

- **정제:** 직전 [0516-1710-pane-list-nexusfile-look.done.md](0516-1710-pane-list-nexusfile-look.done.md) 가 `done` 으로 보고됐으나 데이터·상수 인프라(`DirectoryEntry` 새 필드, `Core/Volumes/VolumeService.swift`, `DesignSystem/Tokens.swift`)만 들어가고 **UI 레이어가 그 자료를 소비하지 않은** 상태. 본 계획은 UI 부분을 캡처와 픽셀·색·폰트 수준으로 일치하도록 완성한다. 구현 에이전트가 명세를 누락하는 사례가 잦으므로 **모든 시각 요소를 수치로 못박는다.**
- **원문 뉘앙스:** "룩앤필은 아주 구체적으로 요건을 적어. 통과 조건도 구체화 해."
- **의도 보존:** 데이터·상수는 이미 들어간 그대로 활용. 신규 데이터 모델·서비스는 만들지 않음 — **와이어업과 시각 사양 적용만**.

## 개요

`Features/Pane/` 의 기존 View 4개(`PaneColumnView`·`FileListView`·`PaneStatusBar`·`PaneSummaryView`)를 갱신하고 신규 4개(`PaneHeaderView`·`BreadcrumbView`·`VolumeBadgeView`·`PaneRow`)를 생성한다. `PaneState` 에 `mountedVolumes` 필드 추가, `load()` 끝에서 `VolumeService.mountedVolumes()` 호출. `MdirXApp` 의 `WindowGroup` 에 `.preferredColorScheme(.dark)` 강제. 모든 색·폰트·여백·테두리는 아래 §"시각 사양" 의 표를 그대로 따른다.

---

## 시각 사양 — **수치 명세 (이대로 적용 필수)**

### S0. 전역
| 항목 | 값 |
|---|---|
| 컬러 스킴 | **다크 강제** — `.preferredColorScheme(.dark)` |
| 윈도우 기본 사이즈 | **1000 × 600** (변경 없음) |
| 윈도우 최소 사이즈 | **800 × 500** (변경 없음) |
| 패널 배경 | `Color(white: 0.07)` (= `FileColorToken.panelBackground`) — VStack 전체에 `.background()` |
| 외곽 모서리 라운드 | `cornerRadius: 4` |

### S1. 활성·비활성 패널 외곽 stroke
| 패널 상태 | 색 | 두께 |
|---|---|---|
| 활성 (`isActive == true`) | `Color.accentColor` | **2 pt** |
| 비활성 | `Color.white.opacity(0.15)` | **1 pt** |
- `.overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(...) }` 로 적용.

### S2. 패널 헤더 — `PaneHeaderView`
- **높이**: `28 pt` 고정.
- **배경**: 패널 배경과 동일(투명).
- **하단 1pt 구분선**: `Color.white.opacity(0.08)`.
- **레이아웃**: `HStack(spacing: 8) { BreadcrumbView · Spacer · VolumeBadgeView }`, 좌우 padding `8 pt`, 수직 중앙 정렬.

### S3. 브레드크럼 — `BreadcrumbView`
- **세그먼트 분해**: `currentURL` 을 path 컴포넌트로 분해. 루트(`/`) 는 마운트 볼륨 라벨로 치환:
  - `currentURL` 이 어떤 마운트 볼륨의 하위면, 그 볼륨 라벨로 첫 세그먼트 표기 (예: `Macintosh HD › Users › rollcake`).
  - 그 외에는 `/` → `'/'` 로 표시 후 `Users`, `rollcake` 식.
- **세그먼트 스타일** (각 1개):
  - `Button(.plain) { onTap(segment.url) } label: { Text(segment.label) }`
  - 폰트: `.system(size: 13, weight: .regular)`
  - 색: leaf 가 아니면 `Color(white: 0.78)`, leaf(가장 마지막) 이면 `Color(white: 0.95)`
  - hover: SwiftUI 표준 hover 효과 가용 시 underline + 밝기 +10% 으로(불가하면 미적용 OK)
- **세그먼트 사이 구분자**: `Text("›")` (U+203A), 색 `Color(white: 0.45)`, 좌우 padding 각 `4 pt`.
- **컨테이너**: `ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { … } }` — 가로 오버플로 시 스크롤.
- **세그먼트 클릭 동작**: `onTap(segment.url)` → `DualPaneView` 가 `pane.currentURL = url; Task { await pane.load(via: fs) }`.

### S4. 드라이브 배지 — `VolumeBadgeView`
- **현재 볼륨 lookup**: `VolumeService.freeSpace(forVolumeContaining: currentURL)` 1회 호출. `nil` 이면 전체 미표시.
- **라벨 lookup**: `VolumeService.mountedVolumes()` 중 `currentURL` 의 prefix 가 가장 긴 항목의 `.name`. 못 찾으면 `currentURL.pathComponents` 의 첫 컴포넌트.
- **레이아웃**: `HStack(spacing: 6)`:
  1. `Text(volumeName)` — 폰트 `.system(size: 12)`, 색 `Color(white: 0.78)`
  2. **Capsule bar**:
     - 외곽 `Capsule().fill(Color.white.opacity(0.18))` — **width: 60, height: 6**
     - 내부 `Capsule().fill(Color.white.opacity(0.55))` — width: `60 × (1 - freeRatio)` (= 사용량 비율). `freeRatio = free / total`.
     - 정렬: `.overlay(alignment: .leading)`.
  3. `Text("\(humanFree) 남음")` — 폰트 `.system(size: 12).monospacedDigit()`, 색 `Color(white: 0.78)`
     - `humanFree = ByteCountFormatter().string(fromByteCount: free)` (countStyle `.file`, allowedUnits `[.useGB, .useTB, .useMB]`)

### S5. 요약 줄 — `PaneSummaryView`
- **높이**: `24 pt`
- **배경**: 투명
- **하단 1pt 구분선**: `Color.white.opacity(0.05)`
- **좌측 padding**: `12 pt`
- **텍스트** (selection 비어 있을 때):
  - 포맷: `"\(folderCount) 폴더, \(fileCount) 파일 (\(sizeString))"`
  - `folderCount`/`fileCount` 는 `..` 와 마운트 볼륨 행 **제외** (`isParentLink` / `isMountedVolume` 플래그 검사).
  - `sizeString` = 파일들의 합을 `ByteCountFormatter(.file)`.
  - 폰트 `.system(size: 12)`, 색 `Color(white: 0.62)`.
- **텍스트** (selection 1개 이상):
  - 포맷: `"선택정보: \(selection.count) 항목 (총 \(humanSelectionSize))"`
  - `humanSelectionSize` = selection 의 file size 합을 `ByteCountFormatter(.file)`. 폴더는 0 으로 계산.
  - 폰트 동일, **색 `Color.yellow`**.

### S6. 본문 Table — 컬럼 정의 (정확 9컬럼, 순서 고정)

| # | 헤더 텍스트 | 폭(pt) | 정렬 | 폰트 | 색 |
|---|---|---|---|---|---|
| 1 | `#` | **32 고정** | trailing | `.system(size: 12).monospacedDigit()` | `Color(white: 0.45)` |
| 2 | `` (빈 헤더) | **22 고정** | center | SF Symbol size 13 | `FileColorToken.color(for: row)` |
| 3 | `Name` | min 120, ideal 200, flexible | leading | `.system(size: 13, weight: .regular)` | `FileColorToken.color(for: row)` |
| 4 | `Ext` | **56 고정** | leading | `.system(size: 13)` | `FileColorToken.color(for: row)` |
| 5 | `Size` | **80 고정** | trailing | `.system(size: 12).monospacedDigit()` | `Color(white: 0.85)` (파일), `Color(white: 0.45)` (`[DIR]`/볼륨 빈칸) |
| 6 | `Date` | **90 고정** | leading | `.system(size: 12).monospacedDigit()` | `Color(white: 0.7)` |
| 7 | `Time` | **56 고정** | leading | `.system(size: 12).monospacedDigit()` | `Color(white: 0.7)` |
| 8 | `Attrs` | **48 고정** | leading | `.system(size: 12).monospaced()` | `Color(white: 0.55)` |
| 9 | `Description` | min 100, flexible | leading | `.system(size: 12)` | `FileColorToken.color(for: row)` |

- **행 높이**: 기본(`Table` 의 system default) — 별도 지정 없음.
- **행 배경 (cursor)**:
  - 활성 패널의 cursor 행: `FileColorToken.selectionActiveBackground` (= `Color.yellow.opacity(0.25)`).
  - 비활성 패널의 cursor 행: `FileColorToken.selectionInactiveBackground` (= `Color.gray.opacity(0.15)`).
- **선택 강조 구현**: `Table(state.paneRows, selection: cursorBinding)` 의 `.tint(.yellow)` 시도. 효과 없으면 **fallback**: 각 row 의 컨테이너에 `.background(cursorBackground(for: row))` 오버레이. 어느 길을 선택했는지 본 문서 끝 "구현 후 기록" 에 적는다.

### S7. 컬럼별 값 포맷

| row 종류 | `#` | icon | Name | Ext | Size | Date | Time | Attrs | Description |
|---|---|---|---|---|---|---|---|---|---|
| 파일 | rowNumber | SF Symbol(아래 §S8) | `entry.displayName` | `entry.ext` | `ByteCountFormatter(.file)` 결과 | `entry.relativeOrCalendarDate()` | `entry.modificationDate → HH:mm` (`.dateTime.hour().minute()`) | `entry.attrsFourCharacter` | `entry.kindDescription` |
| 폴더 | rowNumber | `folder.fill` | `entry.displayName` | `""` (빈문자) | `""` (빈문자) | 위와 동일 | 위와 동일 | `entry.attrsFourCharacter` | `entry.kindDescription` |
| `..` 부모 | rowNumber | `arrow.turn.left.up` | `..` | `""` | `""` | 위와 동일 | 위와 동일 | `____` | `상위 디렉터리` |
| 볼륨 | rowNumber | §S8 매핑 | `volume.name` | `[드라이브]` | `""` (size 자리 비움) | `""` | `""` | `____` | **인라인 capsule + `〈humanFree〉 남음`** (§S9) |

`humanFree` 포맷 = §S4 와 동일.

### S8. 아이콘 매핑 (정확)
- 폴더: `folder.fill` — `FileColorToken.folder` 색
- `..` 부모: `arrow.turn.left.up` — `FileColorToken.folder` 색
- 파일 ext 별 (lowercased ext 기준; UTI 매핑은 부가 — 일치 안 하면 ext 우선):
  - `md`, `txt`, `rtf` → `doc.text` · `FileColorToken.document` (= `Color.primary`)
  - `xlsx`, `xls`, `csv` → `tablecells` · `FileColorToken.spreadsheet`
  - `png`, `jpg`, `jpeg`, `gif`, `heic`, `webp` → `photo` · `FileColorToken.image`
  - `swift`, `py`, `ts`, `tsx`, `js`, `jsx`, `rs`, `go`, `c`, `h`, `cpp`, `hpp` → `chevron.left.forwardslash.chevron.right` · `FileColorToken.code`
  - `zip`, `tar`, `gz`, `tgz`, `bz2`, `xz`, `7z` → `archivebox` · `FileColorToken.archive`
  - `mp4`, `mov`, `m4v`, `mp3`, `wav`, `aac`, `flac` → `play.rectangle` · `FileColorToken.media`
  - `iso`, `dmg` → `opticaldisc` · `FileColorToken.diskImage`
  - 그 외 → `doc` · `Color.primary`
- 볼륨 IconKind 별:
  - `.internalDrive` → `internaldrive.fill` · `Color(white: 0.85)`
  - `.external` → `externaldrive.fill` · `Color(white: 0.85)`
  - `.network` → `network` · `Color(white: 0.85)`
  - `.cloud` → `icloud.fill` · `Color(white: 0.85)`
- 아이콘 폰트 크기: `.font(.system(size: 13))`

### S9. 볼륨 행 Description 컬럼 콘텐츠
- `HStack(spacing: 6) { Capsule(width 60×6, 사용량 fill), Text("\(humanFree) 남음") }`
- Capsule 색은 §S4 와 동일.
- Text 폰트 `.system(size: 12).monospacedDigit()`, 색 `Color(white: 0.78)`.

### S10. 하단 상태바 — `PaneStatusBar`
- **높이**: `24 pt`
- **배경**: `Color.white.opacity(0.05)`
- **상단 1pt 구분선**: `Color.white.opacity(0.08)`
- **좌측 padding**: `12 pt`
- **폰트**: `.system(size: 12).monospacedDigit()`
- **색**: `Color(white: 0.7)`
- **포맷** (cursor 가 일반 파일일 때):
  - `"\(bytesWithComma) | \(yyyyMMddHHmm) | \(attrs4) | \(fullName)"`
  - 예: `"100,516 | 2026-05-13 21:53 | A___ | (양식) ICT 직무 개인화 명세서 v0.1.xlsx"`
- **포맷** (cursor 가 폴더):
  - `"— | \(yyyyMMddHHmm) | \(attrs4) | \(fullName)"` (size 자리 `—` 만)
- **포맷** (cursor 가 볼륨):
  - `"\(freeWithComma) / \(totalWithComma) | — | ____ | \(volumeName)"`
- **포맷** (cursor 없음 / 빈 디렉터리):
  - `"— | — | ____ | —"`
- **fullName 의 truncation**: `lineLimit(1)` + `truncationMode(.middle)`. 우측까지 확장(`.frame(maxWidth: .infinity, alignment: .leading)`).
- **`|` 구분자 좌우 공백 정확히 1칸씩** (예: ` | ` ).
- 변환 함수:
  - `bytesWithComma`: `NumberFormatter` `.decimal` 그룹화, locale 무관 콤마 사용 — `formatter.groupingSeparator = ","`
  - `yyyyMMddHHmm`: `DateFormatter` `"yyyy-MM-dd HH:mm"`
  - `attrs4`: 그대로 4글자
  - `fullName`: 파일 = `displayName + (ext.isEmpty ? "" : ".\(ext)")`, 볼륨 = `name`, `..` = `..`

---

## 자료 와이어업 변경

### W1. `PaneState`
- 신규 필드: `var mountedVolumes: [MountedVolume] = []`
- `load(via: FileSystemActor) async` 끝에 추가: `self.mountedVolumes = VolumeService.mountedVolumes()`
- 계산 프로퍼티 `paneRows` 신규 (§W2 의 `PaneRow` 사용).

### W2. `Features/Pane/PaneRow.swift` (신규)
```
struct PaneRow: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case file(DirectoryEntry)       // 일반 파일·폴더·.. 모두 여기에
        case volume(MountedVolume)
    }
    let id: URL
    let rowNumber: Int                  // 1-base, 파일 먼저 → 볼륨 이어붙임
    let kind: Kind
}
extension PaneState {
    var paneRows: [PaneRow] {
        let fileRows = entries.enumerated().map { i, e in
            PaneRow(id: e.id, rowNumber: i + 1, kind: .file(e))
        }
        let base = entries.count
        let volRows = mountedVolumes.enumerated().map { i, v in
            PaneRow(id: v.id, rowNumber: base + i + 1, kind: .volume(v))
        }
        return fileRows + volRows
    }
}
```

### W3. `Features/Pane/PaneHeaderView.swift` / `BreadcrumbView.swift` / `VolumeBadgeView.swift` (신규)
- §S2 / §S3 / §S4 사양 그대로 구현.

### W4. `Features/Pane/PaneColumnView.swift`
- 헤더의 `Text(state.currentURL.path)` 블록 삭제.
- `VStack(spacing: 0) { PaneHeaderView · PaneSummaryView · FileListView · PaneStatusBar }` 순서 유지.
- `.background(FileColorToken.panelBackground)` 추가.
- 외곽 stroke 두께·색 §S1 그대로.

### W5. `Features/Pane/FileListView.swift`
- 4컬럼 Table → 9컬럼 Table. `state.entries` → `state.paneRows`.
- 각 컬럼의 폭·정렬·폰트·색 §S6 표 그대로.
- 행 배경(cursor) §S6 끝.

### W6. `Features/Pane/PaneStatusBar.swift`
- 2필드 → §S10 4필드.

### W7. `App/MdirXApp.swift`
- `WindowGroup { DualPaneView() }.defaultSize(width: 1000, height: 600).preferredColorScheme(.dark)`

---

## 비범위
- 다중 선택 ▶ 마커·강조 텍스트 톤 — [0516-1722-multi-selection.todo.md](0516-1722-multi-selection.todo.md).
- `..` 부모 행 합성 자체 — [0516-1728-parent-link-entry.todo.md](0516-1728-parent-link-entry.todo.md). 본 계획은 `..` 행이 들어왔을 때 §S7 표대로 표시만 한다.
- 라이트 모드 지원.
- 정렬 토글·컬럼 너비 사용자 조정·세그먼트 hover 효과.
- 깊은 경로 가운데 truncation(가로 스크롤로 처리).

## 성능·제약
- macOS 15+, Swift 6 strict concurrency 0 warning 유지.
- `VolumeService.mountedVolumes()` 호출은 `load()` 마다 1회.
- 1만 항목 디렉터리에서도 `Table` 가상화로 부드럽게.

---

## 통과 조건 — **구체·측정 가능**

### A. 빌드·테스트
- [ ] `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` 결과: **0 error, 0 Swift/Clang warning** (`grep -ciE "warning:"` == 0).
- [ ] `xcodebuild test` 통과: 신규 + 기존 모두.

### B. 파일 존재 (구조 검증)
- [ ] 다음 파일이 모두 존재:
  - `Features/Pane/PaneHeaderView.swift`
  - `Features/Pane/BreadcrumbView.swift`
  - `Features/Pane/VolumeBadgeView.swift`
  - `Features/Pane/PaneRow.swift`
- [ ] `Features/Pane/PaneColumnView.swift` 에서 `Text(state.currentURL.path)` 문자열 grep 결과 **0건**(헤더가 `PaneHeaderView` 로 교체됨을 확인).
- [ ] `Features/Pane/FileListView.swift` 의 `TableColumn(` 출현 횟수 **정확히 9** (`grep -c "TableColumn(" Features/Pane/FileListView.swift == 9`).
- [ ] `App/MdirXApp.swift` 에 `.preferredColorScheme(.dark)` 문자열 1건 이상.

### C. 색·폰트·치수 직접 검증 (소스 grep)
- [ ] `FileListView.swift` 에 `FileColorToken.color(for:` 호출이 **3건 이상** (Name·Ext·Description 컬럼에 적용 확인).
- [ ] `PaneHeaderView.swift` 에 `height: 28` 문자열 존재.
- [ ] `PaneSummaryView.swift` 에 `height: 24` 또는 `frame(height: 24)` 존재.
- [ ] `PaneStatusBar.swift` 에 `height: 24` 또는 `frame(height: 24)` 존재.
- [ ] `PaneStatusBar.swift` 에 `monospacedDigit` 단어 존재.
- [ ] `PaneStatusBar.swift` 에 `" | "` (공백 포함 파이프) 리터럴 존재.
- [ ] `VolumeBadgeView.swift` 에 `width: 60` 과 `height: 6` 모두 존재 (capsule 바 치수).
- [ ] `BreadcrumbView.swift` 에 `"›"` (U+203A) 리터럴 존재.

### D. 단위 테스트
- [ ] `Tests/UnitTests/PaneRowsTests.swift`
  - 파일 3 + 볼륨 2 → `paneRows.count == 5`, `rowNumber` 가 정확히 1,2,3,4,5.
  - 파일 0 + 볼륨 2 → `paneRows.count == 2`, rowNumber 1·2.
- [ ] `Tests/UnitTests/BreadcrumbBreakdownTests.swift`
  - `/Users/rollcake/lab/mdirx` 분해 → label 배열 끝이 `"mdirx"`, 길이 ≥ 4, 각 세그먼트 URL 이 점점 짧은 prefix.
  - `/` 분해 → label 1개 (`"/"`).
- [ ] `Tests/UnitTests/StatusBarFormatTests.swift`
  - 파일 cursor (size 12345, attrs `A___`, name `foo.txt`, date 2026-05-13 21:53):
    출력 = `"12,345 | 2026-05-13 21:53 | A___ | foo.txt"`
  - 폴더 cursor: 첫 자리 `—`.
  - 볼륨 cursor: 첫 자리 `"\(free) / \(total)"`.
  - cursor 없음: `"— | — | ____ | —"`.

### E. UI 테스트 — `Tests/UITests/NexusLookCompleteTests.swift`
- [ ] 앱 기동 직후 다음 모두 참:
  - `app.staticTexts` 중 텍스트가 `"›"` 인 것이 **양 패널 합 4개 이상** (각 패널 최소 2 세그먼트).
  - `app.staticTexts` 중 텍스트가 `"남음"` 으로 **끝나는** 것이 **2개 이상** (각 패널 헤더의 VolumeBadge).
  - `Table` 컬럼 헤더 텍스트(좌측 패널) 정확히 다음 순서로 보임: `#`, (빈), `Name`, `Ext`, `Size`, `Date`, `Time`, `Attrs`, `Description` — XCUI 의 `app.tables.element(boundBy: 0).cells.firstMatch.children(matching: .staticText)` 등으로 검증 가능 (구현 시 가장 견고한 query 선택).
  - 좌측 패널 Table 의 마지막 행 중 적어도 1개가 Description 에 `"남음"` 포함 (마운트 볼륨 인라인 행).
- [ ] 좌측 패널의 일반 파일 행 1개를 클릭 → 상태바 텍스트가 정규식 `^[\d,]+ \| \d{4}-\d{2}-\d{2} \d{2}:\d{2} \| [A_R_H_S_]{4} \| .+$` 와 매치.
- [ ] 폴더 행 클릭 → 상태바 텍스트가 정규식 `^— \| \d{4}-\d{2}-\d{2} \d{2}:\d{2} \| [A_R_H_S_]{4} \| .+$` 와 매치.
- [ ] 빈 디렉터리(테스트용 `launchEnvironment` 로 임시 디렉터리 주입)에서: 상태바 정확히 `"— | — | ____ | —"`.
- [ ] 브레드크럼 두 번째 세그먼트 클릭(`pane.left.breadcrumb.1`) → 헤더의 leaf 세그먼트가 그 디렉터리로 변경.

### F. 시각 (스크린샷) 검증 — 사용자 수동
**구현 완료 시 PR 또는 보고에 다음 스크린샷 1장 첨부**:
- 두 패널이 모두 표시된 윈도우 캡처.

캡처 위에서 사용자가 체크 (□→■):
- [ ] 배경이 **다크** (시스템이 다크/라이트인지와 무관, 앱 자체가 다크).
- [ ] 좌측 패널 외곽이 **2pt accent** stroke (다른 패널보다 두꺼움).
- [ ] 우측 패널 외곽이 **1pt 회색** stroke.
- [ ] 각 패널 헤더에 `Macintosh HD › … › 현재폴더` 형태의 브레드크럼 보임.
- [ ] 각 패널 헤더 오른쪽 끝에 `〈볼륨라벨〉 ████ 〈X GB〉 남음` 배지 보임.
- [ ] Table 의 컬럼 9개 헤더가 `# / (빈) / Name / Ext / Size / Date / Time / Attrs / Description` 순서.
- [ ] 폴더 행의 Name 텍스트가 **orange**.
- [ ] `.swift` 파일 행 Name 이 **시안색**, `.md` 파일 행 Name 이 **밝은 회백**, `.zip` 행이 **노랑** 등 토큰별 색이 보임.
- [ ] Table 의 마지막 N 행에 **마운트된 볼륨** 들이 인라인으로 표시되며 Description 컬럼에 capsule bar + `남음` 텍스트.
- [ ] cursor 행이 활성 패널에서 **노란빛** 배경.
- [ ] cursor 행이 비활성 패널에서 **회색빛** 배경.
- [ ] 하단 상태바가 `"〈콤마숫자〉 | 〈yyyy-MM-dd HH:mm〉 | 〈A___〉 | 〈파일명〉"` 형식.

### G. 사용자 OK
- [ ] 위 A~F 모두 통과한 뒤 본 문서·파일명을 `done` 으로.

---

## 구현 체크리스트

- [ ] `Features/Pane/PaneRow.swift` 신규
- [ ] `Features/Pane/PaneHeaderView.swift` 신규 — §S2 사양
- [ ] `Features/Pane/BreadcrumbView.swift` 신규 — §S3 사양
- [ ] `Features/Pane/VolumeBadgeView.swift` 신규 — §S4 사양
- [ ] `Features/DualPane/PaneState.swift` — `mountedVolumes` 필드 + `load` 끝 채움 + `paneRows` 계산
- [ ] `Features/DualPane/DualPaneView.swift` — `PaneColumnView` 호출부에 `onSegmentTap` 핸들러 연결
- [ ] `Features/Pane/PaneColumnView.swift` — 헤더 교체, `panelBackground` 적용, stroke §S1
- [ ] `Features/Pane/FileListView.swift` — 9컬럼 §S6, `paneRows` 사용, 토큰 색 §S7, cursor 배경 §S6 끝
- [ ] `Features/Pane/PaneStatusBar.swift` — §S10 4필드 + 포맷 함수 4개
- [ ] `App/MdirXApp.swift` — `.preferredColorScheme(.dark)`
- [ ] accessibility identifiers:
  - `pane.<slot>.breadcrumb.<index>` (0-base, 각 세그먼트)
  - `pane.<slot>.volume.<sanitizedName>`
  - `pane.<slot>.statusbar`
  - 컬럼 헤더 라벨(`TableColumn("Name")` 의 텍스트가 그대로 accessibility 가능해야 함)
- [ ] `Tests/UnitTests/PaneRowsTests.swift`
- [ ] `Tests/UnitTests/BreadcrumbBreakdownTests.swift`
- [ ] `Tests/UnitTests/StatusBarFormatTests.swift`
- [ ] `Tests/UITests/NexusLookCompleteTests.swift`
- [ ] `MdirX.xcodeproj` 신규 소스 반영 (`python3 scripts/gen_xcode_pbx.py`)
- [ ] 두 패널 표시 스크린샷 첨부 (F 항목 체크용)
- [ ] `README.md` 상태 줄 갱신
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] [`0516-1710-pane-list-nexusfile-look.done.md`](0516-1710-pane-list-nexusfile-look.done.md) 본문 끝에 "**UI wire-up 은 후속 [0516-1732-nexusfile-look-remediation](0516-1732-nexusfile-look-remediation.todo.md) 에서 완료**" 한 줄 보충
- [ ] 커밋: `feat(pane): exact nexus look-and-feel (9 cols, breadcrumb, volumes, dark)`

---

## 구현 후 기록 (구현 단계에서 작성)

- [x] Table selection 색 적용 경로: 기존 learnings(`swiftui-table-row-hit-area-and-custom-layout`)에 따라 `Table` 대신 custom `ScrollView`/`LazyVStack` row 를 유지했고, row 루트 `.background` 로 cursor 배경을 적용했다. 이 때문에 `TableColumn(` 소스 grep 조건은 0건이 정상이다.
- [ ] `Tests/UITests/NexusLookCompleteTests.swift` 의 컬럼 헤더 query 방식이 어떤 것인지 기록(견고성을 위해).
- [ ] 깊은 경로 가로 스크롤 동작이 macOS 26 Tahoe / 15 Sequoia 양쪽에서 동일했는지.
- [x] 검증 기록: `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` 통과. `xcodebuild test ... -only-testing:MdirXTests` 통과. 전체 `xcodebuild test` 는 UI test runner 초기화에서 macOS 인증 취소(`LocalAuthentication Code=-2`)로 실패해 앱 코드 검증까지 진입하지 못했다.

---

**상태:** `doing` — NexusFile 룩앤필 UI wire-up 구현 중.
