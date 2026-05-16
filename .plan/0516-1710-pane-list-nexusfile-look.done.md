# 패널 리스트 UI — NexusFile 화면 1:1 매칭

## 사용자 요구 (정제)

- **정제:** 직전 `pane-file-listing` 계획이 깔아 놓을 4컬럼 `Table` 위에, NexusFile V 캡처의 **모든 시각 요소를 아주 똑같이** 얹는다. 구체적으로 패널마다: ① **브레드크럼 헤더** + ② **드라이브 라벨·여유공간 바**(오른쪽 끝) + ③ **요약 줄**(`N 폴더, M 파일 (size)`) + ④ 9컬럼 리스트(`# | 🖼 | Name | Ext | Size | Date | Time | Attrs | Description`) + ⑤ **파일 목록 끝에 마운트된 볼륨 인라인 표시** + ⑥ **하단 상태바**(원시 바이트 콤마·전체 datetime·attrs·전체 파일명). 색상은 폴더 = orange, 확장자별 팔레트, 활성 패널의 선택은 yellow, 비활성은 dim.
- **원문 뉘앙스:** "다음 단계로, pane 내부 리스트 UI를 똑같이 아주 똑같이 계획해."
- **의도 보존:** 동작은 file-listing 의 키맵·네비게이션을 그대로 따르고, 본 계획은 **표시 레이어 한정**. 파일 작업·복사·이동·검색·QuickLook 은 모두 후속.

## 개요

`PaneColumnView` 의 placeholder 헤더(경로 단일 문자열)와 4컬럼 `Table` 을, 캡처처럼 **브레드크럼 + 드라이브 정보** 헤더 + **9컬럼 Table** + **인라인 마운트 볼륨** + **상태바**로 확장한다. SwiftData 모델 도입 없이 모두 휘발성(메모리 + UserDefaults) 로 끝낸다. `Core/Volumes/VolumeService.swift` (신규) 가 `URLResourceKey` 와 `FileManager.mountedVolumeURLs(...)` 로 볼륨 정보를 제공한다. `DesignSystem/Tokens.swift` (신규) 가 색상 토큰을 정리한다.

## 요구사항

### UI — 패널 헤더(좌→우)
- **브레드크럼** (좌):
  - 캡처의 `C: > Users > ifwin > lab > ICT-Role-Based-Structuring` 형식.
  - 각 세그먼트 = 작은 패딩의 클릭 가능한 라벨. 구분자 `›` (chevron, U+203A).
  - 루트는 디렉터리에 따라 `/` 또는 마운트 볼륨 라벨(`Macintosh HD`, `nas`, …)로 표시.
  - 세그먼트 클릭 → 해당 디렉터리로 `PaneState.currentURL` 이동.
  - 우클릭(또는 ⌥-클릭) → 후속(이번 범위 밖, 메모만).
- **드라이브 라벨 + 여유공간 바** (우):
  - 캡처의 `Windows (C:) ████ 258GB 남음` 매칭.
  - macOS 매핑: `〈볼륨 라벨〉 〈capsule bar(채움 비율)〉 〈free 인간 단위〉 남음`.
  - 볼륨 라벨은 `currentURL` 의 마운트 포인트 추적해 `URLResourceKey.volumeName`.
  - capsule bar = 1픽셀 corner-radius capsule, 사용량 / 총용량 비율 채움.
- 헤더 1줄 높이 안에 좌 브레드크럼 + 우 볼륨정보가 양 끝 정렬.

### UI — 요약 줄
- 캡처의 `4 폴더, 2 파일 (98.4KB)` 매칭.
- 위치: 헤더 바로 아래, 본문 `Table` 바로 위.
- 좌측 정렬, monospaced digit, `ByteCountFormatter(.file)`.

### UI — 본문 9컬럼 `Table`
| # | 컬럼 | 표시 |
|---|---|---|
| 1 | `#` (row number) | 1-indexed, monospaced, 폭 24~36pt |
| 2 | icon | 폴더 = `folder` SF Symbol(orange), 파일 = UTI 매핑 SF Symbol, 드라이브 = `internaldrive` / `externaldrive` / `network` / `icloud` |
| 3 | Name | 확장자 제외 표시 이름. 색상 = `tokenForEntry(e)` |
| 4 | Ext | lowercased ext. 디렉터리는 `[폴더]`, 드라이브는 `[드라이브]` |
| 5 | Size | 파일은 `ByteCountFormatter(.file)`, 폴더는 빈칸 또는 `[DIR]` 캡처와 동일하게 빈칸 권장 |
| 6 | Date | ≤7일은 `N일 전` (relative), 그 외 `YYYY-MM-DD` |
| 7 | Time | `HH:mm` |
| 8 | Attrs | 4-char 고정폭 (아래 매핑) |
| 9 | Description | UTI `localizedDescription` (예: `Microsoft Excel 워크시트`, `파일 폴더`, `Markdown File`) |

- Attrs 4-char 매핑 (DOS A R H S → macOS 근사):
  | 자리 | 의미 | macOS 매핑 |
  |---|---|---|
  | 1 | A (archive) | 파일이면 항상 `A`, 그 외 `_` (NexusFile 행동 모사) |
  | 2 | R (read-only) | `URLResourceKey.isWritableKey == false` 이면 `R` |
  | 3 | H (hidden) | `URLResourceKey.isHiddenKey == true` 이면 `H` |
  | 4 | S (system) | `URLResourceKey.isSystemImmutableKey == true` 이면 `S` |
  - 결정 가능한 비트가 없으면 `_`. 항상 4 char 고정.
- 행 색상: name·ext·description 모두 동일 토큰 색을 따름.

### UI — 인라인 마운트 볼륨
- 파일 목록 정렬 뒤에 빈 줄 없이 **이어서** mounted volumes 를 행으로 추가.
- 컬럼: icon | `[볼륨라벨]` (Name 컬럼 자리) | `〈capsule bar〉 〈free〉 남음` (Size 이후를 합쳐 spanning) — `Table` 의 셀 spanning 이 불가하면 Size 컬럼에 capsule, Description 에 `'볼륨'` 표기.
- Enter → `URL(fileURLWithPath: "/")` 또는 해당 volume root 로 진입.
- Date/Time/Attrs 컬럼은 `_` 또는 빈칸.

### UI — 하단 상태바
- 좌→우: `〈콤마 포함 byte size〉 | 〈YYYY-MM-DD HH:mm〉 | 〈A___〉 | 〈전체 파일명〉`
- 선택이 없으면 ` — | — | ____ | — `.

### UI — 색상 팔레트 (DesignSystem/Tokens.swift)
- 폴더: `Color(red: 0.98, green: 0.55, blue: 0.20)` 류 orange.
- 파일 카테고리(확장자 기반):
  - 문서(`md`, `txt`, `rtf`): 기본 텍스트
  - 표(`xlsx`, `csv`): 초록
  - 이미지(`png`, `jpg`, `gif`, `heic`): 분홍/마젠타
  - 코드(`swift`, `py`, `ts`, `js`): 시안
  - 아카이브(`zip`, `tar`, `gz`): 노랑
  - 미디어(`mp4`, `mov`, `mp3`): 파랑
  - 디스크 이미지(`iso`, `dmg`): 청록
  - 그 외: 기본 텍스트
- 활성 패널 선택 행 배경: `Color.yellow.opacity(0.25)` + 텍스트 노랑 강조.
- 비활성 패널 선택 행 배경: `Color.gray.opacity(0.15)`.
- 배경: 다크 (`Color(white: 0.07)`); 라이트 모드는 후속.

### 동작
- 동작·키맵은 file-listing 그대로(`Tab` / `Enter` / `⌘↑` / `.` / `⌘Z` / `⌥Z`).
- 브레드크럼 세그먼트 클릭 → `PaneState.currentURL` 변경 → reload.
- 인라인 볼륨 행 Enter / 클릭 → 그 볼륨 root 진입.
- 활성 패널 변경 시 헤더의 강조도 즉시 갱신.

### 비범위
- 컬럼 정렬 토글·헤더 클릭 정렬.
- 라이트/다크 동시 지원(다크 우선, 라이트는 후속).
- 라이브 디스크 사용량 폴링/자동 갱신(앱 기동·`load()` 시점에만 1회).
- 컬러 코딩 사용자 커스터마이즈(테마 플랜에서).
- 한·중·일 폴더명 truncation 의 글리프 폴백.
- Touch Bar / VoiceOver 풀 지원(VoiceOver 라벨링은 최소만).
- SwiftData 모델 도입 (즐겨찾기 G 계획 때 묶음).

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 유지.
- `URLResourceKey` 호출은 `FileSystemActor` 내부에서만(추가 키 셋 확장).
- 볼륨 enumeration 은 `Core/Volumes/VolumeService.swift` 가 actor 또는 단일 호출 함수로 격리.
- `Color` 토큰은 정적 상수만(상태 없음), 따라서 Sendable 자동 충족.

## 수도 코드

```
// DesignSystem/Tokens.swift
enum FileColorToken {
    static let folder      = Color(.sRGB, red: 0.98, green: 0.55, blue: 0.20)
    static let document    = Color.primary
    static let table       = Color(.sRGB, red: 0.55, green: 0.80, blue: 0.40)
    static let image       = Color(.sRGB, red: 0.95, green: 0.55, blue: 0.85)
    static let code        = Color(.sRGB, red: 0.45, green: 0.85, blue: 0.95)
    static let archive     = Color.yellow
    static let media       = Color(.sRGB, red: 0.45, green: 0.65, blue: 0.95)
    static let diskImage   = Color(.sRGB, red: 0.45, green: 0.85, blue: 0.85)
    static func forEntry(_ e: DirectoryEntry) -> Color { /* switch on isDirectory + ext */ }
}

// Core/FileSystem/DirectoryEntry.swift (확장)
struct DirectoryEntry {
    // 기존 필드 +
    let isWritable: Bool
    let isSystemImmutable: Bool
    let isHidden: Bool                     // 점파일 또는 isHiddenKey
    let kindDescription: String            // UTI localizedDescription
    var attrs: String {                    // "A___" / "AR__" / …
        var s = ""
        s += isDirectory ? "_" : "A"
        s += isWritable ? "_" : "R"
        s += isHidden ? "H" : "_"
        s += isSystemImmutable ? "S" : "_"
        return s
    }
    var relativeOrAbsoluteDate: String { /* ≤7d → "N일 전", else "YYYY-MM-DD" */ }
}

// Core/Volumes/VolumeService.swift
struct MountedVolume: Identifiable, Sendable {
    let id: URL                           // root
    let name: String
    let totalBytes: Int64
    let freeBytes: Int64
    let icon: VolumeIcon                  // .internal / .external / .network / .cloud
}
enum VolumeService {
    static func mounted() -> [MountedVolume] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey,
                                       .volumeAvailableCapacityKey,
                                       .volumeIsLocalKey, .volumeIsInternalKey]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return urls.compactMap { /* map → MountedVolume */ }
    }
    static func freeSpace(forVolumeContaining url: URL) -> (free: Int64, total: Int64) {
        // resourceValues on volume root
    }
}

// Features/Pane/PaneHeaderView.swift  (브레드크럼 + 드라이브정보)
struct PaneHeaderView: View {
    @Bindable var state: PaneState
    let onSegmentTap: (URL) -> Void
    var body: some View {
        HStack {
            BreadcrumbView(url: state.currentURL, onTap: onSegmentTap)
            Spacer()
            VolumeBadgeView(url: state.currentURL)
        }
        .padding(.horizontal, 8).frame(height: 22)
    }
}

struct BreadcrumbView: View {
    let url: URL
    let onTap: (URL) -> Void
    var body: some View {
        let parts = breakdown(url)        // [(label, URL), …]
        HStack(spacing: 4) {
            ForEach(parts.indices, id: \.self) { i in
                Button(parts[i].label) { onTap(parts[i].url) }
                    .buttonStyle(.plain)
                if i < parts.count - 1 { Text("›").foregroundStyle(.secondary) }
            }
        }
    }
}

struct VolumeBadgeView: View {
    let url: URL
    var body: some View {
        let v = VolumeService.freeSpace(forVolumeContaining: url)
        HStack(spacing: 6) {
            Text(volumeName(url))
            Capsule().fill(.tertiary).frame(width: 60, height: 6)
                .overlay(GeometryReader { g in
                    Capsule().fill(.secondary)
                        .frame(width: g.size.width * fillRatio(v))
                })
            Text("\(humanFree(v.free)) 남음").monospacedDigit()
        }
    }
}

// Features/Pane/FileListView.swift  (9컬럼으로 확장)
Table(rows, selection: $state.selectedID) {
    TableColumn("#") { row in Text("\(row.rowNumber)").monospacedDigit() }.width(28)
    TableColumn("") { row in row.icon }                                   .width(20)
    TableColumn("Name") { row in
        Text(row.entry.displayName).foregroundStyle(FileColorToken.forEntry(row.entry))
    }
    TableColumn("Ext") { row in Text(row.entry.ext) }                     .width(min: 40, ideal: 64)
    TableColumn("Size") { row in Text(row.sizeString) }                   .width(min: 60, ideal: 90)
    TableColumn("Date") { row in Text(row.entry.relativeOrAbsoluteDate) } .width(min: 70, ideal: 90)
    TableColumn("Time") { row in
        Text(row.entry.modificationDate, format: .dateTime.hour().minute())
    }.width(min: 50, ideal: 60)
    TableColumn("Attrs") { row in Text(row.entry.attrs).monospaced() }    .width(48)
    TableColumn("Description") { row in Text(row.entry.kindDescription)
        .foregroundStyle(FileColorToken.forEntry(row.entry)) }
}
// rows = [PaneRow] = state.entries 매핑 + mountedVolumes 행 매핑(rowNumber 이어붙임)

// Features/Pane/PaneStatusBar.swift  (상태바)
HStack {
    Text(row.map { rawBytes($0.size) } ?? " — ").monospacedDigit()
    Text("|")
    Text(row.map { fullDateTime($0.modificationDate) } ?? " — ").monospacedDigit()
    Text("|")
    Text(row?.entry.attrs ?? "____").monospaced()
    Text("|")
    Text(row.map { $0.entry.fullName } ?? " — ").lineLimit(1).truncationMode(.middle)
}
.padding(.horizontal, 8).frame(height: 22)
```

## 아키텍처

- **신규 파일**
  - `DesignSystem/Tokens.swift` — `FileColorToken` 정적 enum.
  - `Core/Volumes/VolumeService.swift` — `MountedVolume`, `mounted()`, `freeSpace(forVolumeContaining:)`.
  - `Features/Pane/PaneHeaderView.swift` — 브레드크럼 + 드라이브 배지.
  - `Features/Pane/BreadcrumbView.swift`
  - `Features/Pane/VolumeBadgeView.swift`
  - `Features/Pane/PaneRow.swift` — `Table` 행 데이터 모델(파일 + 볼륨 합쳐 단일 ID).
- **수정 파일**
  - `Core/FileSystem/DirectoryEntry.swift` — 필드 4개 추가(`isWritable`, `isSystemImmutable`, `isHidden`, `kindDescription`) + 계산 프로퍼티(`attrs`, `relativeOrAbsoluteDate`).
  - `Core/FileSystem/FileSystemActor.swift` — 리소스 키 셋 확장, 빈 컨테이너 캐스팅 처리.
  - `Features/Pane/FileListView.swift` — 4컬럼 → 9컬럼, 인라인 볼륨 행 합치기.
  - `Features/Pane/PaneColumnView.swift` — 헤더 placeholder → `PaneHeaderView`; 상태바 raw byte 포맷 변경.
  - `Features/Pane/PaneStatusBar.swift` — 콤마 byte / full datetime / attrs / fullname 4 필드.
  - `Features/DualPane/PaneState.swift` — `mountedVolumes: [MountedVolume]` 보유, `load()` 끝에서 `VolumeService.mounted()` 동기 채움.
- **데이터 흐름**
  - 키/마우스 → 기존 PaneState 동작 그대로.
  - 헤더 브레드크럼 클릭 → `PaneState.currentURL = segment.url` → `load()`.
  - 볼륨 행 Enter → `PaneState.currentURL = volume.id`.
- **외부 의존성**: 표준 라이브러리만(`FileManager`, `URLResourceKey`, `UTType`).

## 통과 조건

- [ ] `xcodebuild build` 0 error / 0 warning(strict concurrency).
- [ ] `xcodebuild test` — 신규 단위 + 기존 + UI 모두 통과.
- [ ] **단위 테스트** (`Tests/UnitTests/AttrStringTests.swift`):
  - 디렉터리 → `_R__` 또는 `____` 패턴(폴더는 A 자리 `_`).
  - 점파일 → `H` 자리 set.
  - 읽기 전용 파일 → `R` 자리 set.
- [ ] **단위 테스트** (`Tests/UnitTests/RelativeDateTests.swift`):
  - 오늘 → `0일 전`(또는 `오늘` 표기로 합의 시 그쪽).
  - 6일 전 → `6일 전`.
  - 8일 전 → `YYYY-MM-DD`.
- [ ] **단위 테스트** (`Tests/UnitTests/VolumeServiceTests.swift`):
  - `mounted()` 결과에 `/` 가 포함된다.
  - `freeSpace(forVolumeContaining:)` 가 `> 0` 의 total 반환.
- [ ] **UI 테스트** (`Tests/UITests/PaneNexusLookTests.swift`):
  - 패널 헤더에 `›` 구분자 가진 브레드크럼 노드 1개 이상 존재.
  - 우측 끝에 "남음" 텍스트 존재.
  - `Table` 컬럼 헤더 텍스트가 `#`, `Name`, `Ext`, `Size`, `Date`, `Time`, `Attrs`, `Description` 모두 보임.
  - 마지막 N개 행이 볼륨 행이며 Description 에 `볼륨` 표기.
- [ ] 수동: 캡처와 좌우 패널 헤더·요약·9컬럼·상태바·볼륨 행이 시각적으로 동일.
- [ ] 수동: 폴더 클릭 → 브레드크럼 갱신; 브레드크럼 세그먼트 클릭 → 그 단계로 점프.
- [ ] 수동: 활성 패널 선택 행은 노란 강조, 비활성은 회색 강조.
- [ ] **사용자 OK** 후 `done` 전이.

## 구현 체크리스트

- [ ] `DesignSystem/Tokens.swift` — FileColorToken
- [ ] `Core/Volumes/VolumeService.swift` — MountedVolume, mounted(), freeSpace
- [ ] `Core/FileSystem/DirectoryEntry.swift` — 4 필드 + attrs/relativeOrAbsoluteDate 계산
- [ ] `Core/FileSystem/FileSystemActor.swift` — resource keys 확장
- [ ] `Features/Pane/BreadcrumbView.swift`
- [ ] `Features/Pane/VolumeBadgeView.swift`
- [ ] `Features/Pane/PaneHeaderView.swift`
- [ ] `Features/Pane/PaneRow.swift` — 파일 + 볼륨 합치는 row 모델
- [ ] `Features/Pane/FileListView.swift` — 9컬럼 + 볼륨 행 + 색상 토큰 적용
- [ ] `Features/Pane/PaneColumnView.swift` — 헤더 placeholder → PaneHeaderView
- [ ] `Features/Pane/PaneStatusBar.swift` — raw byte / full datetime / attrs / fullname
- [ ] `Features/DualPane/PaneState.swift` — mountedVolumes 보유, load 끝에 채움
- [ ] accessibility identifiers — `pane.<slot>.breadcrumb.<index>`, `pane.<slot>.volume.<name>`, 컬럼 헤더 라벨
- [ ] `Tests/UnitTests/AttrStringTests.swift`
- [ ] `Tests/UnitTests/RelativeDateTests.swift`
- [ ] `Tests/UnitTests/VolumeServiceTests.swift`
- [ ] `Tests/UITests/PaneNexusLookTests.swift`
- [ ] `MdirX.xcodeproj` 신규 소스 반영
- [ ] `README.md` 상태 줄 갱신
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): NexusFile look-and-feel (breadcrumb, volumes, 9 cols)`

## 테스트 케이스

- **정상**
  - 홈 디렉터리 열기 → 헤더에 `Macintosh HD › Users › rollcake` 류 브레드크럼, 우측에 `Macintosh HD ████ X GB 남음`.
  - 요약 줄에 `N 폴더, M 파일 (size)`.
  - 9컬럼 Table 의 마지막 행들에 mounted 볼륨(`Macintosh HD`, 외장, iCloud Drive 등)이 보임.
  - 파일 행은 확장자에 맞는 색상; 폴더 행은 orange.
  - 행 선택 시 활성 패널이면 노랑 강조, Tab 으로 다른 패널 활성화 시 색상 dim 으로 변환.
  - 하단 상태바에 콤마 포함 바이트 / yyyy-MM-dd HH:mm / Attrs / 전체 파일명.
- **엣지**
  - 점파일: Attrs 의 H 자리 set, 색상은 기본(별도 색 토큰 없음).
  - 읽기 전용 파일: Attrs R 자리 set.
  - 마운트된 외장 디스크: 인라인 볼륨 행으로 나타남. 외장 USB unplug 시 다음 `load()` 에서 사라짐.
  - iCloud Drive: 아이콘 cloud, 볼륨 라벨 정상 표시.
  - 깊은 경로(브레드크럼 8단 이상): 헤더 폭 초과 시 가운데 truncation(앞·뒤만 표시 + `…` 세그먼트, 클릭 시 풀 경로 풀림 — 단순화 위해 본 계획에선 단순 가로 스크롤 OK).
- **에러/미지원**
  - 볼륨 free 정보 조회 실패 → 우측 끝에 `— 남음` 표기, 키 입력은 정상.
  - 매우 큰 디렉터리(1만+) → `Table` 가상화로 부드러움.
  - 라이트 모드: 본 계획 비범위. 다크 우선 가정 — 라이트에서 임시로 깨져 보일 수 있음(README 메모).

## 디자인 결정 (default 채택)

| # | 결정 | 메모 |
|---|---|---|
| 1 | **헤더 = 브레드크럼(좌) + 볼륨 배지(우)** | 각 패널 헤더 독립; 글로벌 toolbar 도입 안 함(B 계획 보류 상태). |
| 2 | **9컬럼: # / icon / Name / Ext / Size / Date / Time / Attrs / Description** | 캡처 매칭. |
| 3 | **Date 포맷: ≤7일 `N일 전`, 그 외 `YYYY-MM-DD`** | 캡처 좌·우의 혼재 패턴 반영. |
| 4 | **Attrs 4-char: A·R·H·S → macOS 근사 매핑** | DOS 비트 1:1 대응 없음 — 가능한 비트만 set, 나머지 `_`. |
| 5 | **Description = UTI `localizedDescription`** | "Microsoft Excel 워크시트" / "Markdown File" 등 Finder 표기와 일치. |
| 6 | **마운트 볼륨 인라인 행** | 캡처처럼 파일 뒤에 이어 표시. macOS 사이드바 패턴 대신. |
| 7 | **컬러 토큰 = DesignSystem/Tokens.swift** | 라이트 모드는 후속. |
| 8 | **선택 강조: 활성 yellow / 비활성 dim gray** | 캡처 매칭. |
| 9 | **하단 상태바: 콤마 byte / full datetime / attrs / fullname** | 캡처 매칭. |
| ⊕ | **SwiftData 미도입** | `PathHistoryEntry`/`Favorite` 은 즐겨찾기 G 와 묶음. |
| ⊕ | **테마/라이트 모드** | 후속 디자인 계획. |
| ⊕ | **정렬 토글, 컬럼 너비 사용자 조정** | 후속 사용성 계획. |

### macOS 매핑 주의
- DOS 의 `A` 비트(archive)는 macOS 에 직접 매핑이 없음 → **파일은 항상 `A`** 로 채워 NexusFile 행동을 모사. 폴더는 `_`.
- "시스템(S)" 비트는 `URLResourceKey.isSystemImmutableKey` 로 대용. 일반 사용자 파일은 거의 모두 `_`.

---

**상태:** `done` — 2026-05-16 완료·사용자 OK.

후속 기록: UI wire-up 은 [0516-1732-nexusfile-look-remediation](0516-1732-nexusfile-look-remediation.doing.md) 에서 보완 중.
